package com.example.thelauncher

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.MediaStore
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "launcher/defaults"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
    }
}