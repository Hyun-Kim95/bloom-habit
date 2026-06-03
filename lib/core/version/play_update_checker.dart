import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_version_policy.dart';

/// Checks Play Store for updates on Android. Other platforms return [UpdateKind.none].
class PlayUpdateChecker {
  Future<UpdateCheckResult> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return UpdateCheckResult.none;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      final kind = resolveUpdateKindFromPlayInfo(info);
      if (kind == UpdateKind.none) {
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          debugPrint(
            '[PlayUpdateChecker] update available but kind=none '
            '(flexible=${info.flexibleUpdateAllowed}, '
            'immediate=${info.immediateUpdateAllowed}, '
            'priority=${info.updatePriority})',
          );
        }
        return UpdateCheckResult.none;
      }

      final storeUrl = playStoreUrlForPackage(info.packageName);
      final displayVersion = displayVersionFromPlayInfo(info);

      return UpdateCheckResult(
        kind: kind,
        playInfo: info,
        storeUrl: storeUrl,
        displayVersion: displayVersion,
      );
    } catch (e, st) {
      debugPrint('[PlayUpdateChecker] checkForUpdate failed: $e\n$st');
      return UpdateCheckResult.none;
    }
  }
}
