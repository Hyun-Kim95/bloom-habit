import 'package:flutter_test/flutter_test.dart';
import 'package:habit_fable/core/version/app_update_config.dart';
import 'package:habit_fable/core/version/app_version_policy.dart';
import 'package:in_app_update/in_app_update.dart';

AppUpdateInfo _playInfo({
  UpdateAvailability availability = UpdateAvailability.updateAvailable,
  int updatePriority = 2,
  bool immediateUpdateAllowed = true,
  bool flexibleUpdateAllowed = true,
}) {
  return AppUpdateInfo(
    updateAvailability: availability,
    immediateUpdateAllowed: immediateUpdateAllowed,
    immediateAllowedPreconditions: const [],
    flexibleUpdateAllowed: flexibleUpdateAllowed,
    flexibleAllowedPreconditions: const [],
    availableVersionCode: 42,
    installStatus: InstallStatus.unknown,
    packageName: 'com.khyun.bloom_habit',
    clientVersionStalenessDays: null,
    updatePriority: updatePriority,
  );
}

void main() {
  group('resolveUpdateKindFromPlayInfo', () {
    test('returns none when update not available', () {
      expect(
        resolveUpdateKindFromPlayInfo(
          _playInfo(availability: UpdateAvailability.updateNotAvailable),
        ),
        UpdateKind.none,
      );
    });

    test('returns optional for low priority with flexible allowed', () {
      expect(
        resolveUpdateKindFromPlayInfo(_playInfo(updatePriority: 2)),
        UpdateKind.optional,
      );
    });

    test('returns forced when priority at threshold and immediate allowed', () {
      expect(
        resolveUpdateKindFromPlayInfo(
          _playInfo(
            updatePriority: kImmediateUpdatePriorityThreshold,
          ),
        ),
        UpdateKind.forced,
      );
    });

    test('returns forced when only immediate is allowed', () {
      expect(
        resolveUpdateKindFromPlayInfo(
          _playInfo(
            updatePriority: 1,
            flexibleUpdateAllowed: false,
            immediateUpdateAllowed: true,
          ),
        ),
        UpdateKind.forced,
      );
    });

    test('returns none when no update path allowed', () {
      expect(
        resolveUpdateKindFromPlayInfo(
          _playInfo(
            flexibleUpdateAllowed: false,
            immediateUpdateAllowed: false,
          ),
        ),
        UpdateKind.none,
      );
    });
  });

  group('playStoreUrlForPackage', () {
    test('builds play store url', () {
      expect(
        playStoreUrlForPackage('com.example.app'),
        'https://play.google.com/store/apps/details?id=com.example.app',
      );
    });
  });
}
