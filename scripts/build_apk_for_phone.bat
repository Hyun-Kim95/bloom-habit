@echo off
chcp 65001 >nul
cd /d "%~dp0.."

REM =============================================================================
REM  실제 폰에 옮겨 설치할 APK 만들기
REM
REM  필수: PC와 폰이 같은 Wi-Fi일 때, 빌드 전에 아래 중 하나로 API 주소를 넣으세요.
REM    (1) android\local.properties 에 한 줄 추가
REM          API_BASE_URL=http://192.168.0.12:3000
REM        ^(숫자는 PC에서 ipconfig 로 본 무선 LAN IPv4^)
REM    (2) 또는 이 콘솔에서:
REM          set API_BASE_URL=http://192.168.0.12:3000
REM          scripts\build_apk_for_phone.bat
REM
REM  에뮬레이터용 APK만 만들 때(주소 불필요): set ALLOW_APK_WITHOUT_API=1
REM
REM  release APK: 첫 인자 release
REM  설치: APK를 카톡·드라이브 등으로 보낸 뒤, 폰에서 출처 알 수 없는 앱 설치 허용
REM =============================================================================

set "MODE=%~1"
set "DEFINE_ARGS="

if not "%API_BASE_URL%"=="" (
  set "DEFINE_ARGS=--dart-define=API_BASE_URL=%API_BASE_URL%"
  echo [정보] 환경변수 API_BASE_URL=%API_BASE_URL%
)

REM local.properties 안의 API_BASE_URL (주석 아닌 줄)
set "FROM_LOCAL=0"
if exist "android\local.properties" (
  for /f "usebackq eol=# tokens=1* delims==" %%A in ("android\local.properties") do (
    if /I "%%A"=="API_BASE_URL" (
      if not "%%B"=="" set "FROM_LOCAL=1"
    )
  )
)

if "%ALLOW_APK_WITHOUT_API%"=="1" goto :do_build
if not "%DEFINE_ARGS%"=="" goto :do_build
if "%FROM_LOCAL%"=="1" goto :do_build

echo.
echo [오류] 실제 폰용 APK에는 API 서버 주소가 빌드에 포함되어야 합니다.
echo       android\local.properties 에 다음 형식으로 추가한 뒤 다시 실행하세요:
echo.
echo       API_BASE_URL=http://여기에_PC의_WiFi_IP:3000
echo.
echo       PC에서 PowerShell: ipconfig  ^> 무선 LAN 어댑터 IPv4 주소 확인
echo       같은 줄을 그대로 넣고, 서버가 PC에서 3000 포트로 떠 있는지 확인하세요.
echo.
echo       ^(에뮬레이터 전용 APK가 필요하면 set ALLOW_APK_WITHOUT_API=1 후 실행^)
echo.
exit /b 1

:do_build
if /i "%MODE%"=="release" (
  echo [빌드] release APK...
  call flutter build apk --release %DEFINE_ARGS%
  if errorlevel 1 exit /b 1
  set "OUT=build\app\outputs\flutter-apk\app-release.apk"
) else (
  echo [빌드] debug APK...
  call flutter build apk --debug %DEFINE_ARGS%
  if errorlevel 1 exit /b 1
  set "OUT=build\app\outputs\flutter-apk\app-debug.apk"
)

echo.
echo 완료. 파일 위치:
echo   %CD%\%OUT%
explorer /select,"%CD%\%OUT%"
pause
