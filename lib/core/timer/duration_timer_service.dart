import 'dart:io';

import 'package:flutter/services.dart';

class DurationTimerService {
  static const MethodChannel _channel = MethodChannel(
    'habit_fable/native_config',
  );

  static bool get supported => Platform.isAndroid;

  static Future<int?> start({
    required String habitName,
    String? habitId,
  }) async {
    if (!supported) return null;
    final result = await _channel.invokeMethod<int>('startDurationTimer', {
      'habitName': habitName,
      'habitId': habitId,
    });
    return result;
  }

  static Future<int?> stop() async {
    if (!supported) return null;
    return _channel.invokeMethod<int>('stopDurationTimer');
  }

  static Future<DurationTimerState> getState() async {
    if (!supported) return const DurationTimerState();
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getDurationTimerState',
    );
    if (raw == null) return const DurationTimerState();
    return DurationTimerState(
      running: raw['running'] == true,
      habitId: raw['habitId'] as String?,
      habitName: raw['habitName'] as String?,
      startedAtMs: (raw['startedAtMs'] as num?)?.toInt(),
      elapsedMs: (raw['elapsedMs'] as num?)?.toInt(),
    );
  }
}

class DurationTimerState {
  const DurationTimerState({
    this.running = false,
    this.habitId,
    this.habitName,
    this.startedAtMs,
    this.elapsedMs,
  });

  final bool running;
  final String? habitId;
  final String? habitName;
  final int? startedAtMs;
  final int? elapsedMs;
}
