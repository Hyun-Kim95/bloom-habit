import 'dart:io';

import 'package:home_widget/home_widget.dart';

/// Update data displayed in Home Widget.
/// Android: requires Glance widget provider registration.
/// iOS: requires Widget Extension setup.
Future<void> updateHomeWidget({
  required int todayCompleted,
  required int totalHabits,
}) async {
  try {
    await HomeWidget.saveWidgetData<int>('today_completed', todayCompleted);
    await HomeWidget.saveWidgetData<int>('total_habits', totalHabits);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: Platform.isAndroid
          ? 'com.example.bloom_habit.glance.BloomHabitWidgetProvider'
          : null,
      androidName: 'BloomHabitWidgetProvider',
      iOSName: 'BloomHabitWidget',
    );
  } catch (_) {
    // Ignore when widget integration is not configured.
  }
}
