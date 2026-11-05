package gr.uth.uthme2

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createGradesNotificationChannel()
    }

    // The id must match the channel_id the grades-api notifier sends.
    private fun createGradesNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            "grades",
            getString(R.string.grades_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.grades_channel_description)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
