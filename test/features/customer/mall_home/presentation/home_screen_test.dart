import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/home_mode.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/home_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/mall_home_page.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reels_pager.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../mall_test_support.dart';

class _MockCartRepository extends Mock implements CartRepository {}

class _FakeFollowApi implements FollowApi {
  @override
  Future<void> follow(String followeeAccountId) async {}

  @override
  Future<void> unfollow(String followeeAccountId) async {}

  @override
  Future<List<String>> followingIds({int pageSize = 200}) async =>
      const <String>[];

  @override
  Future<FollowStats> stats(String accountId) => throw UnimplementedError();
}

class _FakeReelsRepository implements ReelsRepository {
  int feedCalls = 0;

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getReelsFeed({
    int limit = 20,
    String? cursor,
  }) async {
    feedCalls++;
    return right(ReelsFeedPage(reels: [_reel('one')], nextCursor: null));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Instagram without media: shows its poster, no WebView needed.
Reel _reel(String id) => Reel(
  id: id,
  sourceUrl: 'https://www.instagram.com/reel/$id/',
  thumbnailUrl: '',
  creatorId: 'creator-$id',
  creatorName: 'Creator $id',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: const [],
  likeCount: 3,
  commentCount: 1,
  shareCount: 0,
  createdAt: DateTime(2026, 9, 15),
);

const _zero = Money(amount: 0, currency: 'NPR');

void main() {
  late _FakeReelsRepository reels;
  late _MockCartRepository cart;

  setUp(() {
    ReelsPager.debugHostEmbedPlayers = false;
    reels = _FakeReelsRepository();
    cart = _MockCartRepository();
    when(() => cart.getCart()).thenAnswer(
      (_) async => right(
        const Cart(
          id: 'cart',
          items: [],
          subtotal: _zero,
          shippingTotal: _zero,
          taxTotal: _zero,
          total: _zero,
        ),
      ),
    );
  });

  tearDown(() => ReelsPager.debugHostEmbedPlayers = true);

  Future<ProviderContainer> pumpHome(WidgetTester tester) async {
    await pumpMallApp(
      tester,
      location: '/home',
      routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())],
      overrides: [
        mallHomeRepositoryProvider.overrideWithValue(
          FakeMallHomeRepository([right(sampleHome())]),
        ),
        mallViewerSignedInProvider.overrideWithValue(false),
        mallClockProvider.overrideWithValue(mallTestNow),
        reelsRepositoryProvider.overrideWithValue(reels),
        cartRepositoryProvider.overrideWithValue(cart),
        followApiProvider.overrideWithValue(_FakeFollowApi()),
      ],
    );
    return ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
  }

  bool tickerEnabled(WidgetTester tester, Type type) => TickerMode.valuesOf(
    tester.element(find.byType(type, skipOffstage: false)),
  ).enabled;

  // SM-005 (22 Sep TestFlight QA): the app opened on the Mall. Reels is the
  // intended landing surface, so Home now starts there and the feed is part
  // of the launch path rather than something built on first switch.
  testWidgets('opens on Reels and loads the feed', (tester) async {
    final container = await pumpHome(tester);
    await tester.pump();

    expect(container.read(homeModeProvider), HomeMode.reels);
    expect(find.byType(ReelsPager), findsOneWidget);
    expect(reels.feedCalls, 1);
    expect(tickerEnabled(tester, ReelsPager), isTrue);
    expect(tickerEnabled(tester, MallHomePage), isFalse);
  });

  testWidgets('the switch shows the Mall, and pauses reels while it is up', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    await tester.pump();

    await tester.tap(find.text('Mall'));
    await tester.pump();

    expect(container.read(homeModeProvider), HomeMode.mall);
    expect(find.byType(MallHomePage), findsOneWidget);
    expect(tickerEnabled(tester, ReelsPager), isFalse);
    expect(tickerEnabled(tester, MallHomePage), isTrue);

    await tester.tap(find.text('Reels'));
    await tester.pump();

    expect(container.read(homeModeProvider), HomeMode.reels);
    expect(tickerEnabled(tester, ReelsPager), isTrue);
    expect(tickerEnabled(tester, MallHomePage), isFalse);
    // The feed is kept, so switching back is instant.
    expect(find.byType(ReelsPager, skipOffstage: false), findsOneWidget);
    expect(reels.feedCalls, 1);
  });

  testWidgets('Home re-tap on Reels still refreshes the reels feed', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    await tester.pump();
    expect(reels.feedCalls, 1);

    container.read(homeTabReselectedProvider.notifier).state++;
    await tester.pump();
    await tester.pump();
    expect(reels.feedCalls, 2);
  });

  testWidgets('switch segments are 44dp tall', (tester) async {
    await pumpHome(tester);
    for (final label in ['Mall', 'Reels']) {
      final target = find
          .ancestor(
            of: find.text(label),
            matching: find.byType(GestureDetector),
          )
          .first;
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    }
  });
}
