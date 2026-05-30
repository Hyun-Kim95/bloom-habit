# 본인 폰용 release APK (PostHog ON). AAB와 동일하게 local.properties → Gradle dart-define.

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$localProps = Join-Path 'android' 'local.properties'
if (-not (Test-Path $localProps)) {
    Write-Error '[오류] android/local.properties 가 없습니다.'
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
[오류] android/local.properties 에 ANALYTICS_ENABLED=true, POSTHOG_API_KEY=phc_... 가 필요합니다.
"@
}

Write-Host '[빌드] release APK (PostHog ON via local.properties)...'
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build apk --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$out = Join-Path (Get-Location) 'build/app/outputs/flutter-apk/app-release.apk'
Write-Host ''
Write-Host '완료:' $out
