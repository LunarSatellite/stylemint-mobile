import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class ReelProductEarningsSlice {
  const ReelProductEarningsSlice({
    required this.productId,
    this.name,
    this.thumbnailUrl,
    required this.amount,
    required this.quantity,
    required this.percentOfTotal,
  });

  final String productId;
  final String? name;
  final String? thumbnailUrl;
  final Money amount;
  final int quantity;
  final double percentOfTotal;
}
