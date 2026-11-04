param(
  [Parameter(Mandatory)][string]$Organization,
  [Parameter(Mandatory)][string]$NomeProfessor,
  [Parameter(Mandatory)][string[]]$Integrantes,
  [string]$EmailProfessor = '',
  [switch]$EnviarConvite
)

$ErrorActionPreference = 'Stop'
function Invoke-Az { & az @args; if ($LASTEXITCODE -ne 0) { throw "az $($args[0..2] -join ' ') falhou (exit $LASTEXITCODE)" } }

$projectName = "Sprint 4 $([char]0x2013) Azure DevOps"
$description = "Projeto para entrega da Sprint 4 do professor $NomeProfessor`n" + ($Integrantes -join "`n")
$orgUrl = "https://dev.azure.com/$Organization"

Invoke-Az extension add --name azure-devops --only-show-errors -o none
Invoke-Az devops configure --defaults organization=$orgUrl

Write-Host "Criando projeto privado, Git, processo Agile..."
Invoke-Az devops project create --name $projectName --description $description `
  --process Agile --source-control git --visibility private -o none

if ($EmailProfessor) {
  Write-Host "Concedendo nível de acesso Basic (license 'express') ao professor..."
  $convite = if ($EnviarConvite) { 'true' } else { 'false' }
  Invoke-Az devops user add --email-id $EmailProfessor --license-type express `
    --send-email-invite $convite --org $orgUrl -o none

  Write-Host "Adicionando ao grupo Readers do projeto (permissão de visualização)..."
  $grupo = (& az devops security group list --project $projectName --org $orgUrl `
    --query "graphGroups[?displayName=='Readers'].descriptor | [0]" -o tsv)
  $usuario = (& az devops user show --user $EmailProfessor --org $orgUrl --query 'user.descriptor' -o tsv)
  if (-not $grupo -or -not $usuario) { throw 'Não foi possível resolver os descritores do grupo/usuário.' }
  Invoke-Az devops security group membership add --group-id $grupo --member-id $usuario --org $orgUrl -o none
} else {
  Write-Host 'EmailProfessor não informado: convite e permissões NÃO foram concedidos.'
}

Write-Host "Projeto criado: $orgUrl/$([uri]::EscapeDataString($projectName))"
Write-Host 'Faltam (via portal): conexão com GitHub, Service Connection ARM e criação do pipeline - ver o README'
