# Play 비공개 테스트용 AAB (PostHog ON, environment=prelaunch)
# android/local.properties 에 ANALYTICS_ENABLED=true, POSTHOG_API_KEY=... 가 있어야 합니다.
# Gradle이 dart-define을 자동 주입하므로 flutter build appbundle 만 실행합니다.

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$localProps = Join-Path 'android' 'local.properties'
if (-not (Test-Path $localProps)) {
    Write-Error @"
[오류] android/local.properties 가 없습니다.
       android/local.properties.example 를 참고해 PostHog 설정을 추가하세요.
"@
}

$analyticsEnabled = $false
$posthogKey = ''
Get-Content $localProps | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '^#') { return }
    if ($line -match '^ANALYTICS_ENABLED=(.+)$') {
        if ($Matches[1].Trim().Equals('true', [StringComparison]::OrdinalIgnoreCase)) {
            $analyticsEnabled = $true
        }
    }
    if ($line -match '^POSTHOG_API_KEY=(.+)$') {
        $posthogKey = $Matches[1].Trim()
    }
}

if (-not $analyticsEnabled -or [string]::IsNullOrWhiteSpace($posthogKey)) {
    Write-Error @"
[오류] 비공개 테스트 AAB(PostHog ON)에는 android/local.properties 에 다음이 필요합니다:
       ANALYTICS_ENABLED=true
       POSTHOG_API_KEY=phc_...
       (선택) POSTHOG_HOST=https://us.i.posthog.com
       (선택) ANALYTICS_ENVIRONMENT=prelaunch
"@
}

Write-Host '[빌드] appbundle (PostHog ON via local.properties)...'
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$out = Join-Path (Get-Location) 'build/app/outputs/bundle/release/app-release.aab'
Write-Host ''
Write-Host '완료:' $out
Write-Host 'PostHog environment: prelaunch (local.properties ANALYTICS_ENVIRONMENT, 기본 prelaunch)'
