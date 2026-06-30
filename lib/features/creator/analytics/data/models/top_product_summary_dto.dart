import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/money_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_product_summary.dart';

part 'top_product_summary_dto.freezed.dart';
part 'top_product_summary_dto.g.dart';

@freezed
abstract class TopProductSummaryDto with _$TopProductSummaryDto {
  const factory TopProductSummaryDto({
    required String productId,
    required MoneyDto totalCommission,
    required MoneyDto avgCommissionPerSale,
    @Default('') String name,
    @Default('') String thumbnailUrl,
    @Default(0) int totalSales,
    @Default(0.0) double commissionRatePercent,
  }) = _TopProductSummaryDto;

  const TopProductSummaryDto._();

  factory TopProductSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$TopProductSummaryDtoFromJson(json);

  TopProductSummary toDomain() => TopProductSummary(
    productId: productId,
    name: name,
    thumbnailUrl: thumbnailUrl,
    totalSales: totalSales,
    totalCommission: totalCommission.toDomain(),
    commissionRatePercent: commissionRatePercent,
    avgCommissionPerSale: avgCommissionPerSale.toDomain(),
  );
}
