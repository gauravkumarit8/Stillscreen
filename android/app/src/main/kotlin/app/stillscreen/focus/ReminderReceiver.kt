package app.stillscreen.focus

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Fires the daily reminder, and re-arms it after a reboot or an app update. */
class ReminderReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (!Reminder.isEnabled(context)) return

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> Reminder.schedule(context)

            Reminder.ACTION_REMIND -> {
                if (!Reminder.goalReachedToday(context)) Reminder.showNotification(context)
                Reminder.schedule(context) // always line up tomorrow's
            }
        }
    }
}
