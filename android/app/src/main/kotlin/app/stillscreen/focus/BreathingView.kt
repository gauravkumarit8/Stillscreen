package app.stillscreen.focus

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.view.View
import android.view.animation.LinearInterpolator
import kotlin.math.min

/**
 * A slow breathing guide: a circle that grows for four seconds ("Breathe in")
 * and shrinks for six ("Breathe out"). It runs only while it is on screen.
 * If the phone has animations turned off, it simply stays still.
 */
class BreathingView(context: Context) : View(context) {

    private val density = resources.displayMetrics.density

    private val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0x3362B5B0
        style = Paint.Style.FILL
    }
    private val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF62B5B0.toInt()
        style = Paint.Style.STROKE
        strokeWidth = 3 * density
    }
    private val guide = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0x3362B5B0
        style = Paint.Style.STROKE
        strokeWidth = 1 * density
    }

    private var progress = 0f
    private var inhaling = true
    private var animator: ValueAnimator? = null

    /** Called with "Breathe in" or "Breathe out" when the phase changes. */
    var onPhase: ((String) -> Unit)? = null

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        startBreathing()
    }

    override fun onDetachedFromWindow() {
        stopBreathing()
        super.onDetachedFromWindow()
    }

    private fun startBreathing() {
        if (animator != null) return
        inhaling = true
        onPhase?.invoke("Breathe in")
        animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = CYCLE_MS
            repeatCount = ValueAnimator.INFINITE
            interpolator = LinearInterpolator()
            addUpdateListener { a ->
                val t = a.animatedValue as Float
                val inhale = t < INHALE_SHARE
                progress = if (inhale) {
                    ease(t / INHALE_SHARE)
                } else {
                    1f - ease((t - INHALE_SHARE) / (1f - INHALE_SHARE))
                }
                if (inhale != inhaling) {
                    inhaling = inhale
                    onPhase?.invoke(if (inhale) "Breathe in" else "Breathe out")
                }
                invalidate()
            }
            start()
        }
    }

    private fun stopBreathing() {
        animator?.cancel()
        animator = null
    }

    /** Slow at both ends, so the circle eases in and out like a breath. */
    private fun ease(x: Float) = x * x * (3f - 2f * x)

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val cx = width / 2f
        val cy = height / 2f
        val maxRadius = min(width, height) / 2f - ring.strokeWidth
        if (maxRadius <= 0f) return
        val radius = maxRadius * (0.5f + 0.5f * progress)
        canvas.drawCircle(cx, cy, maxRadius, guide)
        canvas.drawCircle(cx, cy, radius, fill)
        canvas.drawCircle(cx, cy, radius, ring)
    }

    companion object {
        private const val CYCLE_MS = 10_000L
        private const val INHALE_SHARE = 0.4f
    }
}
