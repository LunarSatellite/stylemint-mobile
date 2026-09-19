import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/loyalty_wallet.dart';

void main() {
  test('parses numeric loyalty contract and checkout credit', () {
    final wallet = LoyaltyWallet.fromJson(<String, dynamic>{
      'summary': <String, dynamic>{
        'balancePoints': 1250,
        'redeemableValueAmount': 125.0,
        'checkoutCreditAmount': 50.0,
        'currency': 'NPR',
        'tier': 2,
        'lifetimeEarnedPoints': 2300,
        'lifetimeRedeemedPoints': 500,
        'pointsToNextTier': 2700,
        'pointsExpiringNext30Days': 100,
      },
      'transactions': <dynamic>[
        <String, dynamic>{
          'id': 'entry-1',
          'kind': 1,
          'pointsDelta': 250,
          'description': 'Delivered order',
          'occurredUtc': '2026-09-17T12:00:00Z',
        },
      ],
    });

    expect(wallet.summary.tier, 'Bloom');
    expect(wallet.summary.balancePoints, 1250);
    expect(wallet.summary.checkoutCreditAmount, 50);
    expect(wallet.transactions.single.pointsDelta, 250);
  });

  test('unknown and sparse values degrade safely', () {
    final wallet = LoyaltyWallet.fromJson(<String, dynamic>{
      'summary': <String, dynamic>{'tier': 99},
    });

    expect(wallet.summary.tier, 'Icon');
    expect(wallet.summary.balancePoints, 0);
    expect(wallet.summary.currency, 'NPR');
    expect(wallet.transactions, isEmpty);
  });
}
