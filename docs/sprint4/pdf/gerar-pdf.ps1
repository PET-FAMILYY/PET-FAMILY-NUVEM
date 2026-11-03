<#
.SYNOPSIS
  Gera o PDF final da Sprint 4: SOMENTE integrantes (nome completo, RM, turma) e os três links.

.DESCRIPTION
  1. Copie dados-entrega.example.json para dados-entrega.json (ignorado pelo git) e preencha com dados reais.
  2. Rode ./gerar-pdf.ps1  -> gera entrega-sprint4.pdf (usa o Microsoft Edge em modo headless).
  O script RECUSA gerar o PDF final se houver campo vazio ou placeholder (<...>).
  Com -Modelo gera "modelo-NAO-ENTREGAR.pdf" apenas para conferir o layout.
#>
param(
  [string]$Dados = (Join-Path $PSScriptRoot 'dados-entrega.json'),
  [switch]$Modelo
)

$ErrorActionPreference = 'Stop'
if ($Modelo) { $Dados = Join-Path $PSScriptRoot 'dados-entrega.example.json' }
if (-not (Test-Path $Dados)) { throw "Arquivo de dados não encontrado: $Dados (copie dados-entrega.example.json)." }
$d = Get-Content $Dados -Raw -Encoding UTF8 | ConvertFrom-Json

$pendencias = @()
function Confere($rotulo, $valor) {
  if ([string]::IsNullOrWhiteSpace($valor) -or $valor -match '[<>]') { $script:pendencias += $rotulo }
}
if (-not $d.integrantes -or $d.integrantes.Count -eq 0) { $pendencias += 'integrantes' }
$i = 0
foreach ($m in $d.integrantes) { $i++; Confere "integrante $i nome" $m.nome; Confere "integrante $i RM" $m.rm; Confere "integrante $i turma" $m.turma }
Confere 'linkGitHub' $d.linkGitHub
Confere 'linkVideoYouTube' $d.linkVideoYouTube
Confere 'linkProjetoAzureDevOps' $d.linkProjetoAzureDevOps

if ($pendencias.Count -gt 0 -and -not $Modelo) {
  throw "PDF final NÃO gerado. Preencha: $($pendencias -join ', ')"
}

Add-Type -AssemblyName System.Web
$enc = { param($t) [System.Web.HttpUtility]::HtmlEncode([string]$t) }
$linhas = ($d.integrantes | ForEach-Object { "<tr><td>$(& $enc $_.nome)</td><td>$(& $enc $_.rm)</td><td>$(& $enc $_.turma)</td></tr>" }) -join "`n"
$html = @"
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><title>Sprint 4</title>
<style>
 @page { size: A4; margin: 25mm }
 body { font-family: Arial, sans-serif; font-size: 13pt; color: #000 }
 table { border-collapse: collapse; width: 100% }
 th, td { border: 1px solid #000; padding: 6px 10px; text-align: left }
 p { margin: 14px 0; word-break: break-all }
</style></head><body>
<table><tr><th>Nome completo</th><th>RM</th><th>Turma</th></tr>
$linhas
</table>
<p><b>GitHub:</b> <a href="$(& $enc $d.linkGitHub)">$(& $enc $d.linkGitHub)</a></p>
<p><b>Vídeo (YouTube):</b> <a href="$(& $enc $d.linkVideoYouTube)">$(& $enc $d.linkVideoYouTube)</a></p>
<p><b>Azure DevOps:</b> <a href="$(& $enc $d.linkProjetoAzureDevOps)">$(& $enc $d.linkProjetoAzureDevOps)</a></p>
</body></html>
"@

$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
  Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { throw 'Microsoft Edge não encontrado (necessário para gerar o PDF).' }

$nome = if ($Modelo) { 'modelo-NAO-ENTREGAR.pdf' } else { 'entrega-sprint4.pdf' }
$saida = Join-Path $PSScriptRoot $nome
$tmp = Join-Path ([IO.Path]::GetTempPath()) "sprint4-$([guid]::NewGuid()).html"
[IO.File]::WriteAllText($tmp, $html, [Text.UTF8Encoding]::new($false))
try {
  # Start-Process: o Edge escreve ruído em stderr que o PS 5.1 trataria como erro com 'Stop'
  Start-Process -FilePath $edge -Wait -WindowStyle Hidden -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-pdf-header-footer',
    "--print-to-pdf=`"$saida`"", "`"file:///$($tmp -replace '\\','/')`"")
  Start-Sleep 1
} finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
if (-not (Test-Path $saida)) { throw 'Falha ao gerar o PDF.' }
Write-Host "Gerado: $saida"
if ($Modelo) { Write-Host 'ATENÇÃO: é um MODELO com placeholders; não entregue este arquivo.' -ForegroundColor Yellow }
