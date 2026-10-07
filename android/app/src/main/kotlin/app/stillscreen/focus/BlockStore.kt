package app.stillscreen.focus

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.telecom.TelecomManager
import java.util.Calendar

/** Shared state between the Flutter UI (via MainActivity) and the accessibility service. */
object BlockStore {
    private const val PREFS = "stillscreen_native"
    private const val KEY_BLOCKED = "blocked"
    private const val KEY_SESSION_END = "session_end"
    private const val KEY_WD_ENABLED = "wd_enabled"
    private const val KEY_WD_DAYS = "wd_days"
    private const val KEY_WD_START = "wd_start"
    private const val KEY_WD_END = "wd_end"
    private const val KEY_WD_APPS = "wd_apps"

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun setBlocked(ctx: Context, packages: Set<String>) {
        prefs(ctx).edit().putStringSet(KEY_BLOCKED, packages).apply()
    }

    fun getBlocked(ctx: Context): Set<String> =
        prefs(ctx).getStringSet(KEY_BLOCKED, emptySet()) ?: emptySet()

    fun startSession(ctx: Context, durationMs: Long) {
        prefs(ctx).edit()
            .putLong(KEY_SESSION_END, System.currentTimeMillis() + durationMs)
            .apply()
    }

    fun stopSession(ctx: Context) {
        prefs(ctx).edit().remove(KEY_SESSION_END).apply()
    }

    fun isSessionActive(ctx: Context): Boolean =
        System.currentTimeMillis() < prefs(ctx).getLong(KEY_SESSION_END, 0L)

    fun setWindDown(
        ctx: Context,
        enabled: Boolean,
        days: Set<Int>,
        startMinute: Int,
        endMinute: Int,
        packages: Set<String>
    ) {
        prefs(ctx).edit()
            .putBoolean(KEY_WD_ENABLED, enabled)
            .putStringSet(KEY_WD_DAYS, days.map { it.toString() }.toSet())
            .putInt(KEY_WD_START, startMinute)
            .putInt(KEY_WD_END, endMinute)
            .putStringSet(KEY_WD_APPS, packages)
            .apply()
    }

    fun getWindDownApps(ctx: Context): Set<String> =
        prefs(ctx).getStringSet(KEY_WD_APPS, emptySet()) ?: emptySet()

    /**
     * True while the scheduled wind-down window is open. Days are ISO numbers
     * (Mon = 1 ... Sun = 7) and name the day the window STARTS on. An overnight
     * window (start later than end, e.g. 18:30 to 08:00) runs into the next
     * morning, so the morning part belongs to the previous day's entry.
     */
    fun isWindDownActive(ctx: Context, now: Calendar = Calendar.getInstance()): Boolean {
        val p = prefs(ctx)
        if (!p.getBoolean(KEY_WD_ENABLED, false)) return false

        val start = p.getInt(KEY_WD_START, 0)
        val end = p.getInt(KEY_WD_END, 0)
        if (start == end) return false

        val days = (p.getStringSet(KEY_WD_DAYS, emptySet()) ?: emptySet())
            .mapNotNull { it.toIntOrNull() }
            .toSet()

        val today = ((now.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1
        val yesterday = ((today + 5) % 7) + 1
        val minute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

        return if (start < end) {
            today in days && minute >= start && minute < end
        } else {
            (today in days && minute >= start) || (yesterday in days && minute < end)
        }
    }

    /**
     * Apps that must never be blocked: Stillscreen itself, the phone dialer and
     * system Settings. A strict session can then never lock someone out of
     * calls (including emergency calls) or of their own phone settings.
     */
    fun protectedPackages(ctx: Context): Set<String> {
        val protectedSet = mutableSetOf(ctx.packageName)
        (ctx.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager)
            ?.defaultDialerPackage
            ?.let { protectedSet.add(it) }
        ctx.packageManager
            .resolveActivity(Intent(Settings.ACTION_SETTINGS), 0)
            ?.activityInfo?.packageName
            ?.let { protectedSet.add(it) }
        return protectedSet
    }
}
