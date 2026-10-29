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
    private const val KEY_SESSION_START = "session_start"
    private const val KEY_LAST_ACTIVE = "last_active"
    private const val KEY_SEEN_PKG = "seen_pkg"
    private const val KEY_SEEN_AT = "seen_at"
    private const val KEY_TRY_PKG = "try_pkg"
    private const val KEY_TRY_AT = "try_at"
    private const val KEY_TRY_RESULT = "try_result"
    private const val KEY_EVENT_LOG = "event_log"
    private const val KEY_REASON = "reason"
    private const val LEDGER_PREFIX = "mins_"
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
        settleFinished(ctx)
        val now = System.currentTimeMillis()
        prefs(ctx).edit()
            .putLong(KEY_SESSION_START, now)
            .putLong(KEY_SESSION_END, now + durationMs)
            .apply()
        logEvent(
            ctx, "session",
            "started for ${durationMs / 60_000L} min, ${getBlocked(ctx).size} app(s) in the blocked list"
        )
    }

    /** The user ended the session early, or Flutter is clearing one that finished. */
    fun stopSession(ctx: Context) {
        val p = prefs(ctx)
        val start = p.getLong(KEY_SESSION_START, 0L)
        val end = p.getLong(KEY_SESSION_END, 0L)
        if (start != 0L && end != 0L) {
            credit(ctx, start, minOf(System.currentTimeMillis(), end))
        }
        p.edit().remove(KEY_SESSION_START).remove(KEY_SESSION_END).apply()
        if (start != 0L) logEvent(ctx, "session", "ended early")
    }

    /**
     * Credits a session that ran to its end while the app was closed. It never
     * touches a session that is still running.
     */
    fun settleFinished(ctx: Context) {
        val p = prefs(ctx)
        val start = p.getLong(KEY_SESSION_START, 0L)
        val end = p.getLong(KEY_SESSION_END, 0L)
        if (start == 0L || end == 0L || System.currentTimeMillis() < end) return
        credit(ctx, start, end)
        p.edit().remove(KEY_SESSION_START).remove(KEY_SESSION_END).apply()
        if (start != 0L) logEvent(ctx, "session", "finished")
    }

    /** Minutes focused today, as far as this side knows. Keeps the reminder quiet. */
    fun minutesToday(ctx: Context): Int {
        settleFinished(ctx)
        return prefs(ctx).getInt(LEDGER_PREFIX + Reminder.dayKey(Calendar.getInstance()), 0)
    }

    /**
     * Adds the minutes of a finished session to the day ledger. A session that
     * runs past midnight is split, so each day gets its own share.
     */
    private fun credit(ctx: Context, start: Long, end: Long) {
        if (end <= start) return
        val p = prefs(ctx)
        val edit = p.edit()

        var cursor = start
        while (cursor < end) {
            val cal = Calendar.getInstance().apply { timeInMillis = cursor }
            val nextMidnight = (cal.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                add(Calendar.DAY_OF_MONTH, 1)
            }.timeInMillis
            val sliceEnd = minOf(end, nextMidnight)
            val minutes = ((sliceEnd - cursor) / 60_000L).toInt()
            if (minutes > 0) {
                val key = LEDGER_PREFIX + Reminder.dayKey(cal)
                edit.putInt(key, p.getInt(key, 0) + minutes)
            }
            cursor = sliceEnd
        }

        // Keep only the last few days.
        val keep = (0..3).map { daysAgo ->
            Reminder.dayKey(Calendar.getInstance().apply { add(Calendar.DAY_OF_MONTH, -daysAgo) })
        }.toSet()
        for (key in p.all.keys) {
            if (key.startsWith(LEDGER_PREFIX) && key.removePrefix(LEDGER_PREFIX) !in keep) {
                edit.remove(key)
            }
        }
        edit.apply()
    }

    /** Adds time to a session that is still running. False if none is. */
    fun extendSession(ctx: Context, extraMs: Long): Boolean {
        val p = prefs(ctx)
        val end = p.getLong(KEY_SESSION_END, 0L)
        if (System.currentTimeMillis() >= end) return false
        p.edit().putLong(KEY_SESSION_END, end + extraMs).apply()
        return true
    }

    /** The blocking service saw a window change. Shown in the health check. */
    fun touchActive(ctx: Context) {
        prefs(ctx).edit().putLong(KEY_LAST_ACTIVE, System.currentTimeMillis()).apply()
    }

    fun lastActive(ctx: Context): Long = prefs(ctx).getLong(KEY_LAST_ACTIVE, 0L)

    /** The newest app the service noticed, for the health check. */
    fun recordSeen(ctx: Context, pkg: String) {
        prefs(ctx).edit()
            .putString(KEY_SEEN_PKG, pkg)
            .putLong(KEY_SEEN_AT, System.currentTimeMillis())
            .apply()
    }

    /** What happened the last time the service tried to block or pause an app. */
    fun recordAttempt(ctx: Context, pkg: String, result: String) {
        prefs(ctx).edit()
            .putString(KEY_TRY_PKG, pkg)
            .putLong(KEY_TRY_AT, System.currentTimeMillis())
            .putString(KEY_TRY_RESULT, result)
            .apply()
    }

    /**
     * Keeps the last twenty decisions the service made, newest first, so the
     * health check can show why an app was or was not blocked. A line that
     * only repeats the previous one is skipped.
     */
    fun logEvent(ctx: Context, pkg: String, what: String) {
        val p = prefs(ctx)
        val lines = (p.getString(KEY_EVENT_LOG, "") ?: "")
            .split("\n")
            .filter { it.isNotEmpty() }
        if (lines.firstOrNull()?.substringAfter(' ') == "$pkg $what") return
        val time = java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.US)
            .format(java.util.Date())
        val next = (listOf("$time $pkg $what") + lines).take(20)
        p.edit().putString(KEY_EVENT_LOG, next.joinToString("\n")).apply()
    }

    /** One line saying whether a session is running and what it would block. */
    fun stateSummary(ctx: Context): String {
        val end = prefs(ctx).getLong(KEY_SESSION_END, 0L)
        val blocked = getBlocked(ctx).sorted()
        val session = if (System.currentTimeMillis() < end) {
            val until = java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.US)
                .format(java.util.Date(end))
            "Session running until $until"
        } else {
            "No session running"
        }
        val list = if (blocked.isEmpty()) {
            "no apps in the blocked list"
        } else {
            "blocked list (${blocked.size}): " + blocked.take(5).joinToString(", ")
        }
        return "$session. $list."
    }

    fun diagnostics(ctx: Context): Map<String, Any> {
        val p = prefs(ctx)
        return mapOf(
            "seenPackage" to (p.getString(KEY_SEEN_PKG, "") ?: ""),
            "seenAt" to p.getLong(KEY_SEEN_AT, 0L),
            "attemptPackage" to (p.getString(KEY_TRY_PKG, "") ?: ""),
            "attemptAt" to p.getLong(KEY_TRY_AT, 0L),
            "attemptResult" to (p.getString(KEY_TRY_RESULT, "") ?: ""),
            "eventLog" to (p.getString(KEY_EVENT_LOG, "") ?: ""),
            "state" to stateSummary(ctx),
        )
    }

    /** A short personal note shown on the pause and block screens. */
    fun setReason(ctx: Context, reason: String) {
        prefs(ctx).edit().putString(KEY_REASON, reason.trim().take(80)).apply()
    }

    fun reason(ctx: Context): String = prefs(ctx).getString(KEY_REASON, "") ?: ""

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
