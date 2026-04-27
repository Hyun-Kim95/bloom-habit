import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Haptic + short completion sound for habit check-in.
///
/// Uses [assets/sounds/complete.wav] on supported platforms; falls back to
/// [SystemSoundType.click] if asset playback fails.
class HabitCompletionFeedback {
  HabitCompletionFeedback._();

  static final AudioPlayer _player = AudioPlayer();

  /// Fire-and-forget: does not await full playback (network work can proceed).
  static Future<bool> trigger({
    required bool hapticEnabled,
    required bool soundEnabled,
  }) async {
    var anyFeedbackPlayed = false;
    if (hapticEnabled) {
      try {
        await HapticFeedback.mediumImpact();
        anyFeedbackPlayed = true;
      } catch (e) {
        debugPrint('HabitCompletionFeedback: haptic failed: $e');
        try {
          await HapticFeedback.selectionClick();
          anyFeedbackPlayed = true;
        } catch (fallbackError) {
          debugPrint(
            'HabitCompletionFeedback: haptic fallback failed: $fallbackError',
          );
        }
      }
    }
    if (!soundEnabled) return anyFeedbackPlayed;
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/complete.wav');
      await _player.setVolume(1.0);
      await _player.seek(Duration.zero);
      unawaited(_player.play());
      anyFeedbackPlayed = true;
    } catch (e) {
      debugPrint(
        'HabitCompletionFeedback: asset sound failed, fallback to system alert/click: $e',
      );
      try {
        await SystemSound.play(SystemSoundType.alert);
        anyFeedbackPlayed = true;
      } catch (alertError) {
        debugPrint('HabitCompletionFeedback: system alert failed: $alertError');
      }
      try {
        await SystemSound.play(SystemSoundType.click);
        anyFeedbackPlayed = true;
      } catch (fallbackError) {
        debugPrint(
          'HabitCompletionFeedback: system click fallback failed: $fallbackError',
        );
      }
    }
    return anyFeedbackPlayed;
  }
}
