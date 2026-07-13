import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A row from `GET /v1/vendor/analytics/creators` (Vendor §8B). The backend
/// doesn't enrich this list with creator handle/display-name/avatar, so
/// [label] is the only identity shown — a masked short id.
class CreatorPerformance {
  const CreatorPerformance({
    required this.creatorAccountId,
    required this.unitsSold,
    required this.attributedRevenue,
    required this.commissionPaid,
    required this.distinctReelCount,
  });

  final String creatorAccountId;
  final int unitsSold;
  final Money attributedRevenue;
  final Money commissionPaid;
  final int distinctReelCount;

  String get label => creatorAccountId.length >= 4
      ? 'Creator ••${creatorAccountId.substring(creatorAccountId.length - 4)}'
      : 'Creator';

  CreatorPerformance copyWith({
    String? creatorAccountId,
    int? unitsSold,
    Money? attributedRevenue,
    Money? commissionPaid,
    int? distinctReelCount,
  }) {
    return CreatorPerformance(
      creatorAccountId: creatorAccountId ?? this.creatorAccountId,
      unitsSold: unitsSold ?? this.unitsSold,
      attributedRevenue: attributedRevenue ?? this.attributedRevenue,
      commissionPaid: commissionPaid ?? this.commissionPaid,
      distinctReelCount: distinctReelCount ?? this.distinctReelCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CreatorPerformance &&
      other.creatorAccountId == creatorAccountId &&
      other.unitsSold == unitsSold &&
      other.attributedRevenue == attributedRevenue &&
      other.commissionPaid == commissionPaid &&
      other.distinctReelCount == distinctReelCount;

  @override
  int get hashCode => Object.hash(
    creatorAccountId,
    unitsSold,
    attributedRevenue,
    commissionPaid,
    distinctReelCount,
  );
}
