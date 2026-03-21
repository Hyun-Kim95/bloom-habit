import 'dart:io' show Platform;

/// API base URL.
/// - [API_BASE_URL] wins if set, e.g. `http://192.168.0.5:3000` on a real device.
/// - Android + [API_USE_LOCALHOST]=true: `http://127.0.0.1:3000` (requires
///   `adb reverse tcp:3000 tcp:3000`). Use on Windows when firewall blocks 10.0.2.2.
/// - Else Android emulator default: `http://10.0.2.2:3000`.
String getApiBaseUrl() {
  const envUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  if (envUrl.isNotEmpty) return envUrl;

  const useLocalhostTunnel = String.fromEnvironment(
    'API_USE_LOCALHOST',
    defaultValue: '',
  );
  final tunnelOn = useLocalhostTunnel == '1' ||
      useLocalhostTunnel.toLowerCase() == 'true';
  if (Platform.isAndroid && tunnelOn) {
    return 'http://127.0.0.1:3000';
  }

  return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
}
