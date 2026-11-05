package gr.uth.uthme2

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    // Ids must match the channel_id values the grades-api notifier sends.
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val grades = NotificationChannel(
            "grades",
            getString(R.string.grades_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.grades_channel_description)
        }
        val menus = NotificationChannel(
            "menus",
            getString(R.string.menus_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = getString(R.string.menus_channel_description)
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannels(listOf(grades, menus))
    }
}
