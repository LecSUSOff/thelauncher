package com.example.thelauncher

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.MediaStore
import android.provider.Settings
import android.provider.Telephony
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "launcher/defaults"
    private val HOME_CHANNEL = "launcher/home_intent"
    private val NOTI_CHANNEL = "launcher/notifications"
    private var homeMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        homeMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HOME_CHANNEL)

        homeMethodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "openNotifications") {
                try {
                    val statusBarService = getSystemService("statusbar")
                    val statusBarManager = Class.forName("android.app.StatusBarManager")
                    val expand = statusBarManager.getMethod("expandNotificationsPanel")
                    expand.invoke(statusBarService)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", "Could not expand notifications", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDefaults") {
                val pm = packageManager
                fun resolve(intent: Intent): String? =
                    pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)?.activityInfo?.packageName

                val defaults = mapOf(
                    "dialer" to resolve(Intent(Intent.ACTION_DIAL, Uri.parse("tel:"))),
                    "browser" to resolve(Intent(Intent.ACTION_VIEW, Uri.parse("https://google.com"))),
                    "sms" to Telephony.Sms.getDefaultSmsPackage(this),
                    "camera" to resolve(Intent(MediaStore.ACTION_IMAGE_CAPTURE))
                )
                result.success(defaults)
            } else {
                result.notImplemented()
            }
        }

        val notificationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTI_CHANNEL)
        CandyNotificationListener.channel = notificationChannel

        notificationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> {
                    val isGranted = NotificationManagerCompat.getEnabledListenerPackages(this)
                        .contains(packageName)
                    result.success(isGranted)
                }
                "requestPermission" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "sync" -> {
                    CandyNotificationListener.instance?.syncNotifications()
                    result.success(true)
                }
                "triggerAction" -> {
                    val key = call.argument<String>("key")
                    val index = call.argument<Int>("actionIndex")
                    if (key != null && index != null) {
                        val handled = CandyNotificationListener.instance
                            ?.triggerAction(key, index) ?: false
                        result.success(handled)
                    } else {
                        result.error("INVALID_ARGS", "Key or index missing", null)
                    }
                }
                "open" -> {
                    val key = call.argument<String>("key")
                    if (key != null) {
                        val handled = CandyNotificationListener.instance
                            ?.openNotification(key) ?: false
                        result.success(handled)
                    } else {
                        result.error("INVALID_ARGS", "Key missing", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_HOME)) {
            homeMethodChannel?.invokeMethod("onHomePressed", null)
        }
    }
}
