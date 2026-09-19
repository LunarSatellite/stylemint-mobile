package app.stylemint.stylemint_mobile_frontend

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /** The ACTION_SEND image that launched the app, until Dart asks for it. */
    private var pendingShare: ByteArray? = null

    /** Set once Dart is listening; warm shares go straight down it. */
    private var shareEvents: EventChannel.EventSink? = null

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

        // Screenshot search: an image shared *into* StyleMint from another
        // app. Two channels because a share can arrive either way round —
        // it can launch the app (cold, read once on request) or land on an
        // app that is already running (warm, pushed as an event).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INBOUND_SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeLaunchShare" -> {
                        // Taken, not read: a cold-start share must not
                        // re-open the same screenshot on every resume.
                        val bytes = pendingShare
                        pendingShare = null
                        result.success(bytes)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, INBOUND_SHARE_EVENTS)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        shareEvents = events
                    }

                    override fun onCancel(arguments: Any?) {
                        shareEvents = null
                    }
                },
            )

        // The intent that started this launch, before Dart could listen.
        captureShare(intent)
    }

    /** A share that arrives while StyleMint is already on screen. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureShare(intent)
        val sink = shareEvents ?: return
        val bytes = pendingShare ?: return
        pendingShare = null
        sink.success(bytes)
    }

    /**
     * Reads a shared image into memory.
     *
     * Deliberately not copied to a file. A screenshot can hold a private
     * chat or a bank balance, so the only place it exists inside StyleMint
     * is this byte array and the Dart object it becomes — both of which go
     * away on their own.
     */
    private fun captureShare(intent: Intent?) {
        if (intent == null || intent.action != Intent.ACTION_SEND) return
        if (intent.type?.startsWith("image/") != true) return
        val uri: Uri = intent.getParcelableExtra(Intent.EXTRA_STREAM) ?: return
        pendingShare = try {
            contentResolver.openInputStream(uri)?.use { stream ->
                // A share sheet can hand over anything; a picture bigger
                // than this is not a screenshot and is not worth holding
                // in memory on a low-end handset.
                val bytes = stream.readBytes()
                if (bytes.size > MAX_SHARE_BYTES) null else bytes
            }
        } catch (e: SecurityException) {
            // The grant expired before we could read it.
            null
        } catch (e: java.io.IOException) {
            null
        }
        // The URI is not retained: the read grant is scoped to this intent
        // and StyleMint has no reason to reach back into the other app.
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
        const val INBOUND_SHARE_CHANNEL = "app.stylemint/inbound_share"
        const val INBOUND_SHARE_EVENTS = "app.stylemint/inbound_share/events"
        const val MAX_SHARE_BYTES = 25 * 1024 * 1024
    }
}
