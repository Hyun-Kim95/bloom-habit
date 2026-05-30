import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../auth/auth_repository.dart';
import '../router/app_providers.dart';

/// Syncs [MeProfile] to analytics identify/reset on session changes.
class AnalyticsIdentityListener extends ConsumerStatefulWidget {
  const AnalyticsIdentityListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AnalyticsIdentityListener> createState() =>
      _AnalyticsIdentityListenerState();
}

class _AnalyticsIdentityListenerState
    extends ConsumerState<AnalyticsIdentityListener> {
  String? _identifiedUserId;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<MeProfile?>>(meProfileProvider, (previous, next) {
      final profile = next.valueOrNull;
      final analytics = ref.read(analyticsServiceProvider);
      if (profile == null) {
        if (_identifiedUserId != null) {
          _identifiedUserId = null;
          unawaited(analytics.reset());
        }
        return;
      }
      if (_identifiedUserId == profile.id) return;
      _identifiedUserId = profile.id;
      unawaited(
        analytics.identify(
          userId: profile.id,
          userProperties: {'auth_provider': profile.authProvider},
        ),
      );
    });
    return widget.child;
  }
}
