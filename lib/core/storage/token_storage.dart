import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists auth tokens + session identity in the platform secure enclave
/// (Keychain on iOS, EncryptedSharedPreferences on Android).
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'auth.accessToken';
  static const _kRefreshToken = 'auth.refreshToken';
  static const _kAccessExpiry = 'auth.accessExpiresUtc';
  static const _kRefreshExpiry = 'auth.refreshExpiresUtc';
  static const _kAccountId = 'auth.accountId';
  static const _kSessionId = 'auth.sessionId';

  Future<void> saveSession({
    required String? accessToken,
    required String? refreshToken,
    required DateTime accessExpiresUtc,
    required DateTime refreshExpiresUtc,
    required String accountId,
    required String sessionId,
  }) async {
    await Future.wait([
      _write(_kAccessToken, accessToken),
      _write(_kRefreshToken, refreshToken),
      _write(_kAccessExpiry, accessExpiresUtc.toIso8601String()),
      _write(_kRefreshExpiry, refreshExpiresUtc.toIso8601String()),
      _write(_kAccountId, accountId),
      _write(_kSessionId, sessionId),
    ]);
  }

  /// Reads never throw — a secure-storage failure (e.g. Android keystore
  /// decryption error after a rebuild) returns null so callers treat it as
  /// "no session" instead of crashing / freezing on splash.
  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<String?> get accessToken => _safeRead(_kAccessToken);
  Future<String?> get refreshToken => _safeRead(_kRefreshToken);
  Future<String?> get accountId => _safeRead(_kAccountId);
  Future<String?> get sessionId => _safeRead(_kSessionId);

  Future<DateTime?> get refreshExpiresUtc async {
    final raw = await _safeRead(_kRefreshExpiry);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// True when a refresh token exists and has not yet expired.
  Future<bool> get hasValidRefreshToken async {
    final token = await refreshToken;
    if (token == null || token.isEmpty) return false;
    final expiry = await refreshExpiresUtc;
    if (expiry == null) return true;
    return expiry.isAfter(DateTime.now().toUtc());
  }

  /// Clears the session — but deliberately preserves the device identity
  /// (`device.*`) so the same device is recognised after logout. We delete the
  /// known auth keys rather than `deleteAll()` for that reason.
  Future<void> clear() => Future.wait([
        _storage.delete(key: _kAccessToken),
        _storage.delete(key: _kRefreshToken),
        _storage.delete(key: _kAccessExpiry),
        _storage.delete(key: _kRefreshExpiry),
        _storage.delete(key: _kAccountId),
        _storage.delete(key: _kSessionId),
      ]);

  Future<void> _write(String key, String? value) =>
      value == null ? _storage.delete(key: key) : _storage.write(key: key, value: value);
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  // resetOnError: a corrupt/undecryptable Android keystore entry is wiped and
  // treated as empty instead of throwing on every read (which would otherwise
  // freeze the app on splash). EncryptedSharedPreferences is the modern store.
  return TokenStorage(const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
      encryptedSharedPreferences: true,
    ),
  ));
});
