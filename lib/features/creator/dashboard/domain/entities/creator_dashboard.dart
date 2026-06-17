import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A "top performing" reel from the dashboard payload (`topReels[]`). Matches
/// the backend item: `reelId, title, thumbnailUrl, publishedAtUtc, views,
/// likes, impressions, shares, comments, sales, earnings`. We model the subset
/// the dashboard renders.
class CreatorReel {
  const CreatorReel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.publishedAt,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final DateTime publishedAt;
  final int views;
  final int likes;
  final int comments;
  final int shares;

  CreatorReel copyWith({
    String? id,
    String? title,
    String? thumbnailUrl,
    DateTime? publishedAt,
    int? views,
    int? likes,
    int? comments,
    int? shares,
  }) {
    return CreatorReel(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CreatorReel &&
      other.id == id &&
      other.title == title &&
      other.thumbnailUrl == thumbnailUrl &&
      other.publishedAt == publishedAt &&
      other.views == views &&
      other.likes == likes &&
      other.comments == comments &&
      other.shares == shares;

  @override
  int get hashCode =>
      Object.hash(id, title, thumbnailUrl, publishedAt, views, likes, comments, shares);
}

/// Mirrors the `GET /v1/creator/analytics/dashboard` payload. Only the fields
/// the API actually returns are modelled here — earnings (+ period delta),
/// pending balance, sales/views totals, and top reels. (The previous
/// `totalReels`/`totalEngagement`/`activePartnerships`/`pendingInvites` fields
/// were never part of this endpoint and have been removed.)
class CreatorDashboard {
  const CreatorDashboard({
    required this.earnings,
    required this.pendingBalance,
    required this.totalSales,
    required this.totalViews,
    required this.topReels,
    this.earningsDeltaPercent,
  });

  /// `totalEarnings.current` for the window.
  final Money earnings;

  /// `totalEarnings.deltaPercent` — percent change vs the previous window.
  /// `null` when the backend has no comparison baseline yet.
  final double? earningsDeltaPercent;

  final Money pendingBalance;
  final int totalSales;
  final int totalViews;
  final List<CreatorReel> topReels;

  CreatorDashboard copyWith({
    Money? earnings,
    double? earningsDeltaPercent,
    Money? pendingBalance,
    int? totalSales,
    int? totalViews,
    List<CreatorReel>? topReels,
  }) {
    return CreatorDashboard(
      earnings: earnings ?? this.earnings,
      earningsDeltaPercent: earningsDeltaPercent ?? this.earningsDeltaPercent,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalSales: totalSales ?? this.totalSales,
      totalViews: totalViews ?? this.totalViews,
      topReels: topReels ?? this.topReels,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CreatorDashboard &&
      other.earnings == earnings &&
      other.earningsDeltaPercent == earningsDeltaPercent &&
      other.pendingBalance == pendingBalance &&
      other.totalSales == totalSales &&
      other.totalViews == totalViews;

  @override
  int get hashCode => Object.hash(
    earnings,
    earningsDeltaPercent,
    pendingBalance,
    totalSales,
    totalViews,
  );
}
