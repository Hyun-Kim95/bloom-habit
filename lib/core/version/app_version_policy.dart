import 'package:in_app_update/in_app_update.dart';

import 'app_update_config.dart';

enum UpdateKind { none, optional, forced }

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.kind,
    this.playInfo,
    this.storeUrl = '',
    this.displayVersion = '',
  });

  final UpdateKind kind;
  final AppUpdateInfo? playInfo;
  final String storeUrl;
  final String displayVersion;

  static const none = UpdateCheckResult(kind: UpdateKind.none);

  bool get isForced => kind == UpdateKind.forced;
  bool get isOptional => kind == UpdateKind.optional;
}

String playStoreUrlForPackage(String packageName) {
  final trimmed = packageName.trim();
  if (trimmed.isEmpty) return '';
  return 'https://play.google.com/store/apps/details?id=$trimmed';
}

/// Maps Play [AppUpdateInfo] to forced / optional / none using [updatePriority].
UpdateKind resolveUpdateKindFromPlayInfo(
  AppUpdateInfo info, {
  int immediateThreshold = kImmediateUpdatePriorityThreshold,
}) {
  if (info.updateAvailability != UpdateAvailability.updateAvailable) {
    return UpdateKind.none;
  }
  if (info.updatePriority >= immediateThreshold &&
      info.immediateUpdateAllowed) {
    return UpdateKind.forced;
  }
  if (info.flexibleUpdateAllowed) {
    return UpdateKind.optional;
  }
  if (info.immediateUpdateAllowed) {
    return UpdateKind.forced;
  }
  return UpdateKind.none;
}

String displayVersionFromPlayInfo(AppUpdateInfo info) {
  final code = info.availableVersionCode;
  if (code != null) return code.toString();
  return '';
}
