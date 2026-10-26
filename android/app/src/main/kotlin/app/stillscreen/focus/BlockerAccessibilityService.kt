package app.stillscreen.focus

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import android.view.accessibility.AccessibilityEvent

class BlockerAccessibilityService : AccessibilityService() {

    private var lastPackage: String? = null
    private var lastBeat = 0L
    private val handler = Handler(Looper.getMainLooper())

    /** When one of our own screens last came up. Used to see if a block screen opened. */
    @Volatile
    private var ownScreenAt = 0L

    companion object {
        /**
         * True only while Android has this service connected and running. The
         * "enabled" switch in Accessibility settings can stay on after the
         * phone has stopped the service in the background, so the app checks
         * this as well.
         */
        @Volatile
        var connected: Boolean = false
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        connected = true
        BlockStore.touchActive(this)
        Alerts.clearBlockingOff(this)
    }

    /** Blocking was switched off. Warn only if it matters right now. */
    override fun onUnbind(intent: Intent?): Boolean {
        connected = false
        if (BlockStore.isSessionActive(this) || BlockStore.isWindDownActive(this)) {
            Alerts.showBlockingOff(this)
        }
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        connected = false
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        // Note that the service is alive, at most once a minute.
        val now = System.currentTimeMillis()
        if (now - lastBeat > 60_000L) {
            lastBeat = now
            BlockStore.touchActive(this)
        }

        // Our own screens (block, pause, the app itself) are never blocked. But
        // they must still count as "the app on screen", so that going straight
        // back to a blocked app afterwards is seen as a new visit, not a repeat.
        if (pkg == packageName) {
            lastPackage = pkg
            ownScreenAt = now
            return
        }

        // Ignore repeat events for the same app.
        if (pkg == lastPackage) return
        lastPackage = pkg
        BlockStore.recordSeen(this, pkg)

        // Blocking wins over the mindful pause.
        val blockReason = when {
            BlockStore.isSessionActive(this) && pkg in BlockStore.getBlocked(this) ->
                BlockActivity.REASON_FOCUS
            BlockStore.isWindDownActive(this) && pkg in BlockStore.getWindDownApps(this) ->
                BlockActivity.REASON_WIND_DOWN
            else -> null
        }
        val wantsPause = blockReason == null &&
            PauseStore.isEnabled(this) &&
            pkg in PauseStore.getApps(this) &&
            !PauseStore.isInGrace(this, pkg)

        if (blockReason == null && !wantsPause) return
        if (pkg in BlockStore.protectedPackages(this)) return

        val intent = if (blockReason != null) {
            Intent(this, BlockActivity::class.java).apply {
                putExtra(BlockActivity.EXTRA_PACKAGE, pkg)
                putExtra(BlockActivity.EXTRA_REASON, blockReason)
            }
        } else {
            Intent(this, PauseActivity::class.java).apply {
                putExtra(PauseActivity.EXTRA_PACKAGE, pkg)
            }
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

        val launchedAt = System.currentTimeMillis()
        var outcome = "opened the screen"
        try {
            startActivity(intent)
        } catch (e: Exception) {
            outcome = "could not open the screen (${e.javaClass.simpleName})"
        }
        BlockStore.recordAttempt(this, pkg, outcome)

        // Some phones refuse to open a screen from the background without
        // saying so. If the block screen has not appeared a moment later, send
        // the person Home, so the blocked app is still closed.
        if (blockReason != null) {
            handler.postDelayed({
                if (ownScreenAt < launchedAt) {
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    val label = try {
                        packageManager.getApplicationLabel(
                            packageManager.getApplicationInfo(pkg, 0)
                        ).toString()
                    } catch (e: Exception) {
                        pkg
                    }
                    Toast.makeText(
                        this, "$label is blocked during your focus session", Toast.LENGTH_SHORT
                    ).show()
                    BlockStore.recordAttempt(
                        this, pkg, "block screen did not appear, sent Home instead"
                    )
                }
            }, 1000L)
        }
    }

    override fun onInterrupt() {}
}
