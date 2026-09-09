import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/models/earnings_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';

void main() {
  group('PayoutMethodDto', () {
    test('maps every backend payout destination kind exactly', () {
      final expected = <int, PayoutMethodType>{
        1: PayoutMethodType.nimbBank,
        2: PayoutMethodType.laxmiBank,
        3: PayoutMethodType.paypal,
        4: PayoutMethodType.esewa,
      };

      for (final entry in expected.entries) {
        final method = PayoutMethodDto(
          id: 'destination-${entry.key}',
          kind: entry.key,
          label: 'Destination ${entry.key}',
        ).toDomain();

        expect(method.type, entry.value);
      }
    });
  });
}
