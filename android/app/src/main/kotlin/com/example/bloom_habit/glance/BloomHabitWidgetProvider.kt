package com.example.bloom_habit.glance

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/**
 * home_widget 플러그인이 위젯 갱신 시 호출하는 Receiver.
 * qualifiedAndroidName: com.example.bloom_habit.glance.BloomHabitWidgetProvider
 */
class BloomHabitWidgetProvider : HomeWidgetGlanceWidgetReceiver<BloomHabitGlanceAppWidget>() {
    override val glanceAppWidget = BloomHabitGlanceAppWidget()
}
