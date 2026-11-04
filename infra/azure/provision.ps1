param(
  [string]$ResourceGroup = 'rg-petfamily-sprint4',
  [string]$Location      = 'brazilsouth',
  [string]$WebAppName    = 'petfamily-sprint4-api',
  [string]$PlanName      = 'plan-petfamily-sprint4',
  [string]$PlanSku       = 'B1',
  [string]$PgServerName  = 'petfamily-sprint4-pg',
  [string]$DbName        = 'petfamily',
  [string]$DbAdminUser   = 'petfamilyadmin',
  [string]$ClientIp      = ''
)

$ErrorActionPreference = 'Stop'

function Invoke-Az {
  $ErrorActionPreference = 'Continue'
  & az @args
  if ($LASTEXITCODE -ne 0) { throw "az $($args[0..2] -join ' ') falhou (exit $LASTEXITCODE)" }
}
function Test-Az {
  $ErrorActionPreference = 'Continue'
  & az @args -o none 2>$null
  return ($LASTEXITCODE -eq 0)
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) { throw 'Azure CLI (az) não encontrado.' }
$dbPassword = $env:PETFAMILY_DB_PASSWORD
if ([string]::IsNullOrEmpty($dbPassword) -or $dbPassword.Length -lt 12) {
  throw 'Defina $env:PETFAMILY_DB_PASSWORD com no mínimo 12 caracteres.'
}
$jwtSecret = $env:PETFAMILY_JWT_SECRET
if ([string]::IsNullOrEmpty($jwtSecret)) {
  $bytes = New-Object byte[] 48
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $jwtSecret = [Convert]::ToBase64String($bytes)
}

Write-Host "Assinatura ativa:"; Invoke-Az account show --query '{nome:name, id:id}' -o table

$runtime = (& az webapp list-runtimes --os-type linux -o tsv) |
  ForEach-Object { ($_ -split "`t")[0] } |
  Where-Object { $_ -match '^JAVA[:|]17-java17$' } | Select-Object -First 1
if (-not $runtime) { throw "Runtime JAVA 17 não encontrado em 'az webapp list-runtimes --os-type linux'." }
$runtime = $runtime -replace '\|', ':'

Write-Host "0/6 Providers (necessário em assinaturas novas/estudante)"
foreach ($ns in 'Microsoft.Web', 'Microsoft.DBforPostgreSQL') { Invoke-Az provider register --namespace $ns --wait -o none }

Write-Host "1/6 Resource Group"
Invoke-Az group create -n $ResourceGroup -l $Location -o none

Write-Host "2/6 PostgreSQL Flexible Server (pode levar alguns minutos)"
$publicAccess = if ($ClientIp) { $ClientIp } else { 'None' }
if (-not (Test-Az postgres flexible-server show -g $ResourceGroup -n $PgServerName)) {
  Invoke-Az postgres flexible-server create `
    --resource-group $ResourceGroup --name $PgServerName --location $Location `
    --admin-user $DbAdminUser --admin-password $dbPassword `
    --sku-name Standard_B1ms --tier Burstable --storage-size 32 --version 16 `
    --public-access $publicAccess --yes -o none
} else { Write-Host "  (servidor $PgServerName já existe; reaproveitando)" }
if (-not (Test-Az postgres flexible-server db show -g $ResourceGroup --server-name $PgServerName --name $DbName)) {
  Invoke-Az postgres flexible-server db create -g $ResourceGroup --server-name $PgServerName --name $DbName -o none
}

Write-Host "3/6 App Service Plan + Web App (Java SE 17)"
if (-not (Test-Az appservice plan show -g $ResourceGroup -n $PlanName)) {
  Invoke-Az appservice plan create -g $ResourceGroup -n $PlanName --is-linux --sku $PlanSku -o none
}
if (-not (Test-Az webapp show -g $ResourceGroup -n $WebAppName)) {
  Invoke-Az webapp create -g $ResourceGroup -p $PlanName -n $WebAppName --runtime $runtime -o none
}
Invoke-Az webapp update -g $ResourceGroup -n $WebAppName --https-only true -o none
Invoke-Az webapp config set -g $ResourceGroup -n $WebAppName `
  --startup-file 'java -jar /home/site/wwwroot/app.jar --server.port=80' -o none
if ($PlanSku -notin 'F1', 'FREE', 'D1') {
  Invoke-Az webapp config set -g $ResourceGroup -n $WebAppName --always-on true -o none
}

Write-Host "4/6 App Settings (segredos não são exibidos)"
$pgHost = (& az postgres flexible-server show -g $ResourceGroup -n $PgServerName --query fullyQualifiedDomainName -o tsv)
$dbUrl  = "jdbc:postgresql://${pgHost}:5432/${DbName}?sslmode=require"
Invoke-Az webapp config appsettings set -g $ResourceGroup -n $WebAppName -o none --settings `
  "SPRING_PROFILES_ACTIVE=prod" `
  "DB_URL=$dbUrl" `
  "DB_USER=$DbAdminUser" `
  "DB_PASSWORD=$dbPassword" `
  "JWT_SECRET=$jwtSecret" `
  "CORS_ALLOWED_ORIGINS=*" `
  "SWAGGER_ENABLED=true" `
  "WEBSITES_CONTAINER_START_TIME_LIMIT=600"

Write-Host "5/6 Firewall do PostgreSQL: apenas IPs de saída do Web App"
$ips = (& az webapp show -g $ResourceGroup -n $WebAppName --query possibleOutboundIpAddresses -o tsv) -split ','
$i = 0
foreach ($ip in ($ips | Select-Object -Unique)) {
  $i++
  Invoke-Az postgres flexible-server firewall-rule create -g $ResourceGroup --server-name $PgServerName `
    --name "webapp-out-$i" --start-ip-address $ip --end-ip-address $ip -o none
}
if ($ClientIp) {
  Invoke-Az postgres flexible-server firewall-rule create -g $ResourceGroup --server-name $PgServerName `
    --name 'cliente-demo' --start-ip-address $ClientIp --end-ip-address $ClientIp -o none
}

Write-Host "6/6 Pronto."
Write-Host "Web App   : https://$((& az webapp show -g $ResourceGroup -n $WebAppName --query defaultHostName -o tsv))"
Write-Host "PostgreSQL: $pgHost (db: $DbName, usuário: $DbAdminUser)"
Write-Host "Próximo passo: criar a Service Connection ARM e rodar o pipeline (ver o README)."
Write-Host "Obs.: o schema é criado pelo Flyway no primeiro start da aplicação (V1-V7)."
