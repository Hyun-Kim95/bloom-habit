# Play 업로드용 AAB (PostHog OFF — local.properties 에 ANALYTICS_ENABLED 가 없거나 false)
# API_BASE_URL 등 다른 local.properties dart-define 은 Gradle이 그대로 적용합니다.

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$localProps = Join-Path 'android' 'local.properties'
if (Test-Path $localProps) {
    Get-Content $localProps | ForEach-Object {
        $line = $_.Trim()
        if ($line -match '^#') { return }
        if ($line -match '^ANALYTICS_ENABLED=(.+)$') {
            if ($Matches[1].Trim().Equals('true', [StringComparison]::OrdinalIgnoreCase)) {
                Write-Warning @"
[주의] local.properties 에 ANALYTICS_ENABLED=true 입니다.
       분석 OFF AAB가 필요하면 false 로 바꾸거나 해당 줄을 제거한 뒤 다시 실행하세요.
       PostHog ON AAB는 scripts/build_aab_prelaunch.ps1 를 사용하세요.
"@
            }
        }
    }
}

Write-Host '[빌드] appbundle (PostHog OFF)...'
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$out = Join-Path (Get-Location) 'build/app/outputs/bundle/release/app-release.aab'
Write-Host ''
Write-Host '완료:' $out
