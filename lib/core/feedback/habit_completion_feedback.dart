import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:vibration/vibration.dart';

/// Haptic + short completion sound for habit check-in.
///
/// Uses [assets/sounds/complete.mp3] on supported platforms; falls back to
/// [SystemSoundType.click] if asset playback fails.
class HabitCompletionFeedback {
  HabitCompletionFeedback._();

  static final AudioPlayer _player = AudioPlayer();
  static const String _soundAssetPath = 'assets/sounds/complete.mp3';
  static bool _soundPrepared = false;
  static bool _soundPreparing = false;

  static Future<void> _ensureSoundPrepared() async {
    if (_soundPrepared || _soundPreparing) return;
    _soundPreparing = true;
    try {
      await _player.setAsset(_soundAssetPath);
      await _player.setVolume(1.0);
      _soundPrepared = true;
      debugPrint(
        'HabitCompletionFeedback: sound asset preloaded {asset: $_soundAssetPath}',
      );
    } catch (e) {
      _soundPrepared = false;
      debugPrint(
        'HabitCompletionFeedback: sound asset preload failed {asset: $_soundAssetPath, error: $e}',
      );
    } finally {
      _soundPreparing = false;
    }
  }

  /// Fire-and-forget: does not await full playback (network work can proceed).
  static Future<bool> trigger({required bool soundEnabled}) async {
    unawaited(_ensureSoundPrepared());
    debugPrint(
      'HabitCompletionFeedback: trigger start {soundEnabled: $soundEnabled}',
    );
    if (!soundEnabled) {
      debugPrint(
        'HabitCompletionFeedback: trigger done {played: true, hapticPlayed: false, soundPlayed: false, routes: [feedback-disabled]}',
      );
      return true;
    }
    var anyFeedbackPlayed = false;
    var hapticPlayed = false;
    var soundPlayed = false;
    final List<String> feedbackRoutes = <String>[];
    var shouldUseVibration = false;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final status = await SoundMode.ringerModeStatus;
        shouldUseVibration = status != RingerModeStatus.normal;
        debugPrint(
          'HabitCompletionFeedback: android ringer mode status=$status -> vibration=$shouldUseVibration',
        );
      } catch (e) {
        debugPrint(
          'HabitCompletionFeedback: failed to read ringer mode, fallback to sound path: $e',
        );
      }
    }

    if (shouldUseVibration) {
      try {
        await HapticFeedback.mediumImpact();
        anyFeedbackPlayed = true;
        hapticPlayed = true;
        feedbackRoutes.add('haptic-mediumImpact');
        debugPrint('HabitCompletionFeedback: haptic mediumImpact success');
      } catch (e) {
        debugPrint('HabitCompletionFeedback: haptic failed: $e');
        try {
          await HapticFeedback.selectionClick();
          anyFeedbackPlayed = true;
          hapticPlayed = true;
          feedbackRoutes.add('haptic-selectionClick');
          debugPrint(
            'HabitCompletionFeedback: haptic selectionClick fallback success',
          );
        } catch (fallbackError) {
          debugPrint(
            'HabitCompletionFeedback: haptic fallback failed: $fallbackError',
          );
        }
      }
      if (!hapticPlayed || _canForceStrongHapticOnAndroid()) {
        try {
          final hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator) {
            final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
            await Vibration.vibrate(
              duration: 260,
              amplitude: hasAmplitudeControl ? 180 : -1,
            );
            anyFeedbackPlayed = true;
            hapticPlayed = true;
            feedbackRoutes.add('haptic-vibrationPlugin');
            debugPrint(
              'HabitCompletionFeedback: vibration plugin fallback success {hasAmplitudeControl: $hasAmplitudeControl}',
            );
          } else {
            debugPrint(
              'HabitCompletionFeedback: vibration plugin fallback skipped (no vibrator)',
            );
          }
        } catch (pluginError) {
          debugPrint(
            'HabitCompletionFeedback: vibration plugin fallback failed: $pluginError',
          );
        }
      }
      debugPrint(
        'HabitCompletionFeedback: trigger done {played: $anyFeedbackPlayed, hapticPlayed: $hapticPlayed, soundPlayed: $soundPlayed, routes: $feedbackRoutes}',
      );
      return anyFeedbackPlayed;
    }
    try {
      if (!_soundPrepared) {
        await _ensureSoundPrepared();
      }
      await _player.setVolume(1.0);
      await _player.seek(Duration.zero);
      unawaited(_player.play());
      anyFeedbackPlayed = true;
      soundPlayed = true;
      feedbackRoutes.add('sound-asset');
      debugPrint(
        'HabitCompletionFeedback: asset sound play success {asset: $_soundAssetPath}',
      );
    } catch (e) {
      _soundPrepared = false;
      debugPrint(
        'HabitCompletionFeedback: asset sound failed, fallback to system alert/click: $e',
      );
      try {
        await SystemSound.play(SystemSoundType.alert);
        anyFeedbackPlayed = true;
        soundPlayed = true;
        feedbackRoutes.add('sound-systemAlert');
        debugPrint('HabitCompletionFeedback: system alert fallback success');
      } catch (alertError) {
        debugPrint('HabitCompletionFeedback: system alert failed: $alertError');
      }
      try {
        await SystemSound.play(SystemSoundType.click);
        anyFeedbackPlayed = true;
        soundPlayed = true;
        feedbackRoutes.add('sound-systemClick');
        debugPrint('HabitCompletionFeedback: system click fallback success');
      } catch (fallbackError) {
        debugPrint(
          'HabitCompletionFeedback: system click fallback failed: $fallbackError',
        );
      }
    }
    debugPrint(
      'HabitCompletionFeedback: trigger done {played: $anyFeedbackPlayed, hapticPlayed: $hapticPlayed, soundPlayed: $soundPlayed, routes: $feedbackRoutes}',
    );
    return anyFeedbackPlayed;
  }

  static bool _canForceStrongHapticOnAndroid() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }
}
