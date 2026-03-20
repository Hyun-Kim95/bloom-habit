import 'dart:io' show Platform;

/// API base URL.
/// - Env var first: flutter run --dart-define=API_BASE_URL=http://PC_IP:3000
/// - Android emulator: 10.0.2.2 (host PC). Real devices should use PC LAN IP.
String getApiBaseUrl() {
  const envUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  if (envUrl.isNotEmpty) return envUrl;
  return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
}
