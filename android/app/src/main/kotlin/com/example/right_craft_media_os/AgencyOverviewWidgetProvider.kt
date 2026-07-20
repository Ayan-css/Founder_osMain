package com.example.right_craft_media_os

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AgencyOverviewWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_agency_overview).apply {
                val clients = widgetData.getString("active_clients", "0")
                val revenue = widgetData.getString("total_revenue", "$0.00")
                val expenses = widgetData.getString("total_expenses", "$0.00")
                
                setTextViewText(R.id.clients_value, clients)
                setTextViewText(R.id.revenue_value, revenue)
                setTextViewText(R.id.expenses_value, expenses)

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
