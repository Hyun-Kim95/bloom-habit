import 'dart:io' show Platform;

/// API 서버 주소.
/// - 환경 변수 우선: flutter run --dart-define=API_BASE_URL=http://PC_IP:3000
/// - Android 에뮬레이터: 10.0.2.2 (호스트 PC). 실기기는 같은 Wi-Fi의 PC IP 사용 (예: 192.168.0.5)
String getApiBaseUrl() {
  const envUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  if (envUrl.isNotEmpty) return envUrl;
  return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
}
