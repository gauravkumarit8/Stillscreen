package app.stillscreen.focus

import android.animation.ObjectAnimator
import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.view.ViewGroup
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

        val proceed = Button(this).apply {
            isEnabled = false
            text = "Continue in $seconds"
            setOnClickListener {
                PauseStore.grantGrace(this@PauseActivity, target)
                finish()
            }
        }
        val notNow = Button(this).apply {
            text = "Not now"
            setOnClickListener { leave() }
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF14323A.toInt())
            setPadding(48, 48, 48, 48)
            addView(title)
            addView(subtitle)
            addView(countdown)
            addView(proceed, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
            addView(notNow, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
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

    private fun makeText(value: String, size: Float, color: Int) = TextView(this).apply {
        text = value
        textSize = size
        gravity = Gravity.CENTER
        setTextColor(color)
        setPadding(0, 24, 0, 24)
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
