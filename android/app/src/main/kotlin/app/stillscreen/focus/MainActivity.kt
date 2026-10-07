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

    override fun onDestroy() {
        appLoader.shutdown()
        super.onDestroy()
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
    }
}
