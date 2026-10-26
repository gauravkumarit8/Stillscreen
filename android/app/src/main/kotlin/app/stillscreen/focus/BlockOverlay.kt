package app.stillscreen.focus

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * A block screen drawn as an accessibility overlay. It is the backup for
 * phones that refuse to open the normal block screen from the background.
 * An accessibility service may add this kind of window without any extra
 * permission or pop-up setting, so it works the same on every brand.
 */
class BlockOverlay(private val service: AccessibilityService) {

    private var view: View? = null

    /** The app this overlay is covering, or null when nothing is shown. */
    var blockedPackage: String? = null
        private set

    val isShowing: Boolean get() = view != null

    /** Returns false if the phone would not let the window be added. */
    fun show(pkg: String, windDown: Boolean): Boolean {
        if (view != null) return true
        return try {
            val wm = service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val content = build(windDown)
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
            blockedPackage = pkg
            true
        } catch (e: Exception) {
            view = null
            blockedPackage = null
            false
        }
    }

    fun hide() {
        val current = view ?: return
        view = null
        blockedPackage = null
        try {
            val wm = service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            wm.removeView(current)
        } catch (e: Exception) {
            // Already gone.
        }
    }

    private fun leave() {
        hide()
        service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
    }

    /** Same words and colours as BlockActivity, so the two look alike. */
    private fun build(windDown: Boolean): View {
        val density = service.resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val message = TextView(service).apply {
            text = if (windDown) {
                "Time to switch off.\nThis app is paused until your work hours start."
            } else {
                "Take a breath.\nThis app is blocked during your focus session."
            }
            textSize = 22f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setPadding(dp(16), dp(24), dp(16), dp(24))
        }
        val reason = BlockStore.reason(service)
        val reasonView = TextView(service).apply {
            text = "\u201C$reason\u201D"
            textSize = 18f
            gravity = Gravity.CENTER
            setTextColor(0xFF62B5B0.toInt())
            setTypeface(typeface, Typeface.ITALIC)
            setPadding(dp(16), 0, dp(16), dp(24))
        }
        val button = Button(service).apply {
            text = if (windDown) "Okay" else "Back to focus"
            isAllCaps = false
            textSize = 16f
            stateListAnimator = null
            setTextColor(0xFF14323A.toInt())
            background = GradientDrawable().apply {
                cornerRadius = dp(28).toFloat()
                setColor(0xFF62B5B0.toInt())
            }
            setPadding(0, dp(14), 0, dp(14))
            setOnClickListener { leave() }
        }

        val root = object : LinearLayout(service) {
            // Back leaves, the same as the button, instead of revealing the app.
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
            addView(message)
            if (reason.isNotEmpty()) addView(reasonView)
            addView(
                button,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )
        }
    }
}
