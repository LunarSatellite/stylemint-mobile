import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Resolves a STABLE per-device identifier that survives an uninstall+reinstall
/// as far as each OS allows, plus the platform metadata the backend stores on
/// the Device row.
///
/// - **Android**: `Settings.Secure.ANDROID_ID` — persists across reinstall,
///   resets only on factory reset.
/// - **iOS / fallback**: a UUID persisted in the Keychain via
///   [FlutterSecureStorage]. iOS Keychain items survive app deletion, so the
///   same install gets the same id back after reinstall. (Apple gives no
///   cross-reinstall hardware id; this is the sanctioned approach.)
///
/// MAC address, IMEI and hardware serials are intentionally NOT used — modern
/// iOS/Android mask them and stores reject apps that request them.
///
/// The fingerprint key is stored under its own namespace and is deliberately
/// NOT cleared on logout (see [TokenStorage.clear]) so device identity outlives
/// a session.
class DeviceIdentity {
  DeviceIdentity(this._storage);

  final FlutterSecureStorage _storage;
  static const _kFingerprint = 'device.fingerprint';
  static const _androidId = AndroidId();

  String? _cached;

  /// Stable device fingerprint (≤128 chars — backend Guard limit).
  Future<String> fingerprint() async {
    if (_cached != null) return _cached!;

    if (Platform.isAndroid) {
      final id = await _androidId.getId();
      if (id != null && id.isNotEmpty) return _cached = id;
    }

    // iOS + anything else: persisted Keychain UUID.
    final existing = await _storage.read(key: _kFingerprint);
    if (existing != null && existing.isNotEmpty) return _cached = existing;

    final fresh = const Uuid().v4();
    await _storage.write(key: _kFingerprint, value: fresh);
    return _cached = fresh;
  }

  /// Backend `DevicePlatform` enum integer value
  /// (Unknown=0, Ios=1, Android=2, Web=3, MacOs=4, Windows=5, Linux=6).
  int get platformCode {
    if (Platform.isAndroid) return 2;
    if (Platform.isIOS) return 1;
    if (Platform.isMacOS) return 4;
    if (Platform.isWindows) return 5;
    if (Platform.isLinux) return 6;
    return 0;
  }

  /// Human-readable OS version string for the Device row (best-effort).
  String get osVersion => Platform.operatingSystemVersion;
}

final deviceIdentityProvider = Provider<DeviceIdentity>((ref) {
  return DeviceIdentity(const FlutterSecureStorage());
});
