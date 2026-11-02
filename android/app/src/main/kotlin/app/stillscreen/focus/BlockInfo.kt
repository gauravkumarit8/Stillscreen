package app.stillscreen.focus

import android.content.Context
import android.graphics.Typeface
import android.view.Gravity
import android.view.View
import android.widget.TextView

/**
 * What the block screens say besides "blocked". Both screens (the normal one
 * and the overlay that backs it up) use this, so they always match.
 */
object BlockInfo {

    private val TEAL = 0xFF62B5B0.toInt()
    private val WHITE = 0xFFFFFFFF.toInt()
    private val MUTED = 0x99FFFFFF.toInt()

    private val tips = listOf(
        "Breathe in for four, out for six. Do it three times.",
        "An urge fades in about a minute if you do not feed it.",
        "Do only the next small step of your task.",
        "Stand up, drink some water, then start again.",
        "You chose this earlier for a reason. Trust that person.",
        "Ten more minutes. You can stop after that."
    )

    /** The blocked app's name, or "This app" if it cannot be found. */
    fun appName(ctx: Context, pkg: String?): String {
        if (pkg.isNullOrEmpty()) return "This app"
        return try {
            ctx.packageManager.getApplicationLabel(
                ctx.packageManager.getApplicationInfo(pkg, 0)
            ).toString()
        } catch (e: Exception) {
            "This app"
        }
    }

    /** A different tip each minute. */
    fun tip(): String = tips[((System.currentTimeMillis() / 60_000L) % tips.size).toInt()]

    private fun line(ctx: Context, text: String, size: Float, color: Int, italic: Boolean = false): View {
        val density = ctx.resources.displayMetrics.density
        return TextView(ctx).apply {
            this.text = text
            textSize = size
            gravity = Gravity.CENTER
            setTextColor(color)
            if (italic) setTypeface(typeface, Typeface.ITALIC)
            setPadding((16 * density).toInt(), (4 * density).toInt(), (16 * density).toInt(), (4 * density).toInt())
        }
    }

    /** Shown just under the main message: how the session is going, and the exam. */
    fun topViews(ctx: Context, windDown: Boolean): List<View> {
        val views = mutableListOf<View>()
        if (!windDown) {
            BlockStore.sessionProgressLine(ctx)?.let { views += line(ctx, it, 16f, TEAL) }
        }
        BlockStore.examLine(ctx)?.let { views += line(ctx, it, 16f, WHITE) }
        return views
    }

    /** Shown above the button: how often focus won today, and a small tip. */
    fun footerViews(ctx: Context, windDown: Boolean): List<View> {
        val views = mutableListOf<View>()
        if (!windDown) {
            val chosen = BlockStore.focusChosenToday(ctx)
            if (chosen > 0) {
                val times = if (chosen == 1) "1 time" else "$chosen times"
                views += line(ctx, "You have chosen focus $times today.", 14f, MUTED)
            }
            views += line(ctx, tip(), 14f, MUTED, italic = true)
        }
        return views
    }
}
