package com.example.thelauncher

import android.app.Notification
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.provider.Telephony
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
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
                    "sms" to Telephony.Sms.getDefaultSmsPackage(context),
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
                        CandyNotificationListener.instance?.triggerAction(key, index)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Key or index missing", null)
                    }
                }
                "open" -> {
                    val key = call.argument<String>("key")
                    if (key != null) {
                        CandyNotificationListener.instance?.openNotification(key)
                        result.success(true)
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

class CandyNotificationListener : NotificationListenerService() {

    companion object {
        var instance: CandyNotificationListener? = null
        var channel: MethodChannel? = null
        val activeOngoing = mutableMapOf<String, StatusBarNotification>()
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        syncNotifications()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (instance == this) instance = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val n = sbn.notification
        val isOngoing = sbn.isOngoing
        val hasActions = !n.actions.isNullOrEmpty()

        // Filter: ONLY track ongoing tasks or actionable notifications (Google Maps, Timers, Calls, Uber)
        // Skip audio media notifications (Lex's MediaService handles playback)
        if ((!isOngoing && !hasActions) || n.extras.containsKey(Notification.EXTRA_MEDIA_SESSION)) {
            return
        }

        activeOngoing[sbn.key] = sbn
        pushTopNotificationToFlutter()
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        if (activeOngoing.containsKey(sbn.key)) {
            activeOngoing.remove(sbn.key)
            pushTopNotificationToFlutter()
        }
    }

    fun syncNotifications() {
        activeOngoing.clear()
        try {
            activeNotifications?.forEach { sbn ->
                val n = sbn.notification
                val isOngoing = sbn.isOngoing
                val hasActions = !n.actions.isNullOrEmpty()
                if ((isOngoing || hasActions) && !n.extras.containsKey(Notification.EXTRA_MEDIA_SESSION)) {
                    activeOngoing[sbn.key] = sbn
                }
            }
        } catch (_: Exception) {}
        pushTopNotificationToFlutter()
    }

    private fun pushTopNotificationToFlutter() {
        // Prefer a genuinely ongoing notification when other actionable notifications are present.
        val top = activeOngoing.values.firstOrNull { it.isOngoing }
            ?: activeOngoing.values.firstOrNull()

        Handler(Looper.getMainLooper()).post {
            if (top == null) {
                channel?.invokeMethod("onNotificationUpdated", null)
                return@post
            }

            channel?.invokeMethod("onNotificationUpdated", buildNotificationPayload(top))
        }
    }

    private fun buildNotificationPayload(sbn: StatusBarNotification): Map<String, Any?> {
        val notification = sbn.notification
        val extras = notification.extras

        val title = textExtra(extras, Notification.EXTRA_TITLE)
            ?: textExtra(extras, Notification.EXTRA_TITLE_BIG)
            ?: sbn.packageName

        val bigTitle = textExtra(extras, Notification.EXTRA_TITLE_BIG) ?: ""

        val content = textExtra(extras, Notification.EXTRA_TEXT)
            ?: textExtra(extras, Notification.EXTRA_BIG_TEXT)
            ?: ""

        val bigText = textExtra(extras, Notification.EXTRA_BIG_TEXT) ?: ""
        val subText = textExtra(extras, Notification.EXTRA_SUB_TEXT) ?: ""
        val infoText = textExtra(extras, Notification.EXTRA_INFO_TEXT) ?: ""
        val summaryText = textExtra(extras, Notification.EXTRA_SUMMARY_TEXT) ?: ""
        val tickerText = notification.tickerText?.toString()?.takeIf { it.isNotBlank() } ?: ""

        val conversationTitle =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                textExtra(extras, Notification.EXTRA_CONVERSATION_TITLE) ?: ""
            } else {
                ""
            }

        val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            ?.mapNotNull { line -> line?.toString()?.takeIf { it.isNotBlank() } }
            ?: emptyList()

        val messages = readMessages(extras)

        val progressMax = extras.getInt(Notification.EXTRA_PROGRESS_MAX, 0)
        val progressValue = extras.getInt(Notification.EXTRA_PROGRESS, 0)
        val progressIndeterminate =
            extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE, false) ||
                (extras.containsKey(Notification.EXTRA_PROGRESS_MAX) && progressMax <= 0)
        val hasProgress =
            progressIndeterminate || (progressMax > 0 && progressValue >= 0)

        val usesChronometer = extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER, false)
        val chronometerCountDown =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                extras.getBoolean(Notification.EXTRA_CHRONOMETER_COUNT_DOWN, false)
            } else {
                false
            }

        val actionTitles = notification.actions
            ?.map { action -> action.title?.toString()?.takeIf { it.isNotBlank() } ?: "" }
            ?: emptyList()

        return mapOf(
            "key" to sbn.key,
            "packageName" to sbn.packageName,
            "title" to title,
            "bigTitle" to bigTitle,
            "content" to content,
            "bigText" to bigText,
            "subText" to subText,
            "infoText" to infoText,
            "summaryText" to summaryText,
            "conversationTitle" to conversationTitle,
            "tickerText" to tickerText,
            "textLines" to textLines,
            "messages" to messages,
            "actions" to actionTitles,
            "progress" to if (hasProgress) progressValue else null,
            "maxProgress" to if (hasProgress) progressMax else null,
            "progressIndeterminate" to progressIndeterminate,
            "usesChronometer" to usesChronometer,
            "chronometerCountDown" to chronometerCountDown,
            "when" to notification.`when`,
            "isOngoing" to sbn.isOngoing,
            "iconBytes" to loadIconBytes(sbn)
        )
    }

    private fun textExtra(extras: Bundle, key: String): String? =
        extras.getCharSequence(key)?.toString()?.takeIf { it.isNotBlank() }

    @Suppress("DEPRECATION")
    private fun readMessages(extras: Bundle): List<Map<String, Any?>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return emptyList()

        val rawMessages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            ?: return emptyList()

        return rawMessages.mapNotNull { item ->
            val bundle = item as? Bundle ?: return@mapNotNull null
            val text = bundle.getCharSequence("text")?.toString()?.takeIf { it.isNotBlank() }
                ?: return@mapNotNull null
            val sender = bundle.getCharSequence("sender")?.toString()?.takeIf { it.isNotBlank() }

            mapOf(
                "sender" to (sender ?: ""),
                "text" to text,
                "time" to bundle.getLong("time", 0L)
            )
        }
    }

    private fun loadIconBytes(sbn: StatusBarNotification): ByteArray? {
        val drawable = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                sbn.notification.getLargeIcon()?.loadDrawable(this)
            } else {
                null
            }
        } catch (_: Exception) {
            null
        } ?: try {
            packageManager.getApplicationIcon(sbn.packageName)
        } catch (_: Exception) {
            null
        }

        return try {
            drawable?.toIconBytes()
        } catch (_: Exception) {
            null
        }
    }

    private fun Drawable.toIconBytes(): ByteArray? {
        val source = if (this is BitmapDrawable && bitmap != null) {
            bitmap
        } else {
            val width = intrinsicWidth.takeIf { it > 0 } ?: 96
            val height = intrinsicHeight.takeIf { it > 0 } ?: 96
            Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also {
                val canvas = Canvas(it)
                setBounds(0, 0, canvas.width, canvas.height)
                draw(canvas)
            }
        }

        val maxSize = 128
        val icon = if (source.width > maxSize || source.height > maxSize) {
            Bitmap.createScaledBitmap(source, maxSize, maxSize, true)
        } else {
            source
        }

        return ByteArrayOutputStream().use { stream ->
            icon.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        }
    }

    fun triggerAction(key: String, actionIndex: Int) {
        val sbn = activeOngoing[key] ?: return
        val action = sbn.notification.actions?.getOrNull(actionIndex) ?: return
        try {
            action.actionIntent?.send()
        } catch (_: Exception) {}
    }

    fun openNotification(key: String) {
        val sbn = activeOngoing[key] ?: return
        try {
            sbn.notification.contentIntent?.send()
        } catch (_: Exception) {}
    }
}
