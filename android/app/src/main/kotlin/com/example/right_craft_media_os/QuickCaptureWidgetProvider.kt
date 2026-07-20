package com.example.right_craft_media_os

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class QuickCaptureWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick_capture).apply {
                val taskIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    OverlayActivity::class.java,
                    android.net.Uri.parse("rcmos://app/quick-add/task")
                )
                setOnClickPendingIntent(R.id.btn_add_task, taskIntent)

                val leadIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    OverlayActivity::class.java,
                    android.net.Uri.parse("rcmos://app/quick-add/lead")
                )
                setOnClickPendingIntent(R.id.btn_add_lead, leadIntent)

                val outreachIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    OverlayActivity::class.java,
                    android.net.Uri.parse("rcmos://app/quick-add/outreach")
                )
                setOnClickPendingIntent(R.id.btn_add_outreach, outreachIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
