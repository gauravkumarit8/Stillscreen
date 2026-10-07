package app.stillscreen.focus

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/** Simple pause screen. Built in code to avoid extra layout resources for now. */
class BlockActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val windDown = intent.getStringExtra(EXTRA_REASON) == REASON_WIND_DOWN

        val message = TextView(this).apply {
            text = if (windDown) {
                "Time to switch off.\nThis app is paused until your work hours start."
            } else {
                "Take a breath.\nThis app is blocked during your focus session."
            }
            textSize = 22f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setPadding(64, 64, 64, 64)
        }
        val button = Button(this).apply {
            text = if (windDown) "Okay" else "Back to focus"
            setOnClickListener { goHome() }
        }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF14323A.toInt())
            addView(message)
            addView(button)
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
