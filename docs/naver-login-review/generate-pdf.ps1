# UTF-8, no BOM — PDF from service-intro.html via Chrome headless
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$html = Join-Path $here 'service-intro.html'
$pdf = Join-Path $here 'HabitFable-naver-login-service-intro.pdf'
$htmlUri = [Uri]::new((Resolve-Path $html)).AbsoluteUri

$chromeCandidates = @(
  "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
)
$chrome = $chromeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) {
  throw 'Google Chrome not found. Open service-intro.html in browser and Print to PDF.'
}

if (Test-Path $pdf) { Remove-Item -Force $pdf }

& $chrome @(
  '--headless=new',
  '--disable-gpu',
  '--no-pdf-header-footer',
  "--print-to-pdf=$pdf",
  $htmlUri
) | Out-Null

if (-not (Test-Path $pdf)) {
  throw "PDF generation failed: $pdf"
}

Write-Host "Created: $pdf"
