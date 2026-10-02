import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The courier's signing key: generated on this device, never leaves it.
///
/// Custody events are signed with ECDSA over P-256 / SHA-256 and the backend
/// verifies them against the public key registered via
/// `POST /v1/courier/{id}/device-keys`. What gets signed is the canonical
/// attestation string the server rebuilds from its own stored columns — see
/// the published algorithm at `GET /v1/deliveries/custody-proof/rules`, step 6.
///
/// The private key lives in [FlutterSecureStorage] (Keychain on iOS, the
/// EncryptedSharedPreferences-backed store on Android) and is never sent
/// anywhere. Losing it is not a disaster: the courier revokes that key id and
/// registers a new one. Entries already signed stay verifiable, because the
/// public key is retained alongside them.
class CourierDeviceKey {
  CourierDeviceKey({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyIdSlot = 'courier.device_key.id';
  static String _privateSlot(String keyId) => 'courier.device_key.priv.$keyId';

  static final _algorithm = Ecdsa.p256(Sha256());

  /// SubjectPublicKeyInfo prefix for an uncompressed prime256v1 point.
  ///
  /// SPKI is a fixed ASN.1 wrapper — SEQUENCE { SEQUENCE { OID ecPublicKey,
  /// OID prime256v1 }, BIT STRING } — followed by 0x04 and the 64 bytes of
  /// X then Y. package:cryptography exposes the curve point as x and y rather
  /// than an encoded key, so the wrapper is assembled here rather than parsed
  /// out of something. These bytes are a constant of the curve, not a choice.
  static const _p256SpkiPrefix = <int>[
    0x30, 0x59, // SEQUENCE, 89 bytes follow
    0x30, 0x13, // SEQUENCE, 19 bytes follow
    0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, // OID 1.2.840.10045.2.1
    0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, // OID prime256v1
    0x03, 0x42, 0x00, // BIT STRING, 66 bytes, 0 unused bits
    0x04, // uncompressed point
  ];

  /// The key id this device currently signs with, or null if it has none.
  Future<String?> currentKeyId() => _storage.read(key: _keyIdSlot);

  Future<bool> hasKey() async {
    final id = await currentKeyId();
    if (id == null || id.isEmpty) return false;
    return await _storage.read(key: _privateSlot(id)) != null;
  }

  /// Generates a keypair and stores the private half, returning what the
  /// backend needs to register it.
  ///
  /// Deliberately does not call the backend. The caller registers and then
  /// calls [markActive], so a failed registration cannot leave this device
  /// signing with a key the server has never heard of.
  Future<GeneratedDeviceKey> generate() async {
    final pair = await _algorithm.newKeyPair();
    final publicKey = await pair.extractPublicKey();
    final seed = await pair.extract();

    // The key id is ours to pick; the server treats it as an opaque handle and
    // looks the key up by it. A truncated hash of the public point is stable
    // and collision-free without needing a counter or a round trip.
    final spki = _encodeSpki(publicKey);
    final digest = await Sha256().hash(spki);
    final keyId = base64Url
        .encode(digest.bytes.sublist(0, 16))
        .replaceAll('=', '');

    await _storage.write(
      key: _privateSlot(keyId),
      value: base64.encode(seed.d),
    );

    return GeneratedDeviceKey(
      keyId: keyId,
      publicKeyPem: _toPem(spki),
      publicKeySpkiBase64: base64.encode(spki),
    );
  }

  /// Marks a generated key as the one this device signs with. Called only
  /// after the backend has accepted it.
  Future<void> markActive(String keyId) =>
      _storage.write(key: _keyIdSlot, value: keyId);

  /// Signs [attestation] — the exact canonical string the server rebuilds.
  /// Returns base64 of a DER (RFC 3279) ECDSA signature, the wire format
  /// `ECDsa.VerifyData` is called with server-side.
  ///
  /// Null when this device has no usable key, so callers can send the courier
  /// to the device-key screen rather than surface a crypto error.
  Future<String?> sign(String attestation) async {
    final keyId = await currentKeyId();
    if (keyId == null || keyId.isEmpty) return null;
    final stored = await _storage.read(key: _privateSlot(keyId));
    if (stored == null) return null;

    final pair = await _algorithm.newKeyPairFromSeed(base64.decode(stored));
    final signature = await _algorithm.sign(
      utf8.encode(attestation),
      keyPair: pair,
    );
    return base64.encode(_toDer(signature.bytes));
  }

  /// Forgets the local half of a key. Server-side revocation is a separate
  /// call; this only stops the device signing with it.
  Future<void> forget(String keyId) async {
    await _storage.delete(key: _privateSlot(keyId));
    if (await currentKeyId() == keyId) {
      await _storage.delete(key: _keyIdSlot);
    }
  }

  static Uint8List _encodeSpki(EcPublicKey key) {
    final out = BytesBuilder()
      ..add(_p256SpkiPrefix)
      ..add(_pad32(key.x))
      ..add(_pad32(key.y));
    return out.toBytes();
  }

  /// x and y are big-endian and must each occupy exactly 32 bytes.
  ///
  /// A coordinate with leading zero bytes comes back short, and concatenating
  /// it unpadded shifts Y into X's space, producing a key that verifies
  /// nothing. Roughly one key in 256 has a short X or Y, so skipping this is a
  /// bug that presents as intermittent rather than broken.
  static Uint8List _pad32(List<int> coordinate) {
    if (coordinate.length == 32) return Uint8List.fromList(coordinate);
    if (coordinate.length > 32) {
      // Strip leading zeros rather than truncate meaningful bytes.
      return Uint8List.fromList(
        coordinate.sublist(coordinate.length - 32),
      );
    }
    final padded = Uint8List(32);
    padded.setRange(32 - coordinate.length, 32, coordinate);
    return padded;
  }

  static String _toPem(Uint8List spki) {
    final body = base64.encode(spki);
    final lines = <String>[];
    for (var i = 0; i < body.length; i += 64) {
      final end = i + 64 > body.length ? body.length : i + 64;
      lines.add(body.substring(i, end));
    }
    return '-----BEGIN PUBLIC KEY-----\n'
        '${lines.join('\n')}\n'
        '-----END PUBLIC KEY-----';
  }

  /// Normalises an ECDSA signature to DER, accepting either wire format.
  ///
  /// package:cryptography returns P1363 (raw r then s, 64 bytes for P-256) on
  /// some platforms and DER on others, because it delegates to WebCrypto where
  /// that exists and to its own Dart implementation where it does not. The
  /// backend verifies with `DSASignatureFormat.Rfc3279DerSequence` and accepts
  /// nothing else, so rather than depend on which implementation a given build
  /// resolved, detect and convert. A DER signature already starts with
  /// SEQUENCE (0x30).
  static Uint8List _toDer(List<int> signature) {
    if (signature.isNotEmpty && signature[0] == 0x30) {
      return Uint8List.fromList(signature);
    }
    if (signature.length != 64) {
      // Neither a P-256 raw pair nor DER. Passed through unchanged: the server
      // rejecting it is a clearer failure than this function inventing a
      // structure around bytes it does not understand.
      return Uint8List.fromList(signature);
    }

    final body = BytesBuilder()
      ..add(_derInteger(signature.sublist(0, 32)))
      ..add(_derInteger(signature.sublist(32, 64)));
    final bodyBytes = body.toBytes();

    // A P-256 signature body is always well under 128 bytes, so the short-form
    // length is the only one reachable here.
    final out = BytesBuilder()
      ..add([0x30, bodyBytes.length])
      ..add(bodyBytes);
    return out.toBytes();
  }

  /// DER INTEGER: minimal big-endian, with a leading 0x00 when the top bit is
  /// set so the value is not read as negative.
  static Uint8List _derInteger(List<int> magnitude) {
    var start = 0;
    while (start < magnitude.length - 1 && magnitude[start] == 0x00) {
      start++;
    }
    final trimmed = magnitude.sublist(start);
    final needsPad = trimmed[0] & 0x80 != 0;

    final out = BytesBuilder()
      ..add([0x02, trimmed.length + (needsPad ? 1 : 0)]);
    if (needsPad) out.add([0x00]);
    out.add(trimmed);
    return out.toBytes();
  }
}

/// A freshly generated key, before the backend knows about it.
class GeneratedDeviceKey {
  const GeneratedDeviceKey({
    required this.keyId,
    required this.publicKeyPem,
    required this.publicKeySpkiBase64,
  });

  final String keyId;

  /// PEM-armoured SPKI — what `RegisterDeviceKeyVm.PublicKeyPem` expects. The
  /// backend strips the armor itself (`PemPublicKey.ToSpkiBase64`).
  final String publicKeyPem;

  final String publicKeySpkiBase64;
}
