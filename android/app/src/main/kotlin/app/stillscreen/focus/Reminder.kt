package app.stillscreen.focus

import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.util.Calendar
import java.util.Locale

/**
 * Daily reminder. It uses an inexact alarm, so it needs no special exact-alarm
 * permission and the notification may arrive a few minutes late. Everything
 * happens on the phone.
 */
object Reminder {
    const val ACTION_REMIND = "app.stillscreen.focus.REMIND"

    private const val PREFS = "stillscreen_reminder"
    private const val CHANNEL_ID = "daily_reminder"
    private const val ALARM_REQUEST = 1001
    private const val NOTIFICATION_ID = 2001
    private const val DEFAULT_MINUTE = 18 * 60

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun configure(ctx: Context, enabled: Boolean, minuteOfDay: Int, title: String, body: String) {
        prefs(ctx).edit()
            .putBoolean("enabled", enabled)
            .putInt("minute", minuteOfDay)
            .putString("title", title)
            .putString("body", body)
            .apply()
        if (enabled) schedule(ctx) else cancel(ctx)
    }

    fun isEnabled(ctx: Context) = prefs(ctx).getBoolean("enabled", false)

    fun markGoalReached(ctx: Context, dayKey: String) {
        prefs(ctx).edit().putString("goal_day", dayKey).apply()
    }

    fun goalReachedToday(ctx: Context): Boolean =
        prefs(ctx).getString("goal_day", null) == dayKey(Calendar.getInstance())

    /** Same "yyyyMMdd" format the Dart side uses. */
    fun dayKey(c: Calendar): String = String.format(
        Locale.US, "%04d%02d%02d",
        c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH)
    )

    /** Next time the clock shows [minuteOfDay]: today if still ahead, else tomorrow. */
    fun nextTriggerMillis(minuteOfDay: Int, now: Calendar = Calendar.getInstance()): Long {
        val target = (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, minuteOfDay / 60)
            set(Calendar.MINUTE, minuteOfDay % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (!target.after(now)) target.add(Calendar.DAY_OF_MONTH, 1)
        return target.timeInMillis
    }

    fun schedule(ctx: Context) {
        val alarms = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val trigger = nextTriggerMillis(prefs(ctx).getInt("minute", DEFAULT_MINUTE))
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, alarmIntent(ctx))
    }

    fun cancel(ctx: Context) {
        val alarms = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.cancel(alarmIntent(ctx))
    }

    private fun alarmIntent(ctx: Context): PendingIntent = PendingIntent.getBroadcast(
        ctx,
        ALARM_REQUEST,
        Intent(ctx, ReminderReceiver::class.java).setAction(ACTION_REMIND),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    @SuppressLint("MissingPermission")
    fun showNotification(ctx: Context) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(ctx, "android.permission.POST_NOTIFICATIONS")
            != PackageManager.PERMISSION_GRANTED
        ) return
        if (!NotificationManagerCompat.from(ctx).areNotificationsEnabled()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Daily reminder", NotificationManager.IMPORTANCE_DEFAULT)
                    .apply { description = "A daily nudge to start a focus session" }
            )
        }

        val launch = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName) ?: return
        val open = PendingIntent.getActivity(
            ctx, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val p = prefs(ctx)
        val notification = NotificationCompat.Builder(ctx, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_stillscreen)
            .setContentTitle(p.getString("title", "Time to focus"))
            .setContentText(p.getString("body", "A short session keeps your streak going."))
            .setContentIntent(open)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        NotificationManagerCompat.from(ctx).notify(NOTIFICATION_ID, notification)
    }
}
