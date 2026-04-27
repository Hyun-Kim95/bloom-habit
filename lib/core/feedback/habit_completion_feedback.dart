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
    debugPrint(
      'HabitCompletionFeedback: trigger start {hapticEnabled: $hapticEnabled, soundEnabled: $soundEnabled}',
    );
    var anyFeedbackPlayed = false;
    var hapticPlayed = false;
    var soundPlayed = false;
    if (hapticEnabled) {
      try {
        await HapticFeedback.mediumImpact();
        anyFeedbackPlayed = true;
        hapticPlayed = true;
        debugPrint('HabitCompletionFeedback: haptic mediumImpact success');
      } catch (e) {
        debugPrint('HabitCompletionFeedback: haptic failed: $e');
        try {
          await HapticFeedback.selectionClick();
          anyFeedbackPlayed = true;
          hapticPlayed = true;
          debugPrint(
            'HabitCompletionFeedback: haptic selectionClick fallback success',
          );
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
      soundPlayed = true;
      debugPrint('HabitCompletionFeedback: asset sound play success');
    } catch (e) {
      debugPrint(
        'HabitCompletionFeedback: asset sound failed, fallback to system alert/click: $e',
      );
      try {
        await SystemSound.play(SystemSoundType.alert);
        anyFeedbackPlayed = true;
        soundPlayed = true;
        debugPrint('HabitCompletionFeedback: system alert fallback success');
      } catch (alertError) {
        debugPrint('HabitCompletionFeedback: system alert failed: $alertError');
      }
      try {
        await SystemSound.play(SystemSoundType.click);
        anyFeedbackPlayed = true;
        soundPlayed = true;
        debugPrint('HabitCompletionFeedback: system click fallback success');
      } catch (fallbackError) {
        debugPrint(
          'HabitCompletionFeedback: system click fallback failed: $fallbackError',
        );
      }
    }
    debugPrint(
      'HabitCompletionFeedback: trigger done {played: $anyFeedbackPlayed, hapticPlayed: $hapticPlayed, soundPlayed: $soundPlayed}',
    );
    return anyFeedbackPlayed;
  }
}
