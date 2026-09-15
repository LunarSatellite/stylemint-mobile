import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/repositories/storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/storefront_links.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_hero_parts.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_scaffold.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_states.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/creator_shop_view.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/notifiers/creator_storefront_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/widgets/creator_storefront_hero.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/widgets/creator_storefront_tabs.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';

/// A creator's public storefront: their style universe of reels, tagged
/// products, collections and looks. Shoppers only: no owner tools, and every
/// read is a public route for this creator (never `/v1/creator/*`).
class CreatorStorefrontScreen extends ConsumerStatefulWidget {
  const CreatorStorefrontScreen({required this.args, super.key});

  /// Name, handle and avatar the caller already has; shown while loading.
  final CreatorProfileArgs args;

  @override
  ConsumerState<CreatorStorefrontScreen> createState() =>
      _CreatorStorefrontScreenState();
}

class _CreatorStorefrontScreenState
    extends ConsumerState<CreatorStorefrontScreen> {
  CreatorStorefrontTab _tab = CreatorStorefrontTab.home;
  CreatorReelSort _reelSort = CreatorReelSort.latest;
  CreatorShopSort _shopSort = CreatorShopSort.newest;
  String? _shopBrand;

  String get _id => widget.args.accountId;

  void _openTab(CreatorStorefrontTab tab) => setState(() => _tab = tab);

  Future<void> _share(String name) async {
    final link = StorefrontLinks.creatorWeb(_id);
    try {
      await ref
          .read(storefrontExternalActionsProvider)
          .share(
            text: "Step into $name's style universe on StyleMint\n$link",
            subject: '$name on StyleMint',
          );
    } on Object {
      if (mounted) {
        SmSnackbar.error(context, "Couldn't open sharing. Please try again.");
      }
    }
  }

  Future<void> _openSocial(CreatorSocialLink link) async {
    final opened = await ref
        .read(storefrontExternalActionsProvider)
        .open(link.url);
    if (!opened && mounted) {
      SmSnackbar.error(context, "Couldn't open ${link.platform.label}.");
    }
  }

  void _loadMore() {
    switch (_tab) {
      case CreatorStorefrontTab.home:
        return;
      case CreatorStorefrontTab.reels:
        unawaited(
          ref
              .read(
                creatorReelsProvider((
                  accountId: _id,
                  sort: _reelSort,
                )).notifier,
              )
              .loadMore(),
        );
      case CreatorStorefrontTab.shop:
        unawaited(ref.read(creatorShopProvider(_id).notifier).loadMore());
      case CreatorStorefrontTab.collections:
        unawaited(
          ref
              .read(
                storefrontCollectionsProvider(
                  creatorCollectionsKey(_id),
                ).notifier,
              )
              .loadMore(),
        );
      case CreatorStorefrontTab.looks:
        unawaited(
          ref
              .read(
                storefrontCollectionsProvider(creatorLooksKey(_id)).notifier,
              )
              .loadMore(),
        );
    }
  }

  Object? _contentVersion() => switch (_tab) {
    CreatorStorefrontTab.home => null,
    CreatorStorefrontTab.reels => ref.watch(
      creatorReelsProvider((accountId: _id, sort: _reelSort)),
    ),
    CreatorStorefrontTab.shop => (
      ref.watch(creatorShopProvider(_id)),
      _shopBrand,
      _shopSort,
    ),
    CreatorStorefrontTab.collections => ref.watch(
      storefrontCollectionsProvider(creatorCollectionsKey(_id)),
    ),
    CreatorStorefrontTab.looks => ref.watch(
      storefrontCollectionsProvider(creatorLooksKey(_id)),
    ),
  };

  static List<StorefrontStat> _stats(
    CreatorStorefrontLoaded loaded, {
    required bool following,
  }) {
    final stats = loaded.stats;
    final followers = loaded.followersWhen(following: following);
    return [
      if (stats != null) ...[
        StorefrontStat(
          value: formatCompactNumber(stats.publishedReelCount),
          label: stats.publishedReelCount == 1 ? 'Reel' : 'Reels',
        ),
        StorefrontStat(
          value: formatCompactNumber(stats.totalLikes),
          label: stats.totalLikes == 1 ? 'Like' : 'Likes',
        ),
      ],
      if (followers != null)
        StorefrontStat(
          value: formatCompactNumber(followers),
          label: followers == 1 ? 'Follower' : 'Followers',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final header = ref.watch(creatorStorefrontNotifierProvider(_id));
    // The Home tab's lists stay loaded for the whole visit, so returning to
    // Home (or opening a tab it previews) is instant.
    ref
      ..listen(
        creatorReelsProvider((accountId: _id, sort: CreatorReelSort.latest)),
        (_, _) {},
      )
      ..listen(creatorShopProvider(_id), (_, _) {})
      ..listen(
        storefrontCollectionsProvider(creatorCollectionsKey(_id)),
        (_, _) {},
      )
      ..listen(storefrontCollectionsProvider(creatorLooksKey(_id)), (_, _) {});

    switch (header) {
      case CreatorStorefrontNotFound():
        return StorefrontMessagePage(
          icon: Icons.person_off_outlined,
          title: "This creator isn't available",
          body: 'The profile may be private, or it is no longer on StyleMint.',
          actionLabel: 'Explore the Mall',
          onAction: () => context.go(RouteNames.home),
        );
      case CreatorStorefrontFailure(:final failure):
        return StorefrontMessagePage(
          icon: Icons.cloud_off_rounded,
          title: "Couldn't load this creator",
          body: storefrontErrorBody(failure),
          actionLabel: 'Try again',
          onAction: () => unawaited(
            ref.read(creatorStorefrontNotifierProvider(_id).notifier).load(),
          ),
        );
      case CreatorStorefrontLoading():
      case CreatorStorefrontLoaded():
        break;
    }

    final loaded = header is CreatorStorefrontLoaded ? header : null;
    final profile = loaded?.profile;
    final previewName = widget.args.displayName.trim();
    final name =
        profile?.displayName ??
        (previewName.isEmpty ? 'StyleMint creator' : previewName);
    final firstName = profile?.firstName ?? name.split(' ').first;
    final following = ref.watch(
      followNotifierProvider.select((ids) => ids.contains(_id)),
    );
    final coverExtent = StorefrontCover.extentFor(
      context,
      ratio: 0.52,
      min: 170,
      max: 280,
      topBarExtent: StorefrontScaffold.topBarExtentOf(context),
    );

    return StorefrontScaffold(
      title: name,
      coverExtent: coverExtent,
      tabs: [for (final tab in CreatorStorefrontTab.values) tab.label],
      selectedTab: _tab.index,
      onTabChanged: (index) => _openTab(CreatorStorefrontTab.values[index]),
      onShare: () => unawaited(_share(name)),
      shareLabel: 'Share $name',
      onNearEnd: _loadMore,
      contentVersion: _contentVersion(),
      hero: CreatorStorefrontHero(
        accountId: _id,
        displayName: name,
        coverExtent: coverExtent,
        profile: profile,
        previewHandle: widget.args.handle,
        previewAvatarUrl: widget.args.avatarUrl,
        stats: loaded == null ? const [] : _stats(loaded, following: following),
        onSocialTap: (link) => unawaited(_openSocial(link)),
      ),
      slivers: [
        switch (_tab) {
          CreatorStorefrontTab.home => CreatorHomeTab(
            accountId: _id,
            displayName: name,
            firstName: firstName,
            onOpenTab: _openTab,
          ),
          CreatorStorefrontTab.reels => CreatorReelsTab(
            accountId: _id,
            firstName: firstName,
            sort: _reelSort,
            onSortChanged: (sort) => setState(() => _reelSort = sort),
          ),
          CreatorStorefrontTab.shop => CreatorShopTab(
            accountId: _id,
            firstName: firstName,
            sort: _shopSort,
            brandKey: _shopBrand,
            onSortChanged: (sort) => setState(() => _shopSort = sort),
            onBrandChanged: (brand) => setState(() => _shopBrand = brand),
          ),
          CreatorStorefrontTab.collections => CreatorCollectionsTab(
            accountId: _id,
            firstName: firstName,
            looks: false,
          ),
          CreatorStorefrontTab.looks => CreatorCollectionsTab(
            accountId: _id,
            firstName: firstName,
            looks: true,
          ),
        },
      ],
    );
  }
}
