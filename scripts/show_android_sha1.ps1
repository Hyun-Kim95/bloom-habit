# Android 디버그 keystore SHA-1 출력 (Google 로그인 등록용)
# 사용: .\scripts\show_android_sha1.ps1

$keystore = Join-Path $env:USERPROFILE ".android\debug.keystore"
if (-not (Test-Path $keystore)) {
    Write-Host "Debug keystore not found: $keystore" -ForegroundColor Red
    exit 1
}

Write-Host "Package name: com.example.bloom_habit" -ForegroundColor Cyan
Write-Host "SHA-1 (copy to Google Cloud Console):" -ForegroundColor Cyan
$out = keytool -list -v -keystore $keystore -alias androiddebugkey -storepass android -keypass android 2>$null
$sha1 = ($out | Select-String "^\s+SHA1:\s+(.+)").Matches.Groups[1].Value
if ($sha1) {
    Write-Host $sha1 -ForegroundColor Green
} else {
    keytool -list -v -keystore $keystore -alias androiddebugkey -storepass android -keypass android
}
