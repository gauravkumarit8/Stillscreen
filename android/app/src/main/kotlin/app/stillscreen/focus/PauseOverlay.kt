package app.stillscreen.focus

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * The mindful pause drawn as an accessibility overlay. It is the backup for
 * phones that start the normal pause screen behind the app or refuse to open
 * it from the background. Same words as PauseActivity: a countdown, then
 * "Continue", or "Not now" to go home.
 */
class PauseOverlay(private val service: AccessibilityService) {

    private val handler = Handler(Looper.getMainLooper())
    private var view: View? = null
    private var ticker: Runnable? = null

    /** The app this pause is in front of, or null when nothing is shown. */
    var targetPackage: String? = null
        private set

    val isShowing: Boolean get() = view != null

    fun show(pkg: String): Boolean {
        val existing = view
        if (existing != null) {
            if (existing.isAttachedToWindow) return true
            stopTicker()
            view = null
            targetPackage = null
        }
        return try {
            val wm = service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val content = build(pkg)
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.OPAQUE
            ).apply { gravity = Gravity.CENTER }
            wm.addView(content, params)
            content.requestFocus()
            view = content
            targetPackage = pkg
            true
        } catch (e: Exception) {
            stopTicker()
            view = null
            targetPackage = null
            false
        }
    }

    fun hide() {
        stopTicker()
        val current = view ?: return
        view = null
        targetPackage = null
        try {
            val wm = service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            wm.removeView(current)
        } catch (e: Exception) {
            // Already gone.
        }
    }

    private fun stopTicker() {
        ticker?.let { handler.removeCallbacks(it) }
        ticker = null
    }

    private fun leave() {
        PauseStore.recordResisted(service)
        hide()
        service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
    }

    private fun proceed(pkg: String) {
        PauseStore.grantGrace(service, pkg)
        hide()
    }

    private fun labelFor(pkg: String): String = try {
        service.packageManager.getApplicationLabel(
            service.packageManager.getApplicationInfo(pkg, 0)
        ).toString()
    } catch (e: Exception) {
        pkg
    }

    private fun build(pkg: String): View {
        val density = service.resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val seconds = PauseStore.seconds(service)
        val opens = PauseStore.opensToday(service, pkg)
        val reason = BlockStore.reason(service)

        fun text(value: String, size: Float, color: Int) = TextView(service).apply {
            text = value
            textSize = size
            gravity = Gravity.CENTER
            setTextColor(color)
            setPadding(dp(16), dp(8), dp(16), dp(8))
        }

        val title = text("Take a breath.", 28f, Color.WHITE)
        val subtitle = text(
            "You are about to open ${labelFor(pkg)}.\n" +
                if (opens == 1) "First time today." else "That is $opens times today.",
            18f,
            0xFF62B5B0.toInt()
        )
        val reasonView = text("\u201C$reason\u201D", 18f, Color.WHITE).apply {
            setTypeface(typeface, Typeface.ITALIC)
        }
        val countdown = text("$seconds", 56f, Color.WHITE)

        fun styled(label: String, filled: Boolean) = Button(service).apply {
            text = label
            isAllCaps = false
            textSize = 16f
            stateListAnimator = null
            setTextColor(if (filled) 0xFF14323A.toInt() else Color.WHITE)
            background = GradientDrawable().apply {
                cornerRadius = dp(28).toFloat()
                if (filled) {
                    setColor(0xFF62B5B0.toInt())
                } else {
                    setColor(Color.TRANSPARENT)
                    setStroke(dp(1), 0xFF62B5B0.toInt())
                }
            }
            setPadding(0, dp(14), 0, dp(14))
        }

        val proceedButton = styled("Continue in $seconds", filled = true).apply {
            isEnabled = false
            alpha = 0.5f
            setOnClickListener { proceed(pkg) }
        }
        val notNow = styled("Not now", filled = false).apply {
            setOnClickListener { leave() }
        }

        // Count down once a second. The button unlocks at zero.
        var remaining = seconds
        val tick = object : Runnable {
            override fun run() {
                remaining -= 1
                if (remaining <= 0) {
                    countdown.text = "0"
                    proceedButton.text = "Continue"
                    proceedButton.isEnabled = true
                    proceedButton.alpha = 1f
                } else {
                    countdown.text = "$remaining"
                    proceedButton.text = "Continue in $remaining"
                    handler.postDelayed(this, 1000L)
                }
            }
        }
        ticker = tick
        handler.postDelayed(tick, 1000L)

        val root = object : LinearLayout(service) {
            // Back is "Not now", the same as the button.
            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                if (event.keyCode == KeyEvent.KEYCODE_BACK) {
                    if (event.action == KeyEvent.ACTION_UP) leave()
                    return true
                }
                return super.dispatchKeyEvent(event)
            }
        }
        return root.apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            isFocusable = true
            isFocusableInTouchMode = true
            setBackgroundColor(0xFF14323A.toInt())
            setPadding(dp(24), dp(24), dp(24), dp(24))
            addView(title)
            addView(subtitle)
            if (reason.isNotEmpty()) addView(reasonView)
            addView(countdown)
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(12) }
            addView(proceedButton, params)
            addView(notNow, params)
        }
    }
}
