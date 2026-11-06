package com.example.thelauncher

import android.app.ActivityOptions
import android.app.Notification
import android.app.PendingIntent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class CandyNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "CandyNotifications"

        var instance: CandyNotificationListener? = null
        var channel: MethodChannel? = null
    }

    private val trackedNotifications = LinkedHashMap<String, StatusBarNotification>()

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        syncNotifications()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (instance == this) {
            instance = null
            trackedNotifications.clear()
            pushNotificationsToFlutter()
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!isEligible(sbn)) {
            if (trackedNotifications.remove(sbn.key) != null) {
                pushNotificationsToFlutter()
            }
            return
        }

        trackedNotifications[sbn.key] = sbn
        pushNotificationsToFlutter()
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        if (trackedNotifications.remove(sbn.key) != null) {
            pushNotificationsToFlutter()
        }
    }

    fun syncNotifications() {
        trackedNotifications.clear()
        try {
            activeNotifications?.forEach { sbn ->
                if (isEligible(sbn)) {
                    trackedNotifications[sbn.key] = sbn
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not read active notifications", e)
        }
        pushNotificationsToFlutter()
    }

    private fun isEligible(sbn: StatusBarNotification): Boolean {
        val notification = sbn.notification
        val extras = notification.extras

        // Media controls are handled by the dedicated media service.
        if (extras.containsKey(Notification.EXTRA_MEDIA_SESSION)) return false

        val hasActions = notification.actions?.any { !it.title.isNullOrBlank() } == true
        val hasProgress = extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE, false) ||
            extras.getInt(Notification.EXTRA_PROGRESS_MAX, 0) > 0
        val hasChronometer = extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER, false)

        return sbn.isOngoing || hasActions || hasProgress || hasChronometer
    }

    /**
     * Rich, user-actionable ongoing notifications should win over passive system
     * notifications such as "Charging this device via USB".
     */
    private fun rank(sbn: StatusBarNotification): Int {
        val notification = sbn.notification
        val extras = notification.extras
        val category = notification.category ?: ""
        val hasActions = notification.actions?.any {
            !it.title.isNullOrBlank() && it.actionIntent != null
        } == true
        val hasProgress = extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE, false) ||
            extras.getInt(Notification.EXTRA_PROGRESS_MAX, 0) > 0
        val hasChronometer = extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER, false)
        val systemPackage = isSystemPackage(sbn.packageName)

        var score = 0
        if (hasProgress) score += 40
        if (hasChronometer) score += 35
        if (hasActions) score += 25
        if (notification.contentIntent != null) score += 10
        if (sbn.isOngoing) score += 5

        score += when (category) {
            "navigation", "transport", "call", "progress", "stopwatch", "workout",
            "alarm", "event", "reminder", "location" -> 30
            "msg", "email", "social" -> 12
            else -> 0
        }

        // Generic system notifications have no useful launcher interaction.
        if (systemPackage && !hasProgress && !hasChronometer) score -= 40

        return score
    }

    private fun isSystemPackage(packageName: String): Boolean =
        packageName == "android" ||
            packageName.startsWith("com.android.systemui") ||
            packageName.startsWith("com.android.settings")

    private fun pushNotificationsToFlutter() {
        val payloads = trackedNotifications.values
            .sortedWith(
                compareByDescending<StatusBarNotification> { rank(it) }
                    .thenByDescending { it.postTime }
            )
            .map { buildNotificationPayload(it) }

        Handler(Looper.getMainLooper()).post {
            try {
                channel?.invokeMethod("onNotificationsUpdated", payloads)
            } catch (e: Exception) {
                Log.w(TAG, "Could not push notifications to Flutter", e)
            }
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
            extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE, false)
        val hasProgress = progressIndeterminate || progressMax > 0

        val usesChronometer = extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER, false)
        val chronometerCountDown =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                extras.getBoolean(Notification.EXTRA_CHRONOMETER_COUNT_DOWN, false)
            } else {
                false
            }

        // Keep the original action index so Flutter can trigger the right action
        // even when icon-only actions are ignored.
        val actions = notification.actions
            ?.mapIndexedNotNull { index, action ->
                val actionTitle = action.title?.toString()?.trim()
                    ?.takeIf { it.isNotEmpty() }
                    ?: return@mapIndexedNotNull null
                mapOf(
                    "index" to index,
                    "title" to actionTitle
                )
            }
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
            "actions" to actions,
            "progress" to if (hasProgress) progressValue else null,
            "maxProgress" to if (hasProgress) progressMax else null,
            "progressIndeterminate" to progressIndeterminate,
            "usesChronometer" to usesChronometer,
            "chronometerCountDown" to chronometerCountDown,
            "when" to notification.`when`,
            "isOngoing" to sbn.isOngoing,
            "hasContentIntent" to (notification.contentIntent != null),
            "isSystemPackage" to isSystemPackage(sbn.packageName),
            "rank" to rank(sbn),
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

    fun triggerAction(key: String, actionIndex: Int): Boolean {
        val sbn = trackedNotifications[key] ?: return false
        val action = sbn.notification.actions?.getOrNull(actionIndex) ?: return false
        val intent = action.actionIntent ?: return openNotification(key)
        return sendPendingIntent(intent)
    }

    fun openNotification(key: String): Boolean {
        val sbn = trackedNotifications[key] ?: return false
        val intent = sbn.notification.contentIntent ?: return false
        return sendPendingIntent(intent)
    }

    /**
     * Android 14+ blocks activity PendingIntents sent by a background service
     * unless the sender explicitly opts in to a background activity start.
     * The launcher is visible when the user taps a notification, so grant that
     * visibility to the PendingIntent.
     */
    @Suppress("DEPRECATION")
    private fun sendPendingIntent(intent: PendingIntent): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val options = ActivityOptions.makeBasic().apply {
                    setPendingIntentBackgroundActivityStartMode(
                        if (Build.VERSION.SDK_INT >= 36) {
                            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOW_IF_VISIBLE
                        } else {
                            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                        }
                    )
                }
                intent.send(options.toBundle())
            } else {
                intent.send()
            }
            true
        } catch (e: Exception) {
            Log.w(TAG, "PendingIntent send failed", e)
            false
        }
    }
}
