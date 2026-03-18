package com.example.bloom_habit.glance

import android.content.Context
import android.content.Intent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import com.example.bloom_habit.MainActivity

/**
 * 홈 위젯 UI: 오늘 완료한 습관 수 / 전체 습관 수 표시.
 * 탭 시 앱(MainActivity) 실행.
 */
class BloomHabitGlanceAppWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            val prefs = state.preferences
            val todayCompleted = prefs.getInt("today_completed", 0)
            val totalHabits = prefs.getInt("total_habits", 0)

            BloomHabitContent(
                context = context,
                todayCompleted = todayCompleted,
                totalHabits = totalHabits,
            )
        }
    }
}

@androidx.compose.runtime.Composable
private fun BloomHabitContent(
    context: Context,
    todayCompleted: Int,
    totalHabits: Int,
) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Color(0xFFF0F8FF))
            .padding(16.dp)
            .clickable(onClick = actionStartActivity(Intent(context, MainActivity::class.java))),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "Bloom Habit",
            style = TextStyle(
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
            ),
        )
        Text(
            text = "오늘 $todayCompleted / $totalHabits 완료",
            style = TextStyle(
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
    }
}
