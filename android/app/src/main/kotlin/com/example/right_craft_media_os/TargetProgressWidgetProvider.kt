package com.example.right_craft_media_os

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class TargetProgressWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_target_progress).apply {
                setTextViewText(R.id.mrr_current, widgetData.getString("mrr_current", "$0"))
                setTextViewText(R.id.mrr_target, widgetData.getString("mrr_target", "$0"))
                setProgressBar(R.id.mrr_progress_bar, 100, widgetData.getLong("mrr_progress_percent", 0L).toInt(), false)
                
                // Deep link to dashboard
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
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
