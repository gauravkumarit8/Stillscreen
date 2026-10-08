package app.stillscreen.focus

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/** Block screen for focus sessions and wind-down. Built in code, no layout files. */
class BlockActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val windDown = intent.getStringExtra(EXTRA_REASON) == REASON_WIND_DOWN
        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val message = TextView(this).apply {
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
        val button = Button(this).apply {
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
            setOnClickListener { goHome() }
        }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF14323A.toInt())
            setPadding(dp(24), dp(24), dp(24), dp(24))
            addView(message)
            addView(
                button,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )
        }
        setContentView(root)
    }

    @Deprecated("Back always returns home while blocking is active")
    override fun onBackPressed() = goHome()

    private fun goHome() {
        startActivity(
            Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        finish()
    }

    companion object {
        const val EXTRA_PACKAGE = "blocked_package"
        const val EXTRA_REASON = "block_reason"
        const val REASON_FOCUS = "focus"
        const val REASON_WIND_DOWN = "wind_down"
    }
}
