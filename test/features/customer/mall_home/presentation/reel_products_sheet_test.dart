import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/account_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/mall_home_page.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/reel_products_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../mall_test_support.dart';

class _MockCartRepository extends Mock implements CartRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockProfileNotifier extends Mock implements ProfileNotifier {}

class _MockRoleNotifier extends Mock implements RoleNotifier {}

class _MockAccountNotifier extends Mock implements AccountNotifier {}

class _MockCartNotifier extends Mock implements CartNotifier {}

class _MockFollowApi extends Mock implements FollowApi {}

/// Already signed in, so add to cart goes straight through.
class _SignedInSession extends SessionController {
  _SignedInSession()
    : super(
        authRepository: _MockAuthRepository(),
        tokenStorage: _MockTokenStorage(),
        profileNotifier: _MockProfileNotifier(),
        roleNotifier: _MockRoleNotifier(),
        accountNotifier: _MockAccountNotifier(),
        cartNotifier: _MockCartNotifier(),
        followNotifier: FollowNotifier(_MockFollowApi()),
      ) {
    state = const AuthSessionState.authenticated('viewer-1');
  }
}

class _FakeReelsRepository implements ReelsRepository {
  _FakeReelsRepository(this.detail);

  Either<NetworkExceptions, Reel> detail;
  final List<String> requested = [];

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async {
    requested.add(reelId);
    return detail;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _zero = Money(amount: 0, currency: 'NPR');
const _emptyCart = Cart(
  id: 'cart',
  items: [],
  subtotal: _zero,
  shippingTotal: _zero,
  taxTotal: _zero,
  total: _zero,
);

Reel _detail() => Reel(
  id: 'r-ai',
  sourceUrl: '',
  thumbnailUrl: '',
  creatorId: 'a-1',
  creatorName: 'priya',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: [
    TaggedProductEntity(
      id: 'p-1',
      taggedProductId: 'tag-1',
      name: 'Oversized linen co-ord set in washed sand',
      imageUrl: '',
      price: rs(3499),
      quantity: 1,
    ),
    TaggedProductEntity(
      id: 'p-2',
      taggedProductId: 'tag-2',
      name: 'Canvas tote',
      imageUrl: '',
      price: rs(1800),
      quantity: 1,
    ),
  ],
  likeCount: 12,
  commentCount: 0,
  shareCount: 0,
  createdAt: DateTime(2026, 9, 15),
);

const _reelsOnly = MallHome(
  sections: [
    HomeReelsSection(
      id: 'shoppable-reels',
      title: 'Shoppable reels',
      items: [
        HomeReel(
          id: 'r-ai',
          creatorName: 'Priya',
          hook: 'Weekend linen',
          taggedProductCount: 2,
          isAiGenerated: true,
          likeCount: 12,
        ),
      ],
    ),
  ],
);

void main() {
  late _MockCartRepository cart;
  late _FakeReelsRepository reels;

  setUp(() {
    cart = _MockCartRepository();
    reels = _FakeReelsRepository(right(_detail()));
    when(() => cart.getCart()).thenAnswer((_) async => right(_emptyCart));
    when(
      () => cart.addToCart(
        productId: any(named: 'productId'),
        quantity: any(named: 'quantity'),
        variantId: any(named: 'variantId'),
        reelTagContextId: any(named: 'reelTagContextId'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => right(_emptyCart));
  });

  Future<void> openSheet(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1,
  }) async {
    await pumpMallApp(
      tester,
      location: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: MallHomePage()),
        ),
      ],
      overrides: [
        mallHomeRepositoryProvider.overrideWithValue(
          FakeMallHomeRepository([right(_reelsOnly)]),
        ),
        mallViewerSignedInProvider.overrideWithValue(true),
        mallClockProvider.overrideWithValue(mallTestNow),
        reelsRepositoryProvider.overrideWithValue(reels),
        cartRepositoryProvider.overrideWithValue(cart),
        sessionControllerProvider.overrideWith((ref) => _SignedInSession()),
      ],
      width: width,
      textScale: textScale,
    );
    // The reel card's product pill opens the sheet, not the reel.
    await tester.tap(find.text('2 products'));
    await settleTransition(tester);
  }

  testWidgets("the product pill opens the reel's tagged products", (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.byType(ReelProductsSheet), findsOneWidget);
    expect(reels.requested, ['r-ai']);
    expect(find.text('SHOP THE REEL'), findsOneWidget);
    expect(find.text('Weekend linen'), findsOneWidget);
    expect(find.text('Canvas tote'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ReelProductsSheet),
        matching: find.text('AI-generated'),
      ),
      findsOneWidget,
    );
    expect(find.text('reel:r-ai'), findsNothing);
  });

  testWidgets('add to cart keeps the reel attribution', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Add').first);
    await tester.pump();
    await tester.pump();

    verify(
      () => cart.addToCart(
        productId: any(named: 'productId', that: equals('p-1')),
        quantity: any(named: 'quantity', that: equals(1)),
        variantId: any(named: 'variantId'),
        reelTagContextId: any(named: 'reelTagContextId', that: equals('tag-1')),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(1);
    expect(find.byType(ReelProductsSheet), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    reels.detail = left(const NetworkExceptions.serverUnavailable());
    await openSheet(tester);

    expect(find.text("Couldn't load this reel's products."), findsOneWidget);
    reels.detail = right(_detail());
    await tester.tap(find.text('Tap to retry'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Canvas tote'), findsOneWidget);
  });

  testWidgets('Watch the reel closes the sheet and opens the reel', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('Watch the reel'));
    await settleTransition(tester);
    expect(find.byType(ReelProductsSheet), findsNothing);
    expect(find.text('reel:r-ai'), findsOneWidget);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('sheet fits at ${width.toInt()}dp, text ×1.3', (tester) async {
      await openSheet(tester, width: width, textScale: 1.3);
      expect(find.byType(ReelProductsSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
