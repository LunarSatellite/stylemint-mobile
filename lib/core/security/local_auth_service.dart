import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper over [LocalAuthentication] for device unlock (biometric or
/// device PIN/pattern fallback). Used to gate entry for an already-persisted
/// session — "open app → biometric → in".
class LocalAuthService {
  LocalAuthService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the device can perform a local authentication at all (biometrics
  /// enrolled OR a device credential set). If false, callers should not block
  /// entry on it.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canBiometrics = await _auth.canCheckBiometrics;
      // isDeviceSupported() implies a device credential exists, which is a
      // valid fallback even without enrolled biometrics.
      return supported || canBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user. Returns true only on a successful unlock. Allows the
  /// device PIN/pattern as a fallback (biometricOnly: false).
  Future<bool> authenticate({
    String reason = 'Unlock Style Mint',
  }) async {
    try {
      // local_auth 3.x: options are passed as named flags (no
      // AuthenticationOptions). biometricOnly:false allows device PIN/pattern
      // fallback; persistAcrossBackgrounding keeps the prompt sticky.
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final localAuthServiceProvider =
    Provider<LocalAuthService>((ref) => LocalAuthService());
