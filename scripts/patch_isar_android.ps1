# isar_flutter_libs Android namespace 패치 (AGP 8+ 대응)
# 사용: flutter pub get 실행 후, 이 스크립트를 한 번 실행하세요.
#   .\scripts\patch_isar_android.ps1

$pubCache = $env:PUB_CACHE
if (-not $pubCache) {
    $pubCache = Join-Path $env:LOCALAPPDATA "Pub\Cache"
}
$buildGradle = Join-Path $pubCache "hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle"

if (-not (Test-Path $buildGradle)) {
    Write-Host "Not found: $buildGradle" -ForegroundColor Yellow
    Write-Host "Run 'flutter pub get' first, then run this script again."
    exit 1
}

$content = Get-Content $buildGradle -Raw
if ($content -match "namespace\s+'dev\.isar\.isar_flutter_libs'") {
    Write-Host "Already patched: isar_flutter_libs" -ForegroundColor Green
    exit 0
}

if ($content -notmatch "namespace\s+") {
    $content = $content -replace "(android \{\s*\r?\n)", "`$1    namespace 'dev.isar.isar_flutter_libs'`r`n"
    Set-Content $buildGradle -Value $content -NoNewline
    Write-Host "Patched: $buildGradle" -ForegroundColor Green
}
