import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

import '../router/app_providers.dart';
import 'app_update_dialog.dart';
import 'app_update_service.dart';
import 'app_version_policy.dart';

/// Listens for version check results and shows update dialogs once per launch.
class AppUpdateListener extends ConsumerStatefulWidget {
  const AppUpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateListener> createState() => _AppUpdateListenerState();
}

class _AppUpdateListenerState extends ConsumerState<AppUpdateListener> {
  bool _handledThisLaunch = false;
  bool _dialogVisible = false;
  final _updateService = AppUpdateService();
  StreamSubscription<InstallStatus>? _installSub;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      _installSub = InAppUpdate.installUpdateListener.listen((status) {
        if (status == InstallStatus.downloaded && mounted) {
          showFlexibleUpdateReadySnackBar(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _installSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UpdateCheckResult>>(appVersionCheckProvider, (
      previous,
      next,
    ) {
      next.whenData((result) {
        if (_handledThisLaunch || _dialogVisible) return;
        if (result.kind == UpdateKind.none) {
          _handledThisLaunch = true;
          return;
        }
        unawaited(_presentDialog(result));
      });
    });

    return widget.child;
  }

  Future<void> _presentDialog(UpdateCheckResult result) async {
    if (!mounted || _dialogVisible) return;
    _dialogVisible = true;

    final snooze = await ref.read(appUpdateSnoozeProvider.future);

    if (!mounted) return;
    if (result.isOptional && snooze.isSnoozedToday) {
      _handledThisLaunch = true;
      _dialogVisible = false;
      return;
    }

    await showAppUpdateDialog(
      context: context,
      result: result,
      updateService: _updateService,
      snooze: snooze,
      onFlexibleDownloadStarted: () {
        if (!mounted) return;
        showFlexibleUpdateReadySnackBar(context);
      },
    );

    if (mounted) {
      _handledThisLaunch = true;
      _dialogVisible = false;
    }
  }
}
