import 'dart:async';

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
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reel_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reels_pager.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';

class _MockCartRepository extends Mock implements CartRepository {}

class _FakeFollowApi implements FollowApi {
  @override
  Future<void> follow(String followeeAccountId) async {}

  @override
  Future<void> unfollow(String followeeAccountId) async {}

  @override
  Future<FollowStats> stats(String accountId) => throw UnimplementedError();
}

class _FakeReelsRepository implements ReelsRepository {
  Either<NetworkExceptions, Reel> detail = right(_reel('landed'));
  Either<NetworkExceptions, ReelsFeedPage> related = right(
    const ReelsFeedPage(reels: [], nextCursor: null),
  );

  /// When set, related reels wait for it.
  Completer<void>? relatedGate;

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async =>
      detail;

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getRelatedReels(
    String reelId, {
    int limit = 10,
    String? cursor,
  }) async {
    await relatedGate?.future;
    return related;
  }

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getReelsFeed({
    int limit = 20,
    String? cursor,
  }) async => right(const ReelsFeedPage(reels: [], nextCursor: null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An Instagram reel without a media URL: it shows its poster, so the test
/// needs no video or WebView platform.
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

const _emptyCart = Cart(
  id: 'cart-1',
  items: [],
  subtotal: _zero,
  shippingTotal: _zero,
  taxTotal: _zero,
  total: _zero,
);

void main() {
  late _MockCartRepository cartRepository;
  late _FakeReelsRepository reelsRepository;

  setUp(() {
    ReelsPager.debugHostEmbedPlayers = false;
    cartRepository = _MockCartRepository();
    reelsRepository = _FakeReelsRepository();
    when(
      () => cartRepository.getCart(),
    ).thenAnswer((_) async => right(_emptyCart));
  });

  tearDown(() => ReelsPager.debugHostEmbedPlayers = true);

  Future<void> pumpLanding(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/reels/landed',
      routes: [
        GoRoute(path: RouteNames.home, builder: (_, _) => const Text('Home')),
        GoRoute(
          path: RouteNames.reelDetail,
          builder: (_, state) =>
              ReelDetailScreen(reelId: state.pathParameters['reelId']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartRepositoryProvider.overrideWithValue(cartRepository),
          followApiProvider.overrideWithValue(_FakeFollowApi()),
          reelsRepositoryProvider.overrideWithValue(reelsRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  List<String> shownIds(WidgetTester tester) => [
    for (final reel in tester.widget<ReelsPager>(find.byType(ReelsPager)).reels)
      reel.id,
  ];

  testWidgets('a shared reel lands first and full screen, with a back button, '
      'and its related reels follow without repeats', (tester) async {
    final gate = reelsRepository.relatedGate = Completer<void>();
    reelsRepository.related = right(
      ReelsFeedPage(
        reels: [_reel('r1'), _reel('landed'), _reel('r2'), _reel('r1')],
        nextCursor: null,
      ),
    );

    await pumpLanding(tester);

    expect(shownIds(tester), ['landed'], reason: 'shown before related load');
    final card = find.byType(ReelCard).first;
    expect(tester.widget<ReelCard>(card).reel.id, 'landed');
    expect(tester.widget<ReelCard>(card).isActive, isTrue);
    expect(
      tester.getRect(card),
      tester.getRect(find.byType(ReelDetailScreen)),
      reason: 'a full-bleed feed page, no bar above it',
    );
    expect(find.byTooltip('Back'), findsOneWidget);

    gate.complete();
    await tester.pump();
    await tester.pump();

    expect(shownIds(tester), ['landed', 'r1', 'r2']);
    expect(
      tester.widget<ReelCard>(find.byType(ReelCard).first).reel.id,
      'landed',
    );
  });

  testWidgets('a failed related page keeps the landed reel on screen', (
    tester,
  ) async {
    reelsRepository.related = left(const NetworkExceptions.server('boom'));

    await pumpLanding(tester);

    expect(shownIds(tester), ['landed']);
    expect(find.byType(SmErrorView), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('a reel that is gone keeps its message, and back leaves it', (
    tester,
  ) async {
    reelsRepository.detail = left(const NetworkExceptions.notFound());

    await pumpLanding(tester);

    expect(find.text('This reel is no longer available.'), findsOneWidget);
    expect(find.byType(ReelsPager), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('any other failure says the reel could not load', (tester) async {
    reelsRepository.detail = left(const NetworkExceptions.server('boom'));

    await pumpLanding(tester);

    expect(find.text("Couldn't load this reel."), findsOneWidget);
  });
}
