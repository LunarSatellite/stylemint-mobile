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

  Future<String?> get accessToken => _storage.read(key: _kAccessToken);
  Future<String?> get refreshToken => _storage.read(key: _kRefreshToken);
  Future<String?> get accountId => _storage.read(key: _kAccountId);
  Future<String?> get sessionId => _storage.read(key: _kSessionId);

  Future<DateTime?> get refreshExpiresUtc async {
    final raw = await _storage.read(key: _kRefreshExpiry);
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
  return TokenStorage(const FlutterSecureStorage());
});
