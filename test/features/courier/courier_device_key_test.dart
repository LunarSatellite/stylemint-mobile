import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_device_key.dart';

/// Reads a DER ECDSA signature back into r and s.
ECSignature _parseDer(Uint8List der) {
  expect(der[0], 0x30, reason: 'DER signature must be a SEQUENCE');
  var i = 2;
  BigInt readInt() {
    expect(der[i], 0x02, reason: 'expected an INTEGER');
    final len = der[i + 1];
    final bytes = der.sublist(i + 2, i + 2 + len);
    i += 2 + len;
    var v = BigInt.zero;
    for (final b in bytes) {
      v = (v << 8) | BigInt.from(b);
    }
    return v;
  }

  final r = readInt();
  final s = readInt();
  expect(i, der.length);
  return ECSignature(r, s);
}

ECPublicKey _publicKeyFromSpki(Uint8List spki) {
  final domain = ECDomainParameters('secp256r1');
  // Last 65 bytes: 0x04 || X || Y.
  final point = domain.curve.decodePoint(spki.sublist(spki.length - 65));
  return ECPublicKey(point, domain);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('generates a P-256 key and signs what the server can verify', () async {
    final key = CourierDeviceKey();

    final generated = await key.generate();
    final spki = base64.decode(generated.publicKeySpkiBase64);
    expect(spki.length, 91, reason: 'P-256 SPKI is always 91 bytes');
    expect(generated.publicKeyPem, startsWith('-----BEGIN PUBLIC KEY-----\n'));
    expect(generated.keyId, isNotEmpty);

    // Not active until the backend accepts it.
    expect(await key.sign('anything'), isNull);
    await key.markActive(generated.keyId);
    expect(await key.hasKey(), isTrue);

    const attestation = 'v1|hop=7f1c|event=PickedUp|at=2026-10-09T08:00:00Z';
    final signatureB64 = await key.sign(attestation);
    expect(signatureB64, isNotNull);
    final der = base64.decode(signatureB64!);

    final verifier = ECDSASigner(SHA256Digest())
      ..init(false, PublicKeyParameter<ECPublicKey>(_publicKeyFromSpki(spki)));
    expect(
      verifier.verifySignature(
        Uint8List.fromList(utf8.encode(attestation)),
        _parseDer(der),
      ),
      isTrue,
    );

    // Lets the VPS check cross-verify with OpenSSL (same DER/SPKI formats the
    // backend's ECDsa.VerifyData uses).
    final out = Platform.environment['COURIER_KEY_CHECK_DIR'];
    if (out != null) {
      Directory(out).createSync(recursive: true);
      File('$out/pub.pem').writeAsStringSync('${generated.publicKeyPem}\n');
      File('$out/sig.der').writeAsBytesSync(der);
      File('$out/msg.txt').writeAsStringSync(attestation);
    }
  });

  test('every key round-trips, including short coordinates', () async {
    // ~1 key in 128 has a leading zero byte in X or Y; 40 keys exercise the
    // fixed-width encoding often enough to catch a regression over time.
    for (var n = 0; n < 40; n++) {
      FlutterSecureStorage.setMockInitialValues({});
      final key = CourierDeviceKey();
      final generated = await key.generate();
      await key.markActive(generated.keyId);
      final spki = base64.decode(generated.publicKeySpkiBase64);
      final message = 'm$n';
      final der = base64.decode((await key.sign(message))!);
      final verifier = ECDSASigner(SHA256Digest())
        ..init(
          false,
          PublicKeyParameter<ECPublicKey>(_publicKeyFromSpki(spki)),
        );
      expect(
        verifier.verifySignature(
          Uint8List.fromList(utf8.encode(message)),
          _parseDer(der),
        ),
        isTrue,
        reason: 'key $n',
      );
    }
  });

  test('forgetting the active key stops signing', () async {
    final key = CourierDeviceKey();
    final generated = await key.generate();
    await key.markActive(generated.keyId);
    await key.forget(generated.keyId);
    expect(await key.hasKey(), isFalse);
    expect(await key.sign('x'), isNull);
  });
}
