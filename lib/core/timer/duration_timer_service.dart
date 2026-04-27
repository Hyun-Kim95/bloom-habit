import 'dart:io';

import 'package:flutter/services.dart';

class DurationTimerService {
  static const MethodChannel _channel = MethodChannel(
    'bloom_habit/native_config',
  );

  static bool get supported => Platform.isAndroid;

  static Future<int?> start({required String habitName}) async {
    if (!supported) return null;
    final result = await _channel.invokeMethod<int>('startDurationTimer', {
      'habitName': habitName,
    });
    return result;
  }

  static Future<int?> stop() async {
    if (!supported) return null;
    return _channel.invokeMethod<int>('stopDurationTimer');
  }
}

