import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles OS-level push notification permission and FCM token retrieval.
/// Call [requestPermission] when the user enables the toggle.
/// Call [getToken] to get the FCM token for backend registration.
class PushNotificationService {
  PushNotificationService._();

  static final _fcm = FirebaseMessaging.instance;

  /// Requests OS permission. Returns true if granted (or already granted).
  static Future<bool> requestPermission() async {
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
  static Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }
}
