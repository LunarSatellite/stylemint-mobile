import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/app.dart';

void main() {
  test('root app is the Riverpod-powered StyleMint application', () {
    expect(const StyleMintApp(), isA<ConsumerWidget>());
  });
}
