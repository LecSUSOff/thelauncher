package org.candyos.launcher

import android.app.Notification
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.MethodChannel

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
        val top = activeOngoing.values.firstOrNull()

        Handler(Looper.getMainLooper()).post {
            if (top == null) {
                channel?.invokeMethod("onNotificationUpdated", null)
                return@post
            }

            val extras = top.notification.extras
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() 
                ?: extras.getCharSequence(Notification.EXTRA_TITLE_BIG)?.toString() 
                ?: top.packageName

            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() 
                ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() 
                ?: ""

            val actionTitles = top.notification.actions?.map { it.title.toString() } ?: emptyList()

            val payload = mapOf(
                "key" to top.key,
                "packageName" to top.packageName,
                "title" to title,
                "content" to text,
                "actions" to actionTitles
            )

            channel?.invokeMethod("onNotificationUpdated", payload)
        }
    }

    fun triggerAction(key: String, actionIndex: Int) {
        val sbn = activeOngoing[key] ?: return
        val actions = sbn.notification.actions ?: return
        if (actionIndex in actions.indices) {
            try {
                actions[actionIndex].actionIntent.send()
            } catch (_: Exception) {}
        }
    }

    fun openNotification(key: String) {
        val sbn = activeOngoing[key] ?: return
        try {
            sbn.notification.contentIntent?.send()
        } catch (_: Exception) {}
    }
}