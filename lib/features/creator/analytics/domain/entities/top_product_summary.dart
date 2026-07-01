import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class TopProductSummary {
  const TopProductSummary({
    required this.productId,
    required this.name,
    required this.thumbnailUrl,
    required this.totalSales,
    required this.totalCommission,
    required this.commissionRatePercent,
    required this.avgCommissionPerSale,
  });

  final String productId;
  final String name;
  final String thumbnailUrl;
  final int totalSales;
  final Money totalCommission;
  final double commissionRatePercent;
  final Money avgCommissionPerSale;
}
