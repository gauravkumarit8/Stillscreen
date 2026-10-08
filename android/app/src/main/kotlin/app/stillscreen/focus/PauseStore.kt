package app.stillscreen.focus

import android.content.Context
import java.util.Calendar

/** Settings and counters for Mindful pause. Everything stays on the phone. */
object PauseStore {
    private const val PREFS = "stillscreen_pause"
    private val dayKeyedPattern = Regex("^(?:opens|shown|resisted)_(\\d{8})")

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun configure(
        ctx: Context,
        enabled: Boolean,
        seconds: Int,
        graceMinutes: Int,
        packages: Set<String>
    ) {
        prefs(ctx).edit()
            .putBoolean("enabled", enabled)
            .putInt("seconds", seconds.coerceIn(3, 60))
            .putInt("grace", graceMinutes.coerceIn(1, 60))
            .putStringSet("apps", packages)
            .apply()
    }

    fun isEnabled(ctx: Context) = prefs(ctx).getBoolean("enabled", false)

    fun getApps(ctx: Context): Set<String> =
        prefs(ctx).getStringSet("apps", emptySet()) ?: emptySet()

    fun seconds(ctx: Context) = prefs(ctx).getInt("seconds", 10)

    fun isInGrace(ctx: Context, pkg: String): Boolean =
        System.currentTimeMillis() < prefs(ctx).getLong("grace_$pkg", 0L)

    fun grantGrace(ctx: Context, pkg: String) {
        val minutes = prefs(ctx).getInt("grace", 5)
        prefs(ctx).edit()
            .putLong("grace_$pkg", System.currentTimeMillis() + minutes * 60_000L)
            .apply()
    }

    /** Counts one pause and returns how many times this app has paused you today. */
    fun recordShown(ctx: Context, pkg: String): Int {
        val day = Reminder.dayKey(Calendar.getInstance())
        val p = prefs(ctx)
        val appKey = "opens_${day}_$pkg"
        val opens = p.getInt(appKey, 0) + 1
        p.edit()
            .putInt(appKey, opens)
            .putInt("shown_$day", p.getInt("shown_$day", 0) + 1)
            .apply()
        prune(ctx)
        return opens
    }

    fun recordResisted(ctx: Context) {
        val day = Reminder.dayKey(Calendar.getInstance())
        val p = prefs(ctx)
        p.edit().putInt("resisted_$day", p.getInt("resisted_$day", 0) + 1).apply()
    }

    /** Oldest first, ending today. */
    private fun lastDayKeys(n: Int): List<String> {
        val c = Calendar.getInstance()
        val keys = mutableListOf<String>()
        repeat(n) {
            keys.add(Reminder.dayKey(c))
            c.add(Calendar.DAY_OF_MONTH, -1)
        }
        return keys.reversed()
    }

    fun summary(ctx: Context): Map<String, Int> {
        val p = prefs(ctx)
        val days = lastDayKeys(7)
        val today = days.last()
        return mapOf(
            "shownToday" to p.getInt("shown_$today", 0),
            "resistedToday" to p.getInt("resisted_$today", 0),
            "shownWeek" to days.sumOf { p.getInt("shown_$it", 0) },
            "resistedWeek" to days.sumOf { p.getInt("resisted_$it", 0) }
        )
    }

    /** Drops counters older than a week and grace periods that have ended. */
    private fun prune(ctx: Context) {
        val p = prefs(ctx)
        val keep = lastDayKeys(8).toSet()
        val now = System.currentTimeMillis()
        val edit = p.edit()
        for ((key, value) in p.all) {
            val day = dayKeyedPattern.find(key)?.groupValues?.get(1)
            if (day != null && day !in keep) edit.remove(key)
            if (key.startsWith("grace_") && value is Long && value < now) edit.remove(key)
        }
        edit.apply()
    }
}
