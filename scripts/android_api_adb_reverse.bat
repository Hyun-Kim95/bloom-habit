@echo off
chcp 65001 >nul
echo.
echo === 1단계: PC와 에뮬레이터 사이에 "3000 포트 터널" 만들기 ===
echo    (에뮬레이터가 이미 켜져 있어야 합니다.)
echo.

set "ADB=%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe"
if not exist "%ADB%" (
  echo [오류] adb를 찾을 수 없습니다: %ADB%
  echo Android Studio에서 SDK 설치 경로를 확인하세요.
  pause
  exit /b 1
)

"%ADB%" reverse tcp:3000 tcp:3000
if errorlevel 1 (
  echo [오류] reverse 실패. USB 디버깅 기기면 케이블/USB 디버깅을 확인하세요.
  pause
  exit /b 1
)

echo.
echo --- 적용된 reverse 목록 (여기에 3000 이 보이면 OK) ---
"%ADB%" reverse --list
echo.
echo === 2단계: 앱 실행 ===
echo    터미널에서 프로젝트 폴더(bloom_habit)로 이동한 뒤 아래를 **한 줄로** 실행하세요:
echo.
echo    flutter run --dart-define=API_USE_LOCALHOST=true
echo.
echo    (이미 flutter run 중이면 q 로 끄고, 위 명령으로 다시 실행해야 합니다.)
echo.
echo === 참고 ===
echo    - API 서버(server)는 PC에서 npm run start:dev 등으로 3000 포트에 떠 있어야 합니다.
echo    - 에뮬레이터를 완전히 껐다 켰으면, 이 배치 파일을 다시 실행하세요.
echo.
pause
