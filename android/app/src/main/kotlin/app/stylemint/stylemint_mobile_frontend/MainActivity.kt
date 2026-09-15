package app.stylemint.stylemint_mobile_frontend

import android.content.ActivityNotFoundException
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Reel share sheet: hand a StyleMint link to one app's own share
        // screen (e.g. the Facebook app), which web share links can't open.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> result.success(
                        shareText(call.argument("package"), call.argument("text")),
                    )
                    else -> result.notImplemented()
                }
            }
    }

    /** Opens [pkg]'s share screen with [text]; false when that app isn't installed. */
    private fun shareText(pkg: String?, text: String?): Boolean {
        if (pkg.isNullOrBlank() || text.isNullOrBlank()) return false
        val intent = Intent(Intent.ACTION_SEND)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_TEXT, text)
            .setPackage(pkg)
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private companion object {
        const val SHARE_CHANNEL = "app.stylemint/share"
    }
}
