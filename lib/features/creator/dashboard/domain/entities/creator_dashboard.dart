import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum CreatorReelStatus {
  active('Active'),
  pending('Pending'),
  flagged('Flagged');

  const CreatorReelStatus(this.label);

  final String label;
}

class CreatorReel {
  const CreatorReel({
    required this.id,
    required this.platform,
    required this.thumbnailUrl,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String platform;
  final String thumbnailUrl;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final DateTime createdAt;
  final CreatorReelStatus status;

  CreatorReel copyWith({
    String? id,
    String? platform,
    String? thumbnailUrl,
    int? views,
    int? likes,
    int? comments,
    int? shares,
    DateTime? createdAt,
    CreatorReelStatus? status,
  }) {
    return CreatorReel(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CreatorReel &&
      other.id == id &&
      other.platform == platform &&
      other.thumbnailUrl == thumbnailUrl &&
      other.views == views &&
      other.likes == likes &&
      other.comments == comments &&
      other.shares == shares &&
      other.createdAt == createdAt &&
      other.status == status;

  @override
  int get hashCode => Object.hash(id, platform, thumbnailUrl, views, likes, comments, shares, createdAt, status);
}

class CreatorDashboard {
  const CreatorDashboard({
    required this.earnings,
    required this.totalReels,
    required this.totalViews,
    required this.totalEngagement,
    required this.recentReels,
    required this.activePartnerships,
    required this.pendingInvites,
  });

  final Money earnings;
  final int totalReels;
  final int totalViews;
  final int totalEngagement;
  final List<CreatorReel> recentReels;
  final int activePartnerships;
  final int pendingInvites;

  CreatorDashboard copyWith({
    Money? earnings,
    int? totalReels,
    int? totalViews,
    int? totalEngagement,
    List<CreatorReel>? recentReels,
    int? activePartnerships,
    int? pendingInvites,
  }) {
    return CreatorDashboard(
      earnings: earnings ?? this.earnings,
      totalReels: totalReels ?? this.totalReels,
      totalViews: totalViews ?? this.totalViews,
      totalEngagement: totalEngagement ?? this.totalEngagement,
      recentReels: recentReels ?? this.recentReels,
      activePartnerships: activePartnerships ?? this.activePartnerships,
      pendingInvites: pendingInvites ?? this.pendingInvites,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CreatorDashboard &&
      other.earnings == earnings &&
      other.totalReels == totalReels &&
      other.totalViews == totalViews &&
      other.totalEngagement == totalEngagement &&
      other.activePartnerships == activePartnerships &&
      other.pendingInvites == pendingInvites;

  @override
  int get hashCode => Object.hash(earnings, totalReels, totalViews, totalEngagement, activePartnerships, pendingInvites);
}
