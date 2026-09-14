import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/account_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/creator_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_actions.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_button.dart';

class _MockCartRepository extends Mock implements CartRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockProfileNotifier extends Mock implements ProfileNotifier {}

class _MockRoleNotifier extends Mock implements RoleNotifier {}

class _MockAccountNotifier extends Mock implements AccountNotifier {}

class _MockCartNotifier extends Mock implements CartNotifier {}

/// Already signed in, so `ensureAuth` lets the action straight through.
class _SignedInSession extends SessionController {
  _SignedInSession()
    : super(
        authRepository: _MockAuthRepository(),
        tokenStorage: _MockTokenStorage(),
        profileNotifier: _MockProfileNotifier(),
        roleNotifier: _MockRoleNotifier(),
        accountNotifier: _MockAccountNotifier(),
        cartNotifier: _MockCartNotifier(),
      ) {
    state = const AuthSessionState.authenticated('viewer-1');
  }
}

class _FakeFollowApi implements FollowApi {
  final followed = <String>[];

  @override
  Future<void> follow(String followeeAccountId) async {
    followed.add(followeeAccountId);
  }

  @override
  Future<void> unfollow(String followeeAccountId) async {}

  @override
  Future<FollowStats> stats(String accountId) => throw UnimplementedError();
}

const _zero = Money(amount: 0, currency: 'NPR');

const _tote = TaggedProductEntity(
  id: 'prod-1',
  name: 'Nomad Canvas Tote',
  imageUrl: '',
  price: Money(amount: 1800, currency: 'NPR'),
  quantity: 1,
);

Cart _cart(int quantity) => Cart(
  id: 'cart-1',
  items: [
    if (quantity > 0)
      CartItem(
        id: 'line-1',
        productId: 'prod-9',
        productName: 'Linen shirt',
        productImageUrl: '',
        variantName: 'M',
        quantity: quantity,
        unitPrice: const Money(amount: 2500, currency: 'NPR'),
        isInStock: true,
      ),
  ],
  subtotal: _zero,
  shippingTotal: _zero,
  taxTotal: _zero,
  total: _zero,
);

Reel _reel({
  List<TaggedProductEntity> products = const [],
  bool? followed,
  String sourceUrl = 'https://www.tiktok.com/@sumendra/video/1',
}) => Reel(
  id: 'reel-1',
  sourceUrl: sourceUrl,
  thumbnailUrl: '',
  creatorId: 'creator-1',
  creatorName: 'Sumendra',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: products,
  likeCount: 128,
  commentCount: 24,
  shareCount: 9,
  createdAt: DateTime(2026, 9, 14),
  isCreatorFollowed: followed,
);

void main() {
  late _MockCartRepository cartRepository;
  late _FakeFollowApi followApi;

  setUp(() {
    cartRepository = _MockCartRepository();
    followApi = _FakeFollowApi();
    when(
      () => cartRepository.getCart(),
    ).thenAnswer((_) async => right(_cart(0)));
  });

  Future<void> pumpRail(
    WidgetTester tester,
    Reel reel, {
    bool signedIn = false,
    bool disableAnimations = false,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: ReelActions(reel: reel)),
          ),
        ),
        GoRoute(
          path: RouteNames.productDetail,
          builder: (_, state) =>
              Text('Product page ${state.pathParameters['productId']}'),
        ),
        GoRoute(
          path: RouteNames.creatorProfile,
          builder: (_, state) =>
              Text('Profile page ${state.pathParameters['accountId']}'),
        ),
        GoRoute(path: RouteNames.cart, builder: (_, _) => const Text('Cart')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartRepositoryProvider.overrideWithValue(cartRepository),
          followApiProvider.overrideWithValue(followApi),
          if (signedIn)
            sessionControllerProvider.overrideWith((ref) => _SignedInSession()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the creator, counts and the tagged product tile', (
    tester,
  ) async {
    await pumpRail(tester, _reel(products: const [_tote]));

    expect(find.bySemanticsLabel("Open Sumendra's profile"), findsOneWidget);
    expect(find.bySemanticsLabel('Follow Sumendra'), findsOneWidget);
    expect(find.byKey(ReelRailAvatar.followBadgeKey), findsOneWidget);
    expect(find.bySemanticsLabel('Like, 128'), findsOneWidget);
    expect(find.bySemanticsLabel('Comments, 24'), findsOneWidget);
    expect(find.bySemanticsLabel('Share, 9'), findsOneWidget);
    expect(find.text('Rs 1.8K'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Shop Nomad Canvas Tote, Rs 1,800'),
      findsOneWidget,
    );
    expect(find.byType(ReelRailCartDisc), findsNothing);
  });

  testWidgets('shows the cart disc with its item count when nothing is '
      'tagged', (tester) async {
    when(
      () => cartRepository.getCart(),
    ).thenAnswer((_) async => right(_cart(3)));

    await pumpRail(tester, _reel());

    expect(find.byType(ReelRailProductTile), findsNothing);
    expect(find.bySemanticsLabel('Cart, 3'), findsOneWidget);
  });

  testWidgets('the follow badge follows the creator and turns into a check', (
    tester,
  ) async {
    await pumpRail(tester, _reel(), signedIn: true);

    await tester.tap(find.bySemanticsLabel('Follow Sumendra'));
    await tester.pumpAndSettle();

    expect(followApi.followed, ['creator-1']);
    expect(find.byKey(ReelRailAvatar.followingBadgeKey), findsOneWidget);
    expect(find.bySemanticsLabel('Following Sumendra'), findsOneWidget);
  });

  testWidgets('the badge starts as a check for a followed creator', (
    tester,
  ) async {
    await pumpRail(tester, _reel(followed: true));

    expect(find.byKey(ReelRailAvatar.followingBadgeKey), findsOneWidget);
  });

  testWidgets('tapping the product tile opens the product page', (
    tester,
  ) async {
    await pumpRail(tester, _reel(products: const [_tote]));

    await tester.tap(find.byType(ReelRailProductTile));
    await tester.pumpAndSettle();

    expect(find.text('Product page prod-1'), findsOneWidget);
  });

  testWidgets('tapping the avatar opens the creator profile', (tester) async {
    await pumpRail(tester, _reel());

    await tester.tap(find.bySemanticsLabel("Open Sumendra's profile"));
    await tester.pumpAndSettle();

    expect(find.text('Profile page creator-1'), findsOneWidget);
  });

  testWidgets('the like pop does not throw with reduced motion', (
    tester,
  ) async {
    await pumpRail(tester, _reel(sourceUrl: ''), disableAnimations: true);

    await tester.tap(find.bySemanticsLabel('Like, 128'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Unable to open the source reel.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('CreatorInfo can leave the Follow pill to the rail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [followApiProvider.overrideWithValue(followApi)],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CreatorInfo(reel: _reel()),
                CreatorInfo(reel: _reel(), showFollow: false),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sumendra'), findsNWidgets(2));
    expect(find.text('Follow'), findsOneWidget);
  });
}
