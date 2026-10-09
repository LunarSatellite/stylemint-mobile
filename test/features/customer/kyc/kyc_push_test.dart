import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/kyc_push.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

void main() {
  test('kyc.decided opens the verification status screen', () {
    final approved = KycDecidedPush.fromData({
      'type': 'kyc.decided',
      'status': 'Approved',
    })!;
    expect(approved.status, KycStatus.approved);
    expect(approved.route, RouteNames.customerKyc);
    expect(approved.message, contains('verified'));

    final rejected = KycDecidedPush.fromData({
      'type': 'KYC.Decided',
      'status': 'Rejected',
    })!;
    expect(rejected.status, KycStatus.rejected);
  });

  test('other notifications are not KYC decisions', () {
    expect(KycDecidedPush.fromData({'type': 'delivery.request'}), isNull);
    expect(KycDecidedPush.fromData(<String, dynamic>{}), isNull);
  });

  test('an unexpected status still routes, to a screen that re-reads it', () {
    final push = KycDecidedPush.fromData({'type': 'kyc.decided'})!;
    expect(push.status, KycStatus.unknown);
    expect(push.route, RouteNames.customerKyc);
  });
}
