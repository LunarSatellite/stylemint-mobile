import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class ContentPerformancePoint {
  const ContentPerformancePoint({
    required this.reelId,
    this.title,
    this.thumbnailUrl,
    required this.earnings,
    required this.sales,
  });

  final String reelId;
  final String? title;
  final String? thumbnailUrl;
  final Money earnings;
  final int sales;
}
