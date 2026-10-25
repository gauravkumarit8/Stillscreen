package app.stillscreen.focus

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class BlockerAccessibilityService : AccessibilityService() {

    private var lastPackage: String? = null
    private var lastBeat = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        BlockStore.touchActive(this)
        Alerts.clearBlockingOff(this)
    }

    /** Blocking was switched off. Warn only if it matters right now. */
    override fun onUnbind(intent: Intent?): Boolean {
        if (BlockStore.isSessionActive(this) || BlockStore.isWindDownActive(this)) {
            Alerts.showBlockingOff(this)
        }
        return super.onUnbind(intent)
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
            return
        }

        // Ignore repeat events for the same app.
        if (pkg == lastPackage) return
        lastPackage = pkg

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
        startActivity(intent)
    }

    override fun onInterrupt() {}
}
