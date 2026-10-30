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
    private val overlay = BlockOverlay(this)
    private val pauseOverlay = PauseOverlay(this)

    /** When one of our own screens last came up. Used to see if a block screen opened. */
    @Volatile
    private var ownScreenAt = 0L

    private var lastBlockPkg: String? = null
    private var lastBlockAt = 0L

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
        overlay.hide()
        pauseOverlay.hide()
        if (BlockStore.isSessionActive(this) || BlockStore.isWindDownActive(this)) {
            Alerts.showBlockingOff(this)
        }
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        connected = false
        handler.removeCallbacksAndMessages(null)
        overlay.hide()
        pauseOverlay.hide()
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

        // The overlay only belongs on top of the app it blocked. Once the
        // person is in some other app (Home, for example), take it down.
        if (overlay.isShowing && pkg != overlay.blockedPackage && pkg != packageName) {
            overlay.hide()
        }
        if (pauseOverlay.isShowing && pkg != pauseOverlay.targetPackage && pkg != packageName) {
            pauseOverlay.hide()
        }

        // Our own screens (block, pause, the app itself) are never blocked. But
        // they must still count as "the app on screen", so that going straight
        // back to a blocked app afterwards is seen as a new visit, not a repeat.
        if (pkg == packageName) {
            lastPackage = pkg
            ownScreenAt = now
            return
        }

        // An event for the app already on record is a repeat. Repeats are
        // normally ignored, but a blocked app that shows up again must be
        // blocked again. Some phones do not report the person leaving an app,
        // so the "other app in between" is not always seen.
        val repeat = pkg == lastPackage
        lastPackage = pkg
        if (!repeat) BlockStore.recordSeen(this, pkg)

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

        // Only write to the activity log while something could be blocked.
        // Otherwise every app you open would fill it with noise.
        val somethingActive =
            BlockStore.isSessionActive(this) || BlockStore.isWindDownActive(this)

        if (repeat) {
            // Skip only if this very app was blocked a moment ago, which is
            // the block screen's own window settling.
            val justBlocked = pkg == lastBlockPkg && now - lastBlockAt < 3_000L
            if (blockReason == null || justBlocked) {
                if (somethingActive) BlockStore.logEvent(this, pkg, "same app again, ignored")
                return
            }
        }

        if (blockReason == null && !wantsPause) {
            if (somethingActive) {
                val why = if (pkg !in BlockStore.getBlocked(this)) {
                    "not in your blocked list"
                } else {
                    "not blocked"
                }
                BlockStore.logEvent(this, pkg, why)
            }
            return
        }
        if (pkg in BlockStore.protectedPackages(this)) {
            BlockStore.logEvent(this, pkg, "protected app, never blocked")
            return
        }
        BlockStore.logEvent(this, pkg, if (blockReason != null) "blocking it" else "mindful pause")
        if (blockReason != null) {
            lastBlockPkg = pkg
            lastBlockAt = now
        }

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

        // A phone can create the screen and still leave it behind the app that
        // is open (this happens when an app is resumed from the background), or
        // refuse to open it at all. So after a moment, check that it is really
        // in front. If it is not, cover the app with an overlay, which works
        // on every brand. If even that is refused, send the person Home.
        handler.postDelayed({
            if (blockReason != null) {
                if (BlockActivity.onScreen || overlay.isShowing) return@postDelayed
                val shown = overlay.show(pkg, blockReason == BlockActivity.REASON_WIND_DOWN)
                if (shown) {
                    BlockStore.recordAttempt(
                        this, pkg, "block screen was not in front, showed an overlay instead"
                    )
                } else {
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
                        this, pkg, "block screen was not in front, sent Home instead"
                    )
                }
            } else {
                if (PauseActivity.onScreen || pauseOverlay.isShowing) return@postDelayed
                val shown = pauseOverlay.show(pkg)
                BlockStore.recordAttempt(
                    this, pkg,
                    if (shown) {
                        "pause screen was not in front, showed an overlay instead"
                    } else {
                        "pause screen was not in front and no overlay could be shown"
                    }
                )
            }
        }, 600L)
    }

    override fun onInterrupt() {}
}
