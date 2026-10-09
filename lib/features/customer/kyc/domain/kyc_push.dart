import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// The `kyc.decided` push to a buyer: `{ "type": "kyc.decided",
/// "status": "Approved|Rejected" }`. Routed by type, like the delivery
/// notifications — the payload carries no link.
class KycDecidedPush {
  const KycDecidedPush({required this.status});

  static const type = 'kyc.decided';

  /// `Approved`, `Rejected`, or [KycStatus.unknown] for anything else — the
  /// status screen reads the real record on open either way.
  final KycStatus status;

  /// Null when [data] is not a KYC decision.
  static KycDecidedPush? fromData(Map<String, dynamic> data) {
    final raw = data['type']?.toString().trim().toLowerCase();
    if (raw != type) return null;
    return KycDecidedPush(status: KycStatus.fromWire(data['status']));
  }

  /// The verification status screen, which reloads the record.
  String get route => RouteNames.customerKyc;

  /// The in-app banner when it arrives with the app open.
  String get message => switch (status) {
    KycStatus.approved => 'You are verified for EMI',
    KycStatus.rejected => 'Your EMI verification needs another look',
    _ => 'Your EMI verification has been reviewed',
  };
}
