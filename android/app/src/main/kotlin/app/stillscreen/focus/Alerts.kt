package app.stillscreen.focus

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * A warning for the moment blocking stops working while it matters. Blocking
 * can be switched off by the phone after a restart, an update or a battery
 * saver, and people otherwise find out only after they have scrolled.
 */
object Alerts {
    private const val CHANNEL_ID = "blocking_alerts"
    private const val NOTIFICATION_ID = 2002

    @SuppressLint("MissingPermission")
    fun showBlockingOff(ctx: Context) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(ctx, "android.permission.POST_NOTIFICATIONS")
            != PackageManager.PERMISSION_GRANTED
        ) return
        if (!NotificationManagerCompat.from(ctx).areNotificationsEnabled()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Blocking alerts", NotificationManager.IMPORTANCE_DEFAULT)
                    .apply { description = "A warning if blocking switches off during a session" }
            )
        }

        val open = PendingIntent.getActivity(
            ctx,
            1,
            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(ctx, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_stillscreen)
            .setContentTitle("Blocking was switched off")
            .setContentText("Tap to turn it back on, so your session or wind-down keeps working.")
            .setContentIntent(open)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        NotificationManagerCompat.from(ctx).notify(NOTIFICATION_ID, notification)
    }

    fun clearBlockingOff(ctx: Context) {
        NotificationManagerCompat.from(ctx).cancel(NOTIFICATION_ID)
    }
}
