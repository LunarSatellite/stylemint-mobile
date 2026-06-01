import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum PartnershipStatus { pending, accepted, declined, expired, active }

class PartnershipInvite {
  const PartnershipInvite({
    required this.id,
    required this.vendorName,
    required this.vendorLogoUrl,
    required this.campaignBrief,
    required this.commissionRate,
    required this.expiresAt,
    required this.status,
  });

  final String id;
  final String vendorName;
  final String vendorLogoUrl;
  final String campaignBrief;
  final double commissionRate;
  final DateTime expiresAt;
  final PartnershipStatus status;

  PartnershipInvite copyWith({
    String? id,
    String? vendorName,
    String? vendorLogoUrl,
    String? campaignBrief,
    double? commissionRate,
    DateTime? expiresAt,
    PartnershipStatus? status,
  }) {
    return PartnershipInvite(
      id: id ?? this.id,
      vendorName: vendorName ?? this.vendorName,
      vendorLogoUrl: vendorLogoUrl ?? this.vendorLogoUrl,
      campaignBrief: campaignBrief ?? this.campaignBrief,
      commissionRate: commissionRate ?? this.commissionRate,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
    );
  }
}

class ActivePartnership {
  const ActivePartnership({
    required this.id,
    required this.vendorName,
    required this.vendorLogoUrl,
    required this.commissionRate,
    required this.totalEarned,
    required this.totalSales,
    required this.startedAt,
    required this.productsCount,
  });

  final String id;
  final String vendorName;
  final String vendorLogoUrl;
  final double commissionRate;
  final Money totalEarned;
  final int totalSales;
  final DateTime startedAt;
  final int productsCount;

  ActivePartnership copyWith({
    String? id,
    String? vendorName,
    String? vendorLogoUrl,
    double? commissionRate,
    Money? totalEarned,
    int? totalSales,
    DateTime? startedAt,
    int? productsCount,
  }) {
    return ActivePartnership(
      id: id ?? this.id,
      vendorName: vendorName ?? this.vendorName,
      vendorLogoUrl: vendorLogoUrl ?? this.vendorLogoUrl,
      commissionRate: commissionRate ?? this.commissionRate,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSales: totalSales ?? this.totalSales,
      startedAt: startedAt ?? this.startedAt,
      productsCount: productsCount ?? this.productsCount,
    );
  }
}
