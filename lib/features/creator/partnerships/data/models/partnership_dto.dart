import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'partnership_dto.freezed.dart';
part 'partnership_dto.g.dart';

@freezed
abstract class PartnershipInviteDto with _$PartnershipInviteDto {
  const factory PartnershipInviteDto({
    required String id,
    required String vendorName,
    required String vendorLogoUrl,
    required String campaignBrief,
    required double commissionRate,
    required DateTime expiresAt,
    required String status,
  }) = _PartnershipInviteDto;

  const PartnershipInviteDto._();

  factory PartnershipInviteDto.fromJson(Map<String, dynamic> json) =>
      _$PartnershipInviteDtoFromJson(json);

  PartnershipInvite toDomain() {
    final statusEnum = PartnershipStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => PartnershipStatus.pending,
    );
    return PartnershipInvite(
      id: id,
      vendorName: vendorName,
      vendorLogoUrl: vendorLogoUrl,
      campaignBrief: campaignBrief,
      commissionRate: commissionRate,
      expiresAt: expiresAt,
      status: statusEnum,
    );
  }
}

@freezed
abstract class ActivePartnershipDto with _$ActivePartnershipDto {
  const factory ActivePartnershipDto({
    required String id,
    required String vendorName,
    required String vendorLogoUrl,
    required double commissionRate,
    required double totalEarnedAmount,
    @Default('NPR') String totalEarnedCurrency,
    required int totalSales,
    required DateTime startedAt,
    @Default(0) int productsCount,
  }) = _ActivePartnershipDto;

  const ActivePartnershipDto._();

  factory ActivePartnershipDto.fromJson(Map<String, dynamic> json) =>
      _$ActivePartnershipDtoFromJson(json);

  ActivePartnership toDomain() => ActivePartnership(
    id: id,
    vendorName: vendorName,
    vendorLogoUrl: vendorLogoUrl,
    commissionRate: commissionRate,
    totalEarned: Money(
      amount: totalEarnedAmount,
      currency: totalEarnedCurrency,
    ),
    totalSales: totalSales,
    startedAt: startedAt,
    productsCount: productsCount,
  );
}
