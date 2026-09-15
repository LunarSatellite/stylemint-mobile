import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_follow_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/repositories/storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_reel_stats.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/repositories/creator_storefront_repository.dart';

/// The header of a creator's storefront.
sealed class CreatorStorefrontState {
  const CreatorStorefrontState();
}

final class CreatorStorefrontLoading extends CreatorStorefrontState {
  const CreatorStorefrontLoading();
}

/// The creator doesn't exist or isn't public.
final class CreatorStorefrontNotFound extends CreatorStorefrontState {
  const CreatorStorefrontNotFound();
}

final class CreatorStorefrontFailure extends CreatorStorefrontState {
  const CreatorStorefrontFailure(this.failure);

  final NetworkExceptions failure;
}

final class CreatorStorefrontLoaded extends CreatorStorefrontState {
  const CreatorStorefrontLoaded({
    required this.profile,
    this.stats,
    this.followers,
    this.followedAtLoad = false,
  });

  final PublicCreatorProfile profile;

  /// Null when the stats couldn't be read; the page still shows.
  final CreatorReelStats? stats;

  /// Null when the follower count couldn't be read.
  final int? followers;

  /// Whether the viewer followed the creator when the count was read.
  final bool followedAtLoad;

  /// The follower count adjusted for a follow toggled since loading.
  int? followersWhen({required bool following}) {
    final base = followers;
    if (base == null) return null;
    if (following == followedAtLoad) return base;
    return math.max(0, base + (following ? 1 : -1));
  }
}

/// Loads a creator's profile, reel stats and follower count together. Only
/// the profile is required: a missing profile is [CreatorStorefrontNotFound],
/// and stats or follower failures just hide those figures.
class CreatorStorefrontNotifier extends StateNotifier<CreatorStorefrontState> {
  CreatorStorefrontNotifier(
    this._repository,
    this._storefront, {
    required this.accountId,
    this.onFollowSummary,
  }) : super(const CreatorStorefrontLoading()) {
    unawaited(load());
  }

  final CreatorStorefrontRepository _repository;
  final StorefrontRepository _storefront;
  final String accountId;

  /// Receives the viewer's follow state once known (seeds the follow button).
  final void Function(StorefrontFollowSummary summary)? onFollowSummary;

  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    state = const CreatorStorefrontLoading();
    final profileCall = _repository.getProfile(accountId);
    final statsCall = _repository.getReelStats(accountId);
    final followCall = _storefront.getFollowSummary(accountId);
    final profile = await profileCall;
    final stats = await statsCall;
    final follow = await followCall;
    if (!mounted || generation != _generation) return;

    final summary = follow.fold<StorefrontFollowSummary?>(
      (_) => null,
      (value) => value,
    );
    final next = profile.fold<CreatorStorefrontState>(
      (failure) => failure.isNotFound
          ? const CreatorStorefrontNotFound()
          : CreatorStorefrontFailure(failure),
      (value) => CreatorStorefrontLoaded(
        profile: value,
        stats: stats.fold<CreatorReelStats?>((_) => null, (s) => s),
        followers: summary?.followers,
        followedAtLoad: summary?.isFollowedByViewer ?? false,
      ),
    );
    state = next;
    if (summary != null && next is CreatorStorefrontLoaded) {
      onFollowSummary?.call(summary);
    }
  }
}
