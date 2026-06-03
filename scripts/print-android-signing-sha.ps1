# Play / 로컬 릴리즈·디버그 keystore SHA-1·SHA-256 (Firebase·Google 등록용, 네이버 아님)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Push-Location (Join-Path $root "android")
try {
    .\gradlew signingReport
    Write-Host ""
    Write-Host "Firebase / Google 로그인 등록용 SHA-1 입니다. 네이버 개발자 센터에는 SHA-1 항목이 없습니다."
    Write-Host "네이버: 패키지명 com.khyun.bloom_habit + Client ID/Secret -> docs/guides/naver-login-android.md"
} finally {
    Pop-Location
}
