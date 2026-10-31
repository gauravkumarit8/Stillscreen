package app.stillscreen.focus

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
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

    /** The last app that was not Stillscreen itself. */
    private var lastForeign: String? = null
    private var lastBlockAt = 0L

    companion object {
        /**
         * True only while Android has this service connected and running. The
         * "enabled" switch in Accessibility settings can stay on after the
         * phone has stopped the service in the background, so the app checks
         * this as well.
         */
        /** The service instance Android has connected, or null if none. */
        @Volatile
        private var instance: BlockerAccessibilityService? = null

        val connected: Boolean get() = instance != null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        BlockStore.touchActive(this)
        Alerts.clearBlockingOff(this)
    }

    /** Blocking was switched off. Warn only if it matters right now. */
    override fun onUnbind(intent: Intent?): Boolean {
        if (instance === this) instance = null
        overlay.hide()
        pauseOverlay.hide()
        if (BlockStore.isSessionActive(this) || BlockStore.isWindDownActive(this)) {
            Alerts.showBlockingOff(this)
        }
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        if (instance === this) instance = null
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

        // How long ago the app says this happened. A big number means the phone
        // held the event back, for example while it had frozen Stillscreen to
        // save battery. It is written into the activity log.
        val lateMs = SystemClock.uptimeMillis() - event.eventTime
        val late = if (lateMs > 500L) " (event ${lateMs} ms late)" else ""

        if (now - lastBeat > 10_000L) {
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
        lastForeign = pkg
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
            // A repeat is normally ignored. But a blocked app that shows up
            // again while no block screen is in front has come back on top of
            // it (this happens when an app is resumed from the background), so
            // it has to be blocked again. Only skip it if a block screen is up,
            // or one was launched a split second ago.
            val blockUiUp = BlockActivity.onScreen || overlay.isShowing
            val justLaunched = pkg == lastBlockPkg && now - lastBlockAt < 400L
            if (blockReason == null || blockUiUp || justLaunched) {
                if (somethingActive) BlockStore.logEvent(this, pkg, "same app again, ignored$late")
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
                BlockStore.logEvent(this, pkg, "$why$late")
            }
            return
        }
        if (pkg in BlockStore.protectedPackages(this)) {
            BlockStore.logEvent(this, pkg, "protected app, never blocked$late")
            return
        }
        BlockStore.logEvent(
            this, pkg,
            when {
                blockReason == null -> "mindful pause$late"
                repeat -> "blocking it again$late"
                else -> "blocking it$late"
            }
        )
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
        // is open, or let the app climb back on top a moment later (this
        // happens when an app is resumed from the background), or refuse to
        // open it at all. So check a few times that it is really in front, and
        // cover the app with an overlay if it is not.
        for (delay in longArrayOf(600L, 1500L, 3000L)) {
            handler.postDelayed({ ensureScreenShown(pkg, blockReason) }, delay)
        }
    }

    /**
     * Makes sure a block (or pause) screen is in front of [pkg]. Does nothing
     * if one already is, if the session is over, or if the person has moved on.
     */
    private fun ensureScreenShown(pkg: String, blockReason: String?) {
        if (lastForeign != pkg) return
        if (blockReason != null) {
            if (BlockActivity.onScreen || overlay.isShowing) return
            if (!BlockStore.isSessionActive(this) && !BlockStore.isWindDownActive(this)) return
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
            if (PauseActivity.onScreen || pauseOverlay.isShowing) return
            // After "Continue" the pause screen closes on purpose.
            if (PauseStore.isInGrace(this, pkg)) return
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
    }

    override fun onInterrupt() {}
}
