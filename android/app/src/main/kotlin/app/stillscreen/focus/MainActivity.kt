package app.stillscreen.focus

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    // Listing apps is slow (each app name is a resource lookup), so it runs off
    // the main thread and names are remembered between calls.
    private val appLoader = Executors.newSingleThreadExecutor()
    private val labelCache = ConcurrentHashMap<String, String>()
    private var pendingNotificationResult: MethodChannel.Result? = null

    override fun onDestroy() {
        appLoader.shutdown()
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_NOTIFICATIONS) {
            pendingNotificationResult?.success(
                grantResults.firstOrNull() == android.content.pm.PackageManager.PERMISSION_GRANTED
            )
            pendingNotificationResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())

                    "openAccessibilitySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }

                    "getInstalledApps" -> appLoader.execute {
                        val apps = try {
                            launchableApps()
                        } catch (e: Exception) {
                            null
                        }
                        runOnUiThread {
                            if (apps != null) {
                                result.success(apps)
                            } else {
                                result.error("apps_failed", "Could not list apps", null)
                            }
                        }
                    }

                    "setBlockedApps" -> {
                        val packages = (call.arguments as? List<*>)
                            ?.filterIsInstance<String>()
                            ?.toSet()
                            ?: emptySet()
                        BlockStore.setBlocked(this, packages)
                        result.success(null)
                    }

                    "startSession" -> {
                        val durationMs = (call.arguments as Number).toLong()
                        BlockStore.startSession(this, durationMs)
                        result.success(null)
                    }

                    "setWindDown" -> {
                        val args = call.arguments as Map<*, *>
                        BlockStore.setWindDown(
                            this,
                            enabled = args["enabled"] as? Boolean ?: false,
                            days = (args["days"] as? List<*>)
                                ?.filterIsInstance<Int>()?.toSet() ?: emptySet(),
                            startMinute = (args["startMinute"] as? Number)?.toInt() ?: 0,
                            endMinute = (args["endMinute"] as? Number)?.toInt() ?: 0,
                            packages = (args["packages"] as? List<*>)
                                ?.filterIsInstance<String>()?.toSet() ?: emptySet()
                        )
                        result.success(null)
                    }

                    "getManufacturer" -> result.success(Build.MANUFACTURER ?: "")

                    "isBatteryOptimizationIgnored" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }

                    "openBatterySettings" -> {
                        // Opens the system list, so no special permission is needed.
                        val opened = tryStart(
                            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        )
                        if (!opened) openAppInfo()
                        result.success(null)
                    }

                    "openAutostartSettings" -> result.success(openAutostart())

                    "openAppInfo" -> {
                        openAppInfo()
                        result.success(null)
                    }

                    "requestNotificationPermission" -> {
                        val granted = Build.VERSION.SDK_INT < 33 ||
                            androidx.core.content.ContextCompat.checkSelfPermission(
                                this, NOTIFICATION_PERMISSION
                            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            result.success(true)
                        } else {
                            pendingNotificationResult?.success(false)
                            pendingNotificationResult = result
                            androidx.core.app.ActivityCompat.requestPermissions(
                                this, arrayOf(NOTIFICATION_PERMISSION), REQUEST_NOTIFICATIONS
                            )
                        }
                    }

                    "notificationsAllowed" -> result.success(
                        androidx.core.app.NotificationManagerCompat.from(this)
                            .areNotificationsEnabled()
                    )

                    "configureReminder" -> {
                        val args = call.arguments as Map<*, *>
                        Reminder.configure(
                            this,
                            enabled = args["enabled"] as? Boolean ?: false,
                            minuteOfDay = (args["minuteOfDay"] as? Number)?.toInt() ?: 18 * 60,
                            title = args["title"] as? String ?: "Time to focus",
                            body = args["body"] as? String
                                ?: "A short session keeps your streak going."
                        )
                        result.success(null)
                    }

                    "markGoalReached" -> {
                        Reminder.markGoalReached(this, call.arguments as? String ?: "")
                        result.success(null)
                    }

                    "setMindfulPause" -> {
                        val args = call.arguments as Map<*, *>
                        PauseStore.configure(
                            this,
                            enabled = args["enabled"] as? Boolean ?: false,
                            seconds = (args["seconds"] as? Number)?.toInt() ?: 10,
                            graceMinutes = (args["graceMinutes"] as? Number)?.toInt() ?: 5,
                            packages = (args["packages"] as? List<*>)
                                ?.filterIsInstance<String>()?.toSet() ?: emptySet()
                        )
                        result.success(null)
                    }

                    "getPauseSummary" -> result.success(PauseStore.summary(this))

                    "shareImage" -> {
                        val args = call.arguments as Map<*, *>
                        val bytes = args["bytes"] as? ByteArray
                        val text = args["text"] as? String ?: ""
                        if (bytes == null) {
                            result.error("no_image", "No image data", null)
                        } else {
                            try {
                                shareImage(bytes, text)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("share_failed", e.message, null)
                            }
                        }
                    }

                    "stopSession" -> {
                        BlockStore.stopSession(this)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun isAccessibilityEnabled(): Boolean {
        val ours = ComponentName(this, BlockerAccessibilityService::class.java)
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == ours }
    }

    private fun launchableApps(): List<Map<String, Any>> {
        val pm = packageManager
        val protectedApps = BlockStore.protectedPackages(this)
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(launcher, 0)
            .filter { it.activityInfo.packageName !in protectedApps }
            .distinctBy { it.activityInfo.packageName }
            .map { info ->
                val pkg = info.activityInfo.packageName
                val label = labelCache.getOrPut(pkg) { info.loadLabel(pm).toString() }
                val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    info.activityInfo.applicationInfo.category
                } else {
                    -1
                }
                mapOf("package" to pkg, "label" to label, "category" to category)
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    /** Saves the image to our cache and opens Android's share sheet. */
    private fun shareImage(bytes: ByteArray, text: String) {
        val dir = java.io.File(cacheDir, "share").apply { mkdirs() }
        val file = java.io.File(dir, "stillscreen-streak.png")
        file.writeBytes(bytes)
        val uri = androidx.core.content.FileProvider.getUriForFile(
            this, "$packageName.fileprovider", file
        )
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            if (text.isNotEmpty()) putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(send, "Share your streak"))
    }

    private fun tryStart(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        false
    }

    private fun openAppInfo(): Boolean = tryStart(
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
    )

    /**
     * Best effort: these manufacturer screens are not part of Android and can
     * change between phone models and software versions. Returns false when
     * none opened, and the Flutter side falls back to app info.
     */
    private fun openAutostart(): Boolean {
        val candidates = listOf(
            "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
            "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            "com.oppo.safe" to "com.oppo.safe.permission.startup.StartupAppListActivity",
            "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
            "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
        )
        return candidates.any { (pkg, cls) ->
            tryStart(Intent().setComponent(ComponentName(pkg, cls)))
        }
    }

    companion object {
        const val CHANNEL = "app.stillscreen.focus/blocking"
        const val NOTIFICATION_PERMISSION = "android.permission.POST_NOTIFICATIONS"
        const val REQUEST_NOTIFICATIONS = 7001
    }
}
