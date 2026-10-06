import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// OS permission and FCM token handling, safe to call on a build where
/// Firebase is not configured.
///
/// That case is the normal one right now and has to stay harmless: the app
/// depends on `firebase_core` and `firebase_messaging`, but
/// `Firebase.initializeApp` was never called and neither
/// `android/app/google-services.json` nor
/// `ios/Runner/GoogleService-Info.plist` was ever added. Touching
/// `FirebaseMessaging.instance` without initialisation throws
/// "No Firebase App '[DEFAULT]' has been created", so this keeps every entry
/// point behind [isAvailable] rather than behind a `try` that swallows the
/// reason.
///
/// Platform config arriving for one platform and not the other is also
/// normal — iOS first, say — so initialisation failing is not an error worth
/// interrupting startup for. It is reported once to the debug console and the
/// app runs without push.
class PushNotificationService {
  PushNotificationService._();

  static bool _available = false;

  /// Whether Firebase initialised. False means no platform config was bundled
  /// for this platform, and every method below is a no-op.
  static bool get isAvailable => _available;

  /// Called once from `main`, before `runApp`.
  ///
  /// Deliberately does not rethrow. A missing `google-services.json` on
  /// Android would otherwise crash the app at launch for everyone, to deliver
  /// a feature nobody has configured yet.
  static Future<void> initialise() async {
    if (_available) return;
    try {
      // No explicit options: the native config files are the source of truth,
      // so a `flutterfire configure` run that produces firebase_options.dart
      // is not required for this to work.
      await Firebase.initializeApp();
      _available = true;
    } catch (error) {
      _available = false;
      if (kDebugMode) {
        debugPrint(
          'Push disabled: Firebase did not initialise ($error). Add the '
          'platform config file for this platform to enable it.',
        );
      }
    }
  }

  static FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  /// Requests OS permission. Returns true if granted (or already granted).
  static Future<bool> requestPermission() async {
    if (!_available) return false;
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Returns the FCM token, or null if unavailable.
  ///
  /// On iOS this answers null until APNs has handed Firebase a token, which
  /// is why callers must treat null as "not yet" and rely on [onTokenRefresh]
  /// rather than reading once at sign-in and giving up.
  static Future<String?> getToken() async {
    if (!_available) return null;
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Fires whenever FCM rotates the token.
  ///
  /// Registration has to follow this, not just sign-in: a rotated token
  /// leaves the server pushing to an address the device no longer answers on,
  /// and the failure is silent at both ends.
  static Stream<String> get onTokenRefresh =>
      _available ? _fcm.onTokenRefresh : const Stream<String>.empty();

  /// The server's `DevicePlatform` value for this device.
  ///
  /// Decides which transport the backend uses — FCM for Android, APNs for
  /// iOS — so it is read from the running platform rather than assumed.
  static int? get platformWireValue {
    if (Platform.isAndroid) return 1;
    if (Platform.isIOS) return 2;
    return null;
  }
}
