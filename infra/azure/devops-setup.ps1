<#
.SYNOPSIS
  Cria o projeto Azure DevOps da Sprint 4 e concede acesso ao professor.

.DESCRIPTION
  Pré-requisitos: Azure CLI + extensão azure-devops, e `az login` com uma conta
  que administre a organização (ou `az devops login` com PAT digitado no prompt;
  nunca cole o token em arquivos ou no chat).

  ACESSO DO PROFESSOR - dois níveis distintos:
    * Nível de acesso (license) = Basic -> o que a pessoa pode usar na organização (Repos, Pipelines, Boards...).
    * Permissões no projeto = grupo "Readers" -> o que ela pode ver/fazer dentro DESTE projeto.
  O script concede os dois. O convite por e-mail só é enviado com -EnviarConvite.

.EXAMPLE
  ./infra/azure/devops-setup.ps1 -Organization minha-org -NomeProfessor 'Fulano' `
     -Integrantes '566551 - Pedro Vaz Ferreira - <TURMA>','565139 - ...' `
     -EmailProfessor professor@exemplo.com -EnviarConvite
#>
param(
  [Parameter(Mandatory)][string]$Organization,   # https://dev.azure.com/<Organization>
  [Parameter(Mandatory)][string]$NomeProfessor,
  [Parameter(Mandatory)][string[]]$Integrantes,  # "<RM> - <nome completo> - <turma>"
  [string]$EmailProfessor = '',
  [switch]$EnviarConvite
)

$ErrorActionPreference = 'Stop'
function Invoke-Az { & az @args; if ($LASTEXITCODE -ne 0) { throw "az $($args[0..2] -join ' ') falhou (exit $LASTEXITCODE)" } }

$projectName = "Sprint 4 $([char]0x2013) Azure DevOps"      # "Sprint 4 – Azure DevOps"
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
Write-Host 'Faltam (via portal): conexão com GitHub, Service Connection ARM e criação do pipeline - ver docs/sprint4/azure-devops-setup.md'
