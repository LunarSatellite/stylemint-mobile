import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class ConversionMetrics {
  const ConversionMetrics({
    required this.totalClicks,
    required this.totalOrders,
    required this.conversionRate,
    required this.averageOrderValue,
  });

  final int totalClicks;
  final int totalOrders;
  final double conversionRate;
  final Money averageOrderValue;
}
