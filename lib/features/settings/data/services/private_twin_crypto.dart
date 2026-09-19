import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Password-based, authenticated encryption for portable commerce-twin files.
/// Plaintext and derived keys never leave this process. The password is never
/// stored; customers can restore the file on another device with the same one.
class PrivateTwinCrypto {
  PrivateTwinCrypto({AesGcm? cipher, Pbkdf2? keyDeriver})
    : _cipher = cipher ?? AesGcm.with256bits(),
      _keyDeriver =
          keyDeriver ??
          Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: 210000,
            bits: 256,
          );

  static const schema = 'stylemint.private-commerce-twin.encrypted';
  static const version = 1;

  final AesGcm _cipher;
  final Pbkdf2 _keyDeriver;

  Future<Uint8List> encrypt(String plaintext, String password) async {
    _validatePassword(password);
    final salt = SecretKeyData.random(length: 16).bytes;
    final nonce = _cipher.newNonce();
    final key = await _keyDeriver.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final box = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
      aad: utf8.encode('$schema:$version'),
    );
    final envelope = <String, Object>{
      'schema': schema,
      'version': version,
      'kdf': 'PBKDF2-HMAC-SHA256/210000',
      'cipher': 'AES-256-GCM',
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<String> decrypt(Uint8List encrypted, String password) async {
    _validatePassword(password);
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(encrypted));
    } on Object {
      throw const FormatException('This is not a StyleMint private twin file.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['schema'] != schema ||
        decoded['version'] != version) {
      throw const FormatException('This private twin format is not supported.');
    }
    try {
      final salt = base64Decode(decoded['salt'] as String);
      final key = await _keyDeriver.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );
      final clear = await _cipher.decrypt(
        SecretBox(
          base64Decode(decoded['ciphertext'] as String),
          nonce: base64Decode(decoded['nonce'] as String),
          mac: Mac(base64Decode(decoded['mac'] as String)),
        ),
        secretKey: key,
        aad: utf8.encode('$schema:$version'),
      );
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw const FormatException('Wrong password or the backup was changed.');
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('The private twin file is damaged.');
    }
  }

  static void _validatePassword(String password) {
    if (password.length < 10) {
      throw const FormatException(
        'Use a password with at least 10 characters.',
      );
    }
  }
}
