# Flutter 실기기 테스트 가이드 (Android / Windows)

USB 케이블이 없어도 Android 11+ 기기에서는 무선 디버깅으로 테스트할 수 있습니다.

---

## 1) USB 연결 테스트

1. 휴대폰에서 `개발자 옵션`을 켜고 **USB 디버깅**을 활성화합니다.
2. USB 케이블로 PC와 연결한 뒤, 휴대폰의 "USB 디버깅 허용" 팝업을 허용합니다.
3. 프로젝트 루트에서 기기 인식을 확인합니다.

```powershell
flutter devices
```

4. 앱을 실행합니다.

```powershell
flutter run
```

기기가 여러 대면 아래처럼 특정 기기를 지정합니다.

```powershell
flutter run -d <deviceId>
```

---

## 2) 무선 연결 테스트 (케이블 없이)

1. 휴대폰과 PC를 같은 Wi-Fi에 연결합니다.
2. 휴대폰 `개발자 옵션`에서 **무선 디버깅**을 켭니다.
3. `무선 디버깅` 화면에서 **페어링 코드로 기기 페어링**을 선택합니다.
4. 휴대폰에 표시된 `ip:pairingPort`와 페어링 코드를 사용해 PC에서 페어링합니다.

```powershell
adb pair <ip:pairingPort>
```

5. 휴대폰 `무선 디버깅` 화면의 `ip:debugPort`로 연결합니다.

```powershell
adb connect <ip:debugPort>
```

6. Flutter에서 기기 목록을 확인하고 앱을 실행합니다.

```powershell
flutter devices
flutter run -d <deviceId>
```

---

## 3) 용어 정리

- `debugPort`: `adb connect <ip:debugPort>`에 사용하는 ADB 연결 포트
- `deviceId`: `flutter devices` 출력에 보이는 기기 식별자 (`flutter run -d`에서 사용)

무선 디버깅 환경에서는 `deviceId`가 `ip:port` 형태로 표시되는 경우가 많습니다.

---

## 4) 자주 막히는 문제

- `unauthorized`가 보이면 휴대폰의 디버깅 허용을 다시 확인하고 재연결합니다.
- 기기가 목록에 안 보이면 케이블/네트워크 상태와 USB 모드를 점검합니다.
- 빌드 오류가 있으면 먼저 아래 명령으로 환경 진단을 확인합니다.

```powershell
flutter doctor
```

---

## 5) iOS 참고

Windows에서는 iOS 실기기 빌드를 직접 실행할 수 없습니다. iPhone 테스트는 Mac + Xcode 환경이 필요합니다.
