package com.example.uthme2

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/// Home-screen widget that renders the grades hero card (produced as a PNG by
/// the Flutter side) and forwards taps to the Dart background callback, which
/// re-scrapes grades or opens the app.
class GradeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.grade_widget).apply {
                val imagePath = widgetData.getString("gradeWidgetImage", null)
                if (imagePath != null) {
                    val file = File(imagePath)
                    if (file.exists()) {
                        setImageViewBitmap(
                            R.id.widget_image,
                            BitmapFactory.decodeFile(file.absolutePath)
                        )
                    }
                }

                val tapIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("uthme2://refresh")
                )
                setOnClickPendingIntent(R.id.widget_root, tapIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
