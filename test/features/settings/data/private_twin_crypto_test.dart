import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/services/private_twin_crypto.dart';

void main() {
  const payload = '{"schema":"stylemint.private-commerce-twin","memories":[]}';
  const password = 'correct horse battery staple';

  test('encrypts without exposing plaintext and decrypts on device', () async {
    final crypto = PrivateTwinCrypto();

    final encrypted = await crypto.encrypt(payload, password);
    final envelope = utf8.decode(encrypted);

    expect(envelope, isNot(contains(payload)));
    expect(envelope, contains('AES-256-GCM'));
    expect(await crypto.decrypt(encrypted, password), payload);
  });

  test('rejects a wrong password', () async {
    final crypto = PrivateTwinCrypto();
    final encrypted = await crypto.encrypt(payload, password);

    expect(
      () => crypto.decrypt(encrypted, 'incorrect password value'),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a weak backup password', () async {
    expect(
      () => PrivateTwinCrypto().encrypt(payload, 'short'),
      throwsA(isA<FormatException>()),
    );
  });
}
