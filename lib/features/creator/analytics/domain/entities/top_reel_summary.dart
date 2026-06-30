import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class TopReelSummary {
  const TopReelSummary({
    required this.reelId,
    required this.title,
    required this.thumbnailUrl,
    required this.publishedAtUtc,
    required this.views,
    required this.likes,
    required this.impressions,
    required this.shares,
    required this.comments,
    required this.sales,
    required this.earnings,
  });

  final String reelId;
  final String title;
  final String thumbnailUrl;
  final DateTime publishedAtUtc;
  final int views;
  final int likes;
  final int impressions;
  final int shares;
  final int comments;
  final int sales;
  final Money earnings;
}
