import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_follow_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/repositories/storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/storefront_links.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_collection_cards.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_reel_grid.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/screens/creator_profile_gate.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/screens/creator_storefront_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../../customer/reels/fake_reels_repository.dart';
import '../../customer/storefront/storefront_test_support.dart';
import '../../customer/storefront/storefront_widget_harness.dart';

GoRoute _creatorRoute() => GoRoute(
  path: RouteNames.creatorProfile,
  builder: (_, state) => CreatorProfileGate(
    args: CreatorProfileArgs(
      accountId: state.pathParameters['accountId']!,
      displayName: 'Sarah K',
      handle: 'sarah_creates',
    ),
  ),
);

void main() {
  late FakeCreatorStorefrontRepository creators;
  late FakeStorefrontRepository storefront;
  late FakeExternalActions external;

  setUp(() {
    creators = FakeCreatorStorefrontRepository();
    storefront = FakeStorefrontRepository();
    external = FakeExternalActions();
  });

  Future<void> pump(
    WidgetTester tester, {
    double width = 390,
    double height = 1600,
    double textScale = 1,
  }) => pumpStorefrontApp(
    tester,
    initialLocation: StorefrontLinks.creator(creatorId),
    storefrontRoute: _creatorRoute(),
    width: width,
    height: height,
    textScale: textScale,
    scope: (app) => ProviderScope(
      overrides: [
        creatorStorefrontRepositoryProvider.overrideWithValue(creators),
        storefrontRepositoryProvider.overrideWithValue(storefront),
        storefrontViewerAccountIdProvider.overrideWithValue('viewer-1'),
        storefrontExternalActionsProvider.overrideWithValue(external),
        followApiProvider.overrideWithValue(FollowApi(ApiClient(dio: Dio()))),
        // Home's reels rail opens the window, which resolves playback here.
        reelsRepositoryProvider.overrideWithValue(FakeReelsRepository()),
      ],
      child: app,
    ),
  );

  testWidgets('header shows the creator, stats, follow and tabs', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(CreatorStorefrontScreen), findsOneWidget);
    expect(find.textContaining('Sarah K'), findsWidgets);
    expect(find.textContaining('@sarah_creates'), findsOneWidget);
    expect(find.textContaining('Kathmandu, NP'), findsOneWidget);
    expect(find.text('STREETWEAR STYLIST'), findsOneWidget);
    expect(find.text('Y2K revival'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('348'), findsOneWidget);
    expect(find.text('1.2K'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
    for (final label in ['Home', 'Reels', 'Shop', 'Collections', 'Looks']) {
      expect(storefrontTab(label), findsOneWidget);
    }
    // Shoppers never see owner tools.
    expect(find.textContaining('Delete'), findsNothing);

    await tester.tap(find.byTooltip('Share Sarah K'));
    await tester.pump();
    expect(
      external.shared.single,
      contains(
        'https://stylemint.voyageritnepal.com/creator-profile/$creatorId',
      ),
    );
  });

  testWidgets('reels grid labels AI reels, sorts and opens a reel', (
    tester,
  ) async {
    storefront.creatorReels[CreatorReelSort.latest] = right(
      page([aiReel, humanReel]),
    );
    storefront.creatorReels[CreatorReelSort.popular] = right(page([humanReel]));
    await pump(tester);

    await tapStorefrontTab(tester, 'Reels');

    expect(find.byType(StorefrontReelTile), findsNWidgets(2));
    expect(find.text('2 reels'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reel-ai')),
        matching: find.text('AI-generated'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reel-human')),
        matching: find.text('AI-generated'),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Popular'));
    await settleStorefront(tester);
    expect(storefront.calls, contains('creatorReels popular'));
    expect(find.byType(StorefrontReelTile), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reel-human')));
    await settleStorefront(tester);
    expect(find.text('reel reel-human'), findsOneWidget);
  });

  testWidgets('the home reels rail plays in the window, not the pager', (
    tester,
  ) async {
    addTearDown(ReelWindow.debugResetOpenState);
    storefront.creatorReels[CreatorReelSort.latest] = right(page([aiReel]));
    await pump(tester);

    final card = find.byType(MallReelCard).first;
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card, warnIfMissed: false);
    await settleStorefront(tester);

    expect(find.byType(ReelWindow), findsOneWidget);
    // The disclosure follows the reel into the window's chrome.
    expect(find.byKey(ReelWindow.aiLabelKey), findsOneWidget);
    expect(find.text('reel reel-ai'), findsNothing);
  });

  testWidgets('shop groups by brand and sorts most loved', (tester) async {
    creators.shop = right(
      page([
        shopProduct('p1'),
        shopProduct(
          'p2',
          vendor: otherVendorId,
          vendorName: 'Loom',
          reelCount: 4,
        ),
        shopProduct('p3', reelCount: 2),
      ]),
    );
    await pump(tester);

    await tapStorefrontTab(tester, 'Shop');

    List<String> names() => tester
        .widgetList<MallProductTile>(find.byType(MallProductTile))
        .map((card) => card.product.name)
        .toList();

    expect(find.text('3 pieces tagged in reels'), findsOneWidget);
    expect(find.text('All · 3'), findsOneWidget);
    expect(find.text('Mint Goods · 2'), findsOneWidget);
    expect(find.text('Loom · 1'), findsOneWidget);
    expect(names(), ['Piece p1', 'Piece p2', 'Piece p3']);

    await tester.ensureVisible(find.text('Loom · 1'));
    await tester.pump();
    await tester.tap(find.text('Loom · 1'));
    await settleStorefront(tester);
    expect(names(), ['Piece p2']);

    await tester.ensureVisible(find.text('All · 3'));
    await tester.pump();
    await tester.tap(find.text('All · 3'));
    await tester.tap(find.text('Most loved'));
    await settleStorefront(tester);
    expect(names(), ['Piece p2', 'Piece p3', 'Piece p1']);
  });

  testWidgets('every tab has a polished empty state', (tester) async {
    await pump(tester);

    expect(find.text('A new style universe is taking shape'), findsOneWidget);
    await tapStorefrontTab(tester, 'Reels');
    expect(find.text('No reels yet'), findsOneWidget);
    await tapStorefrontTab(tester, 'Shop');
    expect(find.text('Shop coming soon'), findsOneWidget);
    await tapStorefrontTab(tester, 'Collections');
    expect(find.text('No collections yet'), findsOneWidget);
    await tapStorefrontTab(tester, 'Looks');
    expect(find.text('No looks yet'), findsOneWidget);
  });

  testWidgets('collections and looks open the collection screen', (
    tester,
  ) async {
    storefront.collections[CollectionKind.creatorCollection] = right(
      page([sampleCollection('thrift-edit'), sampleCollection('city-edit')]),
    );
    storefront.collections[CollectionKind.look] = right(
      page([sampleCollection('monsoon-look', kind: CollectionKind.look)]),
    );
    await pump(tester);

    expect(find.text('Featured collection'), findsOneWidget);
    await tapStorefrontTab(tester, 'Collections');
    expect(find.byType(MallCollectionCard), findsNWidgets(2));

    await tapStorefrontTab(tester, 'Looks');
    expect(find.byType(StorefrontLookCard), findsOneWidget);
    expect(find.text('Shop the look · 6 pieces'), findsOneWidget);
    await tester.tap(find.byType(StorefrontLookCard));
    await settleStorefront(tester);
    expect(find.text('collection monsoon-look'), findsOneWidget);
  });

  testWidgets('404 shows that the creator is not available', (tester) async {
    creators.profile = left(const NetworkExceptions.notFound());
    await pump(tester);

    expect(find.text("This creator isn't available"), findsOneWidget);
    await tester.tap(find.text('Explore the Mall'));
    await settleStorefront(tester);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    creators.profile = left(const NetworkExceptions.noInternetConnection());
    await pump(tester);
    expect(find.text("Couldn't load this creator"), findsOneWidget);

    creators.profile = right(sampleCreator);
    await tester.tap(find.text('Try again'));
    await settleStorefront(tester);
    expect(find.textContaining('@sarah_creates'), findsOneWidget);
  });

  testWidgets('no overflow at 320dp with text ×1.3 on any tab', (tester) async {
    creators.profile = right(
      PublicCreatorProfile(
        accountId: creatorId,
        displayName: 'Priya Shrestha With A Long Display Name',
        handle: 'priya.styles.with.a.long.handle',
        bio:
            'Thrift, streetwear and slow fashion from Kathmandu. Styling '
            'everyday looks with local labels, vintage finds and a lot of '
            'layering for monsoon days in the city.',
        location: 'Lalitpur, Kathmandu Valley, Nepal',
        styleTags: ['Streetwear', 'Minimal', 'Y2K revival', 'Thrift'],
        isVerified: true,
        specializationSummary: 'Streetwear stylist and vintage curator',
        socialLinks: [
          CreatorSocialLink(
            platform: CreatorSocialPlatform.instagram,
            handle: 'priya',
            url: _instagram,
          ),
        ],
      ),
    );
    storefront
      ..follow = right(
        const StorefrontFollowSummary(
          followers: 1284000,
          isFollowedByViewer: true,
        ),
      )
      ..creatorReels[CreatorReelSort.latest] = right(
        page([aiReel, humanReel]),
      )
      ..collections[CollectionKind.creatorCollection] = right(
        page([sampleCollection('a-very-long-collection-slug-for-layout')]),
      )
      ..collections[CollectionKind.look] = right(
        page([sampleCollection('look-one', kind: CollectionKind.look)]),
      );
    creators.shop = right(
      page([
        shopProduct('p1', vendorName: 'Kathmandu Atelier of Hand Loomed Goods'),
        shopProduct('p2', vendor: otherVendorId, vendorName: 'Loom'),
      ]),
    );

    await pump(tester, width: 320, height: 2600, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Following'), findsOneWidget);

    for (final tab in ['Reels', 'Shop', 'Collections', 'Looks', 'Home']) {
      await tapStorefrontTab(tester, tab);
      expect(tester.takeException(), isNull, reason: '$tab tab');
    }
  });

  group('public viewer', () {
    testWidgets('never calls the creator-only /v1/creator/reels route', (
      tester,
    ) async {
      final adapter = _RecordingAdapter({
        '/v1/public/creators/$creatorId': creatorProfileJson()
          ..['avatarUrl'] = null
          ..['coverImageUrl'] = null,
        '/v1/public/creators/$creatorId/reel-stats': reelStatsJson(),
        '/v1/public/creators/$creatorId/reels': pagedJson([
          reelJson()..['thumbnailCdnUrl'] = null,
        ]),
        '/v1/public/creators/$creatorId/shop': pagedJson([
          shopProductJson()..['primaryImageUrl'] = null,
        ]),
        '/v1/public/collections': pagedJson(const []),
        '/v1/follows/$creatorId/stats': {
          'accountId': creatorId,
          'followers': 5,
          'following': 1,
          'isFollowedByViewer': false,
        },
      });

      await pumpStorefrontApp(
        tester,
        initialLocation: StorefrontLinks.creator(creatorId),
        storefrontRoute: _creatorRoute(),
        scope: (app) => ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(
              ApiClient(dio: Dio()..httpClientAdapter = adapter),
            ),
            storefrontNetworkInfoProvider.overrideWithValue(_Online()),
            storefrontViewerAccountIdProvider.overrideWithValue('viewer-2'),
            storefrontExternalActionsProvider.overrideWithValue(
              FakeExternalActions(),
            ),
          ],
          child: app,
        ),
      );

      expect(find.byType(CreatorStorefrontScreen), findsOneWidget);
      expect(find.byType(CreatorProfileScreen), findsNothing);

      await tapStorefrontTab(tester, 'Reels');
      await tester.tap(find.text('Popular'));
      await settleStorefront(tester);

      final paths = adapter.paths;
      expect(paths, contains('/v1/public/creators/$creatorId'));
      expect(paths, contains('/v1/public/creators/$creatorId/reels'));
      expect(
        adapter.requests.map((r) => r.uri.queryParameters['sort']),
        containsAll(<String>['latest', 'popular']),
      );
      expect(paths.where((p) => p.startsWith('/v1/creator/')), isEmpty);
      expect(find.text('AI-generated'), findsOneWidget);
    });
  });
}

final Uri _instagram = Uri.parse('https://www.instagram.com/priya');

class _Online implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

/// Answers requests from [responses] by path (404 otherwise) and records
/// every request.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.responses);

  final Map<String, Object> responses;
  final List<RequestOptions> requests = [];

  List<String> get paths => [for (final request in requests) request.uri.path];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = responses[options.uri.path];
    return ResponseBody.fromString(
      jsonEncode(
        body ??
            const {
              'status': 404,
              'errorCode': 'resource.not_found',
              'title': 'Not found',
            },
      ),
      body == null ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
