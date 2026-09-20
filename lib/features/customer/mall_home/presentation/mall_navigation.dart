import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/in_app_link.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/home_mode.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/scan/domain/style_mint_code.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// App locations the Mall links to.
abstract final class MallRoutes {
  /// Query parameter carrying the listing screen's title.
  static const titleParam = 'title';

  /// Query parameter naming the shared element a screen should fly from.
  /// Carried on the URL so the flight survives a push from anywhere, and
  /// ignored by any caller that does not set it — deep links are unaffected.
  static const heroParam = 'hero';

  static String product(String id) =>
      RouteNames.productDetail.replaceFirst(':productId', id);

  static String reel(String id) =>
      RouteNames.reelDetail.replaceFirst(':reelId', id);

  /// One of the customer's own shopping missions — the checklist screen the
  /// app already has.
  static String mission(String missionId) => RouteNames.mission.replaceFirst(
    ':missionId',
    Uri.encodeComponent(missionId),
  );

  static String creator(String accountId) =>
      RouteNames.creatorProfile.replaceFirst(':accountId', accountId);

  /// A collection or look. With [heroTag] the destination's cover flies from
  /// the tagged element; without it the location is unchanged.
  static String collection(String slug, {String? heroTag}) {
    final path = RouteNames.collection.replaceFirst(':slug', slug);
    final tag = heroTag?.trim();
    if (tag == null || tag.isEmpty) return path;
    return Uri(path: path, queryParameters: {heroParam: tag}).toString();
  }

  /// `/products` with the listing filters in [params].
  static String listing(Map<String, String> params, {String? title}) {
    final name = title?.trim();
    final query = {
      for (final MapEntry(:key, :value) in params.entries)
        if (key != titleParam && value.trim().isNotEmpty) key: value.trim(),
      if (name != null && name.isNotEmpty) titleParam: name,
    };
    return Uri(
      path: RouteNames.productListing,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// A brand's public flagship storefront. [name] is kept for callers that
  /// still pass the display name; the storefront loads it itself.
  // ignore: avoid_unused_parameters
  static String brand(String vendorAccountId, String name) => RouteNames
      .brandStorefront
      .replaceFirst(':vendorAccountId', Uri.encodeComponent(vendorAccountId));

  static String category(HomeCategory category) => listing({
    if (category.slug.isNotEmpty)
      ProductListingQuery.keyCategorySlug: category.slug
    else
      ProductListingQuery.keyCategoryId: category.id,
  }, title: category.name);
}

/// Where a Mall action leads.
sealed class MallDestination {
  const MallDestination();
}

/// Pushes [location] over the current screen.
final class MallPush extends MallDestination {
  const MallPush(this.location);

  final String location;
}

/// Switches to another bottom-bar tab at [location].
final class MallGoTab extends MallDestination {
  const MallGoTab(this.location);

  final String location;
}

/// Switches Home to its Reels view.
final class MallShowReels extends MallDestination {
  const MallShowReels();
}

/// The shared-element tag for a campaign's artwork, used by the cinematic
/// hero and by whatever the campaign opens.
String mallCampaignHeroTag(String campaignId) => 'mall-campaign-$campaignId';

/// The destination of a campaign CTA, or null when it has nowhere to go.
///
/// [heroTag] opts a collection CTA into a shared-element flight from the
/// campaign artwork it was tapped on.
MallDestination? destinationForCta(HomeCampaignCta cta, {String? heroTag}) {
  final value = cta.targetValue.trim();
  return switch (cta.targetKind) {
    HomeCtaTargetKind.collection =>
      value.isEmpty
          ? null
          : MallPush(MallRoutes.collection(value, heroTag: heroTag)),
    HomeCtaTargetKind.reels =>
      value.isEmpty ? const MallShowReels() : MallPush(MallRoutes.reel(value)),
    HomeCtaTargetKind.creators =>
      value.isEmpty
          ? const MallGoTab(RouteNames.search)
          : MallPush(MallRoutes.creator(value)),
    HomeCtaTargetKind.category =>
      value.isEmpty
          ? null
          : MallPush(
              MallRoutes.listing({
                ProductListingQuery.keyCategorySlug: value,
              }, title: cta.label),
            ),
    HomeCtaTargetKind.brand =>
      value.isEmpty ? null : MallPush(MallRoutes.brand(value, cta.label)),
    HomeCtaTargetKind.product =>
      value.isEmpty ? null : MallPush(MallRoutes.product(value)),
    HomeCtaTargetKind.url => switch (styleMintLinkRoute(value)) {
      final route? => MallPush(route),
      null => null,
    },
    HomeCtaTargetKind.unknown => null,
  };
}

/// The "See all" destination of [section], or null when there is no list
/// screen for it yet (brands, collections).
MallDestination? destinationForSeeAll(HomeSection section) {
  final seeAll = section.seeAll;
  if (seeAll == null) return null;
  final params = seeAll.params;
  String? param(List<String> keys) {
    for (final key in keys) {
      final value = params[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  switch (seeAll.target) {
    case HomeSeeAllTarget.productList:
      return MallPush(MallRoutes.listing(params, title: section.title));
    case HomeSeeAllTarget.reels:
      return const MallShowReels();
    case HomeSeeAllTarget.creators:
      return const MallPush(RouteNames.discoverCreators);
    case HomeSeeAllTarget.category:
      final slug = param(const ['categorySlug', 'slug']);
      final id = param(const ['categoryId', 'id']);
      if (slug == null && id == null) return null;
      return MallPush(
        MallRoutes.listing({
          ProductListingQuery.keyCategorySlug: ?slug,
          ProductListingQuery.keyCategoryId: ?id,
        }, title: section.title),
      );
    case HomeSeeAllTarget.collection:
      final slug = param(const ['slug', 'collectionSlug']);
      return slug == null ? null : MallPush(MallRoutes.collection(slug));
    case HomeSeeAllTarget.mission:
      final id = param(const ['missionId', 'id']);
      return id == null ? null : MallPush(MallRoutes.mission(id));
    // "Buy It Again" now has a screen, so a Refill module has somewhere
    // honest to go and is drawn rather than skipped. The screen carries the
    // consent gate and the "these are estimates" framing; this only routes.
    case HomeSeeAllTarget.reorder:
      return const MallPush(RouteNames.buyItAgain);
    case HomeSeeAllTarget.brands:
    case HomeSeeAllTarget.collections:
    case HomeSeeAllTarget.unknown:
      return null;
  }
}

/// The in-app route for a link on one of StyleMint's own hosts, or null.
/// Links elsewhere are never opened from the Mall.
String? styleMintLinkRoute(String link) {
  final raw = link.trim();
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  final scheme = uri.scheme.toLowerCase();
  if ((scheme != 'https' && scheme != 'http') ||
      !isStyleMintWebHost(uri.host)) {
    return null;
  }
  final code = StyleMintCode.parse(raw);
  if (code is StyleMintShortCode) return code.route;
  if (code is StyleMintLinkCode) return code.route;
  final product = styleMintProductRoute(raw);
  if (product != null) return product;
  final path = uri.path;
  final known =
      path == RouteNames.productListing ||
      (path.startsWith(RouteNames.collectionRoot) &&
          path.length > RouteNames.collectionRoot.length) ||
      path.startsWith('${RouteNames.reelsFeed}/');
  if (!known) return null;
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

/// Follows [destination] from a Home widget.
void openMallDestination(
  BuildContext context,
  WidgetRef ref,
  MallDestination destination,
) {
  switch (destination) {
    case MallPush(:final location):
      unawaited(context.push(location));
    case MallGoTab(:final location):
      context.go(location);
    case MallShowReels():
      ref.read(homeModeProvider.notifier).state = HomeMode.reels;
  }
}
