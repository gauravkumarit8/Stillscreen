package app.stillscreen.focus

import android.content.Context

/** Shared state between the Flutter UI (via MainActivity) and the accessibility service. */
object BlockStore {
    private const val PREFS = "stillscreen_native"
    private const val KEY_BLOCKED = "blocked"
    private const val KEY_SESSION_END = "session_end"

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
}
