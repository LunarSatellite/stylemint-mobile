import 'dart:async';

import 'package:dio/dio.dart' show Options;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stylemint_mobile_frontend/core/device/push_notification_service.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:uuid/uuid.dart';

/// Sends this device's FCM token to the server, and keeps it current.
///
/// This is the link that was missing. `PushNotificationService.getToken()` was
/// already being called — from the push toggle in the profile screen — and the
/// result was thrown away, so `public.device_registrations` held zero rows and
/// there was nothing for the backend to push to. Every notification the
/// platform already routes to a courier (offers issued, and now onboarding)
/// had no address to go to.
///
/// `POST api/v1/devices` upserts on the token, so calling this more often than
/// strictly necessary is cheap and calling it too rarely is not: a token the
/// server does not know about, or one it knows about after rotation, both fail
/// silently at each end.
class DevicePushRegistration {
  DevicePushRegistration(this._apiClient);

  final ApiClient _apiClient;
  static const _uuid = Uuid();

  StreamSubscription<String>? _rotation;

  /// Registers the current token and starts following rotations.
  ///
  /// Safe to call on every sign-in. Does nothing when Firebase is not
  /// configured for this platform, which is the current state of the app.
  Future<void> start() async {
    if (!PushNotificationService.isAvailable) return;

    await _registerCurrent();

    // Rotation matters as much as the first registration: FCM replaces a
    // token on reinstall, restore from backup, and occasionally on its own.
    await _rotation?.cancel();
    _rotation = PushNotificationService.onTokenRefresh.listen(
      (token) => unawaited(_register(token)),
    );
  }

  /// Stops following rotations. Called on sign-out.
  ///
  /// The row is deliberately NOT deleted here. The server keys dispatches by
  /// account, and the next account to sign in on this phone registers the
  /// same token against themselves — which is the upsert's job. Deleting on
  /// the way out would instead race that sign-in.
  Future<void> stop() async {
    await _rotation?.cancel();
    _rotation = null;
  }

  Future<void> _registerCurrent() async {
    final token = await PushNotificationService.getToken();
    // Null is normal on iOS until APNs has answered, which is why the
    // rotation listener is the real path and this is only a head start.
    if (token == null || token.isEmpty) return;
    await _register(token);
  }

  Future<void> _register(String token) async {
    final platform = PushNotificationService.platformWireValue;
    if (platform == null) return;

    try {
      final info = await PackageInfo.fromPlatform();
      await _apiClient.post(
        '/api/v1/devices',
        data: <String, dynamic>{
          'platform': platform,
          'pushToken': token,
          'appVersion': '${info.version}+${info.buildNumber}',
        },
        options: Options(
          headers: {
            'requiresToken': true,
            // The endpoint is [Idempotent], so a retried registration
            // resolves to one row rather than two.
            'Idempotency-Key': _uuid.v4(),
          },
        ),
      );
    } catch (error) {
      // Best effort, and quiet by design. A failed registration costs the
      // user notifications, not the session they are in the middle of, and
      // the next sign-in or rotation tries again.
      if (kDebugMode) debugPrint('Push token registration failed: $error');
    }
  }
}

/// App-lifetime singleton: the push token belongs to the device, not to a
/// screen, and the rotation subscription must outlive whatever registered it.
final devicePushRegistrationProvider = Provider<DevicePushRegistration>(
  (ref) => DevicePushRegistration(ref.watch(apiClientProvider)),
);
