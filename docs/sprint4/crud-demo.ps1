param(
  [Parameter(Mandatory)][string]$BaseUrl,
  [switch]$Pausar,
  [switch]$ManterTutor
)

$ErrorActionPreference = 'Stop'
$BaseUrl = $BaseUrl.TrimEnd('/')
$sufixo  = Get-Date -Format 'yyyyMMddHHmmss'
$email   = "demo.sprint4.$sufixo@exemplo.com"
$senha   = [Convert]::ToBase64String((1..18 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])

function Passo($titulo, $dica) {
  Write-Host "`n=== $titulo ===" -ForegroundColor Cyan
  if ($dica) { Write-Host $dica -ForegroundColor Yellow }
}
function Espera { if ($Pausar) { [void](Read-Host 'ENTER para continuar') } }
function Mostra($obj) { $obj | ConvertTo-Json -Depth 5 }

Passo '0. Registrar tutor de demonstração (POST /auth/registrar)' $null
$reg = Invoke-RestMethod -Method Post -Uri "$BaseUrl/auth/registrar" -ContentType 'application/json' `
  -Body (@{ nome = "DEMO Sprint4 Tutor $sufixo"; email = $email; senha = $senha } | ConvertTo-Json)
$h = @{ Authorization = "Bearer $($reg.token)" }
Write-Host "tutorId=$($reg.tutorId)  email=$email"

Passo '1. CREATE  POST /pets' 'Rode no psql o SELECT dos pets DEMO (deve aparecer 1 linha: DEMO-Sprint4-Rex)'
$pet = Invoke-RestMethod -Method Post -Uri "$BaseUrl/pets" -Headers $h -ContentType 'application/json' `
  -Body (@{ nome = 'DEMO-Sprint4-Rex'; especie = 'Cachorro'; raca = 'SRD'; idade = 3; peso = 12.5 } | ConvertTo-Json)
Mostra $pet
$id = $pet.id
Espera

Passo "2. READ  GET /pets/$id  e  GET /pets" 'Rode no psql o mesmo SELECT e compare com os dados acima'
Write-Host "`n--- Consulta 1: um pet pelo id (GET /pets/$id) ---" -ForegroundColor White
Mostra (Invoke-RestMethod -Uri "$BaseUrl/pets/$id" -Headers $h)
Write-Host "`n--- Consulta 2: lista de pets do tutor (GET /pets) ---" -ForegroundColor White
$lista = (Invoke-RestMethod -Uri "$BaseUrl/pets?size=5" -Headers $h).content
$lista | Format-Table id, nome, especie, raca, idade, peso -AutoSize | Out-String | Write-Host
Write-Host "Total de pets na lista: $(@($lista).Count)"
Espera

Passo "3. UPDATE  PUT /pets/$id" 'Rode no psql o mesmo SELECT: nome ...-Atualizado, raca Labrador, idade 4, peso 14'
$upd = Invoke-RestMethod -Method Put -Uri "$BaseUrl/pets/$id" -Headers $h -ContentType 'application/json' `
  -Body (@{ nome = 'DEMO-Sprint4-Rex-Atualizado'; especie = 'Cachorro'; raca = 'Labrador'; idade = 4; peso = 14.0 } | ConvertTo-Json)
Mostra $upd
Espera

Passo "4. DELETE  DELETE /pets/$id" 'Rode no psql o COUNT dos pets DEMO: deve retornar 0'
Invoke-WebRequest -Method Delete -Uri "$BaseUrl/pets/$id" -Headers $h -UseBasicParsing | Select-Object StatusCode | Format-List
try {
  Invoke-RestMethod -Uri "$BaseUrl/pets/$id" -Headers $h | Out-Null
  Write-Host 'ATENÇÃO: o pet ainda existe.' -ForegroundColor Red
} catch {
  Write-Host "GET /pets/$id após exclusão -> HTTP $([int]$_.Exception.Response.StatusCode) (esperado 404)"
}
Espera

if (-not $ManterTutor) {
  Passo "5. Limpeza  DELETE /tutores/$($reg.tutorId)" 'Remove o tutor e o usuário de demonstração (rode os 2 COUNT: tutores_demo e usuarios_demo = 0)'
  Invoke-WebRequest -Method Delete -Uri "$BaseUrl/tutores/$($reg.tutorId)" -Headers $h -UseBasicParsing |
    Select-Object StatusCode | Format-List
}
Write-Host "`nFim. Registros criados tinham o prefixo DEMO e o e-mail $email" -ForegroundColor Green
