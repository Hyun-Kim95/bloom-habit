# 카카오 Android 키 해시 등록

로그인 시 다음 오류가 나면 **카카오 개발자 콘솔에 앱 서명 키 해시가 등록되지 않은 것**입니다.

- `Android keyHash validation failed`
- `invalid_request` + `keyHash`

## 등록 위치

1. [카카오 개발자 콘솔](https://developers.kakao.com/console/app) → 내 앱 → **앱 설정** → **플랫폼**
2. **Android** 플랫폼에 패키지명이 `com.example.bloom_habit`(또는 실제 `applicationId`)로 등록돼 있는지 확인
3. 같은 화면의 **키 해시**에 아래에서 구한 값을 **추가** 후 저장

## 디버그 빌드 키 해시 구하기 (Windows / 기본 debug.keystore)

PowerShell에서 실행합니다. (`%USERPROFILE%\.android\debug.keystore` 사용)

```powershell
$der = "$env:TEMP\kakao_debug_cert.der"
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android -file $der
$bytes = [System.IO.File]::ReadAllBytes($der)
$sha1 = [System.Security.Cryptography.SHA1]::Create().ComputeHash($bytes)
[Convert]::ToBase64String($sha1)
```

출력되는 한 줄(예: `xxxxxxxxxxxxxxxxxxxxx=`)을 콘솔 **키 해시**에 붙여넣습니다.

> PC마다 `debug.keystore`가 다르므로, **팀원·다른 PC**에서는 각자 위 명령으로 다시 구한 뒤 등록해야 합니다.

## 릴리스(배포) APK / AAB

스토어 배포용 서명 키로 빌드할 때는 **그 keystore**로 같은 방식으로 인증서를 export한 뒤 위와 같이 SHA1 → Base64 한 줄을 구해, 콘솔에 **추가**로 등록합니다.

```text
keytool -exportcert -alias <별칭> -keystore <릴리스.keystore> -file release.der
```

이후 PowerShell에서 `release.der`에 대해 동일하게 `SHA1` + `ToBase64String`을 적용하면 됩니다.

## 참고

- [카카오 로그인 Android 가이드 — 키 해시](https://developers.kakao.com/docs/latest/ko/getting-started/sdk-android#add-key-hash)
