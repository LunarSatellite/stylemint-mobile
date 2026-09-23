import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_like_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/reel_share.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/creator_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_share_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class _MockCartRepository extends Mock implements CartRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockProfileNotifier extends Mock implements ProfileNotifier {}

class _MockRoleNotifier extends Mock implements RoleNotifier {}

class _MockAccountNotifier extends Mock implements AccountNotifier {}

class _MockCartNotifier extends Mock implements CartNotifier {}

class _MockFollowApi extends Mock implements FollowApi {}

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
        followNotifier: FollowNotifier(_MockFollowApi()),
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
  Future<List<String>> followingIds({int pageSize = 200}) async =>
      const <String>[];

  @override
  Future<FollowStats> stats(String accountId) => throw UnimplementedError();
}

class _FakeReelsRepository implements ReelsRepository {
  final likeCalls = <String>[];
  final unlikeCalls = <String>[];
  bool fail = false;

  Either<NetworkExceptions, ReelLikeResult> _answer({
    required bool liked,
    required int count,
  }) => fail
      ? left(const NetworkExceptions.server('boom'))
      : right(ReelLikeResult(liked: liked, likeCount: count));

  @override
  Future<Either<NetworkExceptions, ReelLikeResult>> likeReel(
    String reelId,
  ) async {
    likeCalls.add(reelId);
    return _answer(liked: true, count: 129);
  }

  @override
  Future<Either<NetworkExceptions, ReelLikeResult>> unlikeReel(
    String reelId,
  ) async {
    unlikeCalls.add(reelId);
    return _answer(liked: false, count: 127);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _zero = Money(amount: 0, currency: 'NPR');

const _tote = TaggedProductEntity(
  id: 'prod-1',
  name: 'Nomad Canvas Tote',
  imageUrl: '',
  price: Money(amount: 1800, currency: 'NPR'),
  quantity: 1,
);

Cart _cart(int quantity, {String productId = 'prod-9'}) => Cart(
  id: 'cart-1',
  items: [
    if (quantity > 0)
      CartItem(
        id: 'line-1',
        productId: productId,
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
  bool? liked,
  int likes = 128,
  int comments = 24,
  int shares = 9,
}) => Reel(
  id: 'reel-1',
  sourceUrl: 'https://www.tiktok.com/@sumendra/video/1',
  thumbnailUrl: '',
  creatorId: 'creator-1',
  creatorName: 'Sumendra',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: products,
  likeCount: likes,
  commentCount: comments,
  shareCount: shares,
  createdAt: DateTime(2026, 9, 14),
  isCreatorFollowed: followed,
  isLikedByMe: liked,
);

/// The rail's heart icon.
ReelRailIcon _heart(WidgetTester tester) => tester.widget<ReelRailIcon>(
  find.byWidgetPredicate(
    (widget) =>
        widget is ReelRailIcon &&
        (widget.svg == ReelRailIcons.heart ||
            widget.svg == ReelRailIcons.heartFilled),
  ),
);

void main() {
  late _MockCartRepository cartRepository;
  late _FakeFollowApi followApi;
  late _FakeReelsRepository reelsRepository;

  setUp(() {
    cartRepository = _MockCartRepository();
    followApi = _FakeFollowApi();
    reelsRepository = _FakeReelsRepository();
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
        GoRoute(
          path: RouteNames.signInMethod,
          builder: (_, _) => const Text('Sign in'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartRepositoryProvider.overrideWithValue(cartRepository),
          followApiProvider.overrideWithValue(followApi),
          reelsRepositoryProvider.overrideWithValue(reelsRepository),
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

  testWidgets("share opens StyleMint's sheet with the reel's StyleMint link", (
    tester,
  ) async {
    await pumpRail(tester, _reel(), signedIn: true);

    await tester.tap(find.bySemanticsLabel('Share, 9'));
    await tester.pumpAndSettle();

    expect(find.text(ReelShareSheet.title), findsOneWidget);
    expect(find.text(ReelShare.link('reel-1').toString()), findsOneWidget);
    expect(find.text(ReelShareSheet.copyLabel), findsOneWidget);
  });

  testWidgets('hides like, comment and share counts while they are zero', (
    tester,
  ) async {
    await pumpRail(tester, _reel(likes: 0, comments: 0, shares: 3));

    expect(find.bySemanticsLabel('Like'), findsOneWidget);
    expect(find.bySemanticsLabel('Comments'), findsOneWidget);
    expect(find.bySemanticsLabel('Share, 3'), findsOneWidget);
    expect(find.text('0'), findsNothing);
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

  testWidgets('the heart is a white outline until the reel is liked', (
    tester,
  ) async {
    await pumpRail(tester, _reel(liked: false));

    final heart = _heart(tester);
    expect(heart.svg, ReelRailIcons.heart);
    expect(heart.color, DesignTokens.textWhite);
    expect(find.bySemanticsLabel('Like, 128'), findsOneWidget);
  });

  testWidgets('a reel the viewer liked shows the filled red heart', (
    tester,
  ) async {
    await pumpRail(tester, _reel(liked: true));

    final heart = _heart(tester);
    expect(heart.svg, ReelRailIcons.heartFilled);
    expect(heart.color, ReelRailStyle.liked);
    expect(heart.color, const Color(0xFFFF3B5C));
    expect(find.bySemanticsLabel('Liked, 128'), findsOneWidget);
  });

  testWidgets('tapping the heart likes the reel on StyleMint', (tester) async {
    await pumpRail(tester, _reel(liked: false), signedIn: true);

    await tester.tap(find.bySemanticsLabel('Like, 128'));
    await tester.pumpAndSettle();

    expect(reelsRepository.likeCalls, ['reel-1']);
    expect(_heart(tester).svg, ReelRailIcons.heartFilled);
    expect(find.bySemanticsLabel('Liked, 129'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Liked, 129'));
    await tester.pumpAndSettle();

    expect(reelsRepository.unlikeCalls, ['reel-1']);
    expect(_heart(tester).svg, ReelRailIcons.heart);
    expect(find.bySemanticsLabel('Like, 127'), findsOneWidget);
  });

  testWidgets('a failed like rolls the heart back and says so', (
    tester,
  ) async {
    reelsRepository.fail = true;
    await pumpRail(tester, _reel(liked: false), signedIn: true);

    await tester.tap(find.bySemanticsLabel('Like, 128'));
    await tester.pumpAndSettle();

    expect(_heart(tester).svg, ReelRailIcons.heart);
    expect(find.bySemanticsLabel('Like, 128'), findsOneWidget);
    expect(
      find.text("Couldn't update your like. Please try again."),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a guest is asked to sign in and nothing is liked', (
    tester,
  ) async {
    await pumpRail(tester, _reel());

    await tester.tap(find.bySemanticsLabel('Like, 128'));
    await tester.pumpAndSettle();

    expect(reelsRepository.likeCalls, isEmpty);
    expect(find.text('Sign in to like'), findsOneWidget);
    expect(_heart(tester).svg, ReelRailIcons.heart);
  });

  testWidgets('the like pop does not throw with reduced motion', (
    tester,
  ) async {
    await pumpRail(tester, _reel(), signedIn: true, disableAnimations: true);

    await tester.tap(find.bySemanticsLabel('Like, 128'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Liked, 129'), findsOneWidget);
  });

  group('cart feedback on the rail', () {
    /// Records the haptic types the rail asks for.
    List<Object?> recordHaptics(WidgetTester tester) {
      final haptics = <Object?>[];
      final messenger = tester.binding.defaultBinaryMessenger
        ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      return haptics;
    }

    void stubAdd(Cart result) {
      when(
        () => cartRepository.addToCart(
          productId: any(named: 'productId'),
          quantity: any(named: 'quantity'),
          variantId: any(named: 'variantId'),
          reelTagContextId: any(named: 'reelTagContextId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => right(result));
    }

    CartNotifier cartNotifier(WidgetTester tester) => ProviderScope.containerOf(
      tester.element(find.byType(ReelActions)),
    ).read(cartNotifierProvider.notifier);

    testWidgets('the product tile shows the cart count while its product is '
        'not in the cart', (tester) async {
      when(
        () => cartRepository.getCart(),
      ).thenAnswer((_) async => right(_cart(2)));

      await pumpRail(tester, _reel(products: const [_tote]));

      expect(
        find.descendant(
          of: find.byKey(ReelRailProductTile.cartCountKey),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsNothing);
      expect(
        find.bySemanticsLabel('Shop Nomad Canvas Tote, Rs 1,800'),
        findsOneWidget,
      );
    });

    testWidgets('a loaded cart holding the product shows it in cart without '
        'celebrating', (tester) async {
      final haptics = recordHaptics(tester);
      when(
        () => cartRepository.getCart(),
      ).thenAnswer((_) async => right(_cart(1, productId: 'prod-1')));

      await pumpRail(tester, _reel(products: const [_tote]));

      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsOneWidget);
      expect(
        find.bySemanticsLabel('Shop Nomad Canvas Tote, Rs 1,800, in cart'),
        findsOneWidget,
      );
      expect(haptics, isEmpty);
    });

    testWidgets('adding the tagged product celebrates on the tile', (
      tester,
    ) async {
      final haptics = recordHaptics(tester);
      stubAdd(_cart(1, productId: 'prod-1'));
      await pumpRail(tester, _reel(products: const [_tote]));

      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsNothing);
      expect(haptics, isEmpty);

      // However it gets there — here straight through the cart notifier, as
      // the tagged-product card does.
      await cartNotifier(tester).addItem(
        productId: 'prod-1',
        quantity: 1,
        idempotencyKey: 'reel-atc-test',
      );
      await tester.pump();

      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsOneWidget);
      expect(
        find.bySemanticsLabel('Shop Nomad Canvas Tote, Rs 1,800, in cart'),
        findsOneWidget,
      );
      // The count shows on the tile; no "added" text anywhere.
      expect(
        find.descendant(
          of: find.byKey(ReelRailProductTile.inCartBadgeKey),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Added'), findsNothing);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        ['Added to cart'],
      );

      await tester.pumpAndSettle();
      expect(find.text('Rs 1.8K'), findsOneWidget);
      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsOneWidget);
      expect(haptics, hasLength(1));
    });

    testWidgets('adding to the cart pops the cart disc', (tester) async {
      final haptics = recordHaptics(tester);
      stubAdd(_cart(1));
      await pumpRail(tester, _reel());

      expect(find.bySemanticsLabel('Cart'), findsOneWidget);

      await cartNotifier(tester).addItem(
        productId: 'prod-9',
        quantity: 1,
        idempotencyKey: 'reel-atc-test',
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Cart, 1'), findsOneWidget);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      await tester.pumpAndSettle();
    });
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
