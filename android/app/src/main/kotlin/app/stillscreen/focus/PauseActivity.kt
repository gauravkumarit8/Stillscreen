package app.stillscreen.focus

import android.animation.ObjectAnimator
import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Mindful pause: a short breathing screen before an app the user chose.
 * "Continue" unlocks when the countdown ends. "Not now" goes home.
 */
class PauseActivity : Activity() {

    private var timer: CountDownTimer? = null
    private var target = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        target = intent.getStringExtra(EXTRA_PACKAGE) ?: ""
        val label = labelFor(target)
        val opens = PauseStore.recordShown(this, target)
        val seconds = PauseStore.seconds(this)

        val title = makeText("Take a breath.", 28f, Color.WHITE)
        val subtitle = makeText(
            "You are about to open $label.\n" +
                if (opens == 1) "First time today." else "That is $opens times today.",
            18f,
            0xFF62B5B0.toInt()
        )
        val countdown = makeText("$seconds", 72f, Color.WHITE)
        ObjectAnimator.ofFloat(countdown, "alpha", 0.45f, 1f).apply {
            duration = 2000
            repeatCount = ObjectAnimator.INFINITE
            repeatMode = ObjectAnimator.REVERSE
            start()
        }

        val proceed = styledButton("Continue in $seconds", filled = true).apply {
            isEnabled = false
            setLocked(this, true)
            setOnClickListener {
                PauseStore.grantGrace(this@PauseActivity, target)
                finish()
            }
        }
        val notNow = styledButton("Not now", filled = false).apply {
            setOnClickListener { leave() }
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF14323A.toInt())
            val pad = dp(24)
            setPadding(pad, pad, pad, pad)
            addView(title)
            addView(subtitle)
            addView(countdown)
            addView(proceed, buttonParams())
            addView(notNow, buttonParams())
        }
        setContentView(root)

        timer = object : CountDownTimer(seconds * 1000L, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                val left = ((millisUntilFinished + 999) / 1000).toInt()
                countdown.text = "$left"
                proceed.text = "Continue in $left"
            }

            override fun onFinish() {
                countdown.text = "0"
                proceed.isEnabled = true
                setLocked(proceed, false)
                proceed.text = "Continue to $label"
            }
        }.start()
    }

    /** A second paused app while this screen is open: start over for that app. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        recreate()
    }

    @Deprecated("Back counts as walking away")
    override fun onBackPressed() = leave()

    override fun onDestroy() {
        timer?.cancel()
        super.onDestroy()
    }

    private fun leave() {
        PauseStore.recordResisted(this)
        startActivity(
            Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        finish()
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    private fun buttonParams() = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply { topMargin = dp(12) }

    /** Locked: faint and readable. Unlocked: solid, so the change is obvious. */
    private fun setLocked(button: Button, locked: Boolean) {
        button.setTextColor(if (locked) 0x99FFFFFF.toInt() else 0xFF14323A.toInt())
        (button.background as GradientDrawable)
            .setColor(if (locked) 0x33FFFFFF else 0xFF62B5B0.toInt())
    }

    /** Drawn by hand so it looks the same on every Android version. */
    private fun styledButton(label: String, filled: Boolean) = Button(this).apply {
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
                setStroke(dp(2), 0x99EAF0F1.toInt())
            }
        }
        setPadding(0, dp(14), 0, dp(14))
    }

    private fun makeText(value: String, size: Float, color: Int) = TextView(this).apply {
        text = value
        textSize = size
        gravity = Gravity.CENTER
        setTextColor(color)
        setPadding(0, dp(8), 0, dp(8))
    }

    private fun labelFor(pkg: String): String = try {
        packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
    } catch (e: Exception) {
        "this app"
    }

    companion object {
        const val EXTRA_PACKAGE = "paused_package"
    }
}
