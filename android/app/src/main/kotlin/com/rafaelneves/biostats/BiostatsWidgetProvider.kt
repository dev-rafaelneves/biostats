package com.rafaelneves.biostats

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class BiostatsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.biostats_widget).apply {
                val weight = widgetData.getString("weight_value", "--") ?: "--"
                val unit = widgetData.getString("weight_unit", "kg") ?: "kg"
                val trend = widgetData.getString("trend_label", "Sem registros") ?: "Sem registros"
                val streak = widgetData.getString("streak_label", "0 dias") ?: "0 dias"

                setTextViewText(R.id.widget_weight_value, weight)
                setTextViewText(R.id.widget_weight_unit, unit)
                setTextViewText(R.id.widget_trend_label, trend)
                setTextViewText(R.id.widget_streak_label, streak)

                // Ao clicar no widget ou no botão "+ Registrar", abre o app
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                setOnClickPendingIntent(R.id.widget_btn_register, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
