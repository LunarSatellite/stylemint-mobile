package app.stylemint.stylemint_mobile_frontend

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth so
// the biometric/device-credential prompt can attach to a FragmentActivity.
class MainActivity : FlutterFragmentActivity()
