import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_version_policy.dart';

enum AppUpdateActionResult {
  startedInApp,
  openedStore,
  storeUnavailable,
  failed,
}

class AppUpdateService {
  Future<AppUpdateActionResult> performUpdate({
    required UpdateKind kind,
    required String storeUrl,
    AppUpdateInfo? playInfo,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      final inAppResult = await _tryAndroidInAppUpdate(
        kind: kind,
        playInfo: playInfo,
      );
      if (inAppResult != null) {
        return inAppResult;
      }
    }
    return _openStore(storeUrl);
  }

  Future<AppUpdateActionResult?> _tryAndroidInAppUpdate({
    required UpdateKind kind,
    AppUpdateInfo? playInfo,
  }) async {
    try {
      final info = playInfo ?? await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return null;
      }

      if (kind == UpdateKind.forced) {
        if (!info.immediateUpdateAllowed) {
          return null;
        }
        final result = await InAppUpdate.performImmediateUpdate();
        if (result == AppUpdateResult.success) {
          return AppUpdateActionResult.startedInApp;
        }
        return null;
      }

      if (!info.flexibleUpdateAllowed) {
        return null;
      }
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        return AppUpdateActionResult.startedInApp;
      }
      return null;
    } catch (e, st) {
      debugPrint('[AppUpdateService] in-app update failed: $e\n$st');
      return null;
    }
  }

  Future<bool> completeFlexibleUpdateIfReady() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return true;
    } catch (e, st) {
      debugPrint('[AppUpdateService] complete flexible failed: $e\n$st');
      return false;
    }
  }

  Future<AppUpdateActionResult> _openStore(String storeUrl) async {
    final trimmed = storeUrl.trim();
    if (trimmed.isEmpty) {
      return AppUpdateActionResult.storeUnavailable;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return AppUpdateActionResult.storeUnavailable;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return opened
          ? AppUpdateActionResult.openedStore
          : AppUpdateActionResult.failed;
    } catch (e, st) {
      debugPrint('[AppUpdateService] open store failed: $e\n$st');
      return AppUpdateActionResult.failed;
    }
  }
}
