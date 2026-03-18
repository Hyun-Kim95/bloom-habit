import 'dart:io';

import 'package:home_widget/home_widget.dart';

/// 홈 위젯에 표시할 데이터 갱신.
/// Android: Glance 위젯(BloomHabitWidgetProvider) 등록 필요.
/// iOS: Widget Extension 추가 필요. 자세한 설정은 home_widget 문서 참고.
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
    // 위젯 미설정 시 무시
  }
}
