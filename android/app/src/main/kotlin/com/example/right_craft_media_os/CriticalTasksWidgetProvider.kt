package com.example.right_craft_media_os

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class CriticalTasksWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_critical_tasks).apply {
                setTextViewText(R.id.task_1_title, widgetData.getString("task_1_title", "No critical tasks"))
                setTextViewText(R.id.task_2_title, widgetData.getString("task_2_title", ""))
                setTextViewText(R.id.task_3_title, widgetData.getString("task_3_title", ""))

                val pendingIntent = es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("rcmos://app/dashboard")
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
