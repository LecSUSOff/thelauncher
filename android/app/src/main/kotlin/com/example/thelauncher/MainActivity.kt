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
    private val HOME_CHANNEL = "launcher/home_intent" // 1. New channel name
    private var homeMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 2. Set up the home channel
        homeMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HOME_CHANNEL)

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

    // 3. Catch the Home Button / Swipe-Up gesture!
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_HOME)) {
            // Tell Flutter the home button was pressed!
            homeMethodChannel?.invokeMethod("onHomePressed", null)
        }
    }
}