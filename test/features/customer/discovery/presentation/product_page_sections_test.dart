import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_reason.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/account_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_review_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/delivery_estimate_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_reels_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/related_products_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/review_summary_block.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/datasources/saved_for_later_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saveable_product_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/saved_products_providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

import '../../reels/fake_reels_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockProfileNotifier extends Mock implements ProfileNotifier {}

class _MockRoleNotifier extends Mock implements RoleNotifier {}

class _MockAccountNotifier extends Mock implements AccountNotifier {}

class _MockCartNotifier extends Mock implements CartNotifier {}

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _Session extends SessionController {
  _Session({required bool signedIn})
    : super(
        authRepository: _MockAuthRepository(),
        tokenStorage: _MockTokenStorage(),
        profileNotifier: _MockProfileNotifier(),
        roleNotifier: _MockRoleNotifier(),
        accountNotifier: _MockAccountNotifier(),
        cartNotifier: _MockCartNotifier(),
      ) {
    state = signedIn
        ? const AuthSessionState.authenticated('viewer-1')
        : const AuthSessionState.unauthenticated();
  }
}

class _FakeInStoreRepository implements InStoreRepository {
  _FakeInStoreRepository(this.reels);

  final List<ProductReel> reels;

  @override
  Future<Either<NetworkExceptions, List<ProductReel>>> getProductReels(
    String productId,
  ) async => right(reels);

  @override
  Future<Either<NetworkExceptions, StoreProductsPage>> getVendorProducts(
    String vendorAccountId, {
    String? cursor,
  }) async => right((products: const <StoreProduct>[], nextCursor: null));
}

class _SummaryDataSource extends DiscoveryRemoteDataSource {
  _SummaryDataSource(this.summary) : super(apiClient: ApiClient(dio: Dio()));

  final ProductReviewSummary? summary;

  @override
  Future<ProductReviewSummary> getReviewSummary(String productId) async =>
      summary ?? (throw Exception('404'));
}

class _FakeSavedApi implements SavedForLaterApi {
  final List<(String, String)> saves = [];

  @override
  Future<List<SavedForLaterEntry>> list() async => const [];

  @override
  Future<SavedForLaterEntry> save({
    required String productId,
    required String variantId,
  }) async {
    saves.add((productId, variantId));
    return SavedForLaterEntry(
      savedItemId: 'saved-$productId',
      productId: productId,
      variantId: variantId,
    );
  }

  @override
  Future<void> remove(String savedItemId) async {}
}

const _reels = [
  ProductReel(
    id: 'r-1',
    permalink: 'https://www.instagram.com/reel/abc/',
    creatorName: 'Asha',
    caption: 'Linen days #AIgenerated',
    likeCount: 12,
  ),
  ProductReel(
    id: 'r-2',
    permalink: 'https://www.tiktok.com/@asha/video/2',
    creatorName: 'Asha',
    caption: 'Weekend fit',
  ),
];

const _summary = ProductReviewSummary(
  productId: 'p-1',
  averageRating: 4.4,
  ratingCount: 8,
  reviewCount: 1234,
  withPhotosCount: 3,
  distribution: {5: 4, 4: 2, 3: 1, 2: 1, 1: 0},
);

RelatedProduct _related(String id, {String name = 'Linen shirt'}) =>
    RelatedProduct(
      id: id,
      name: name,
      imageUrl: '',
      price: const Money(amount: 1500, currency: 'NPR'),
      rating: 4.5,
    );

const _shirt = MallProductVm(
  id: 'p-2',
  name: 'Linen shirt',
  price: Money(amount: 1500, currency: 'NPR'),
);

Widget _app(Widget child, {double textScale = 1}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [child],
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.reelDetail,
        builder: (_, state) => Text('reel ${state.pathParameters['reelId']}'),
      ),
      GoRoute(
        path: RouteNames.productDetail,
        builder: (_, state) =>
            Text('product ${state.pathParameters['productId']}'),
      ),
      GoRoute(
        path: RouteNames.signInMethod,
        builder: (_, _) => const Text('sign in'),
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    theme: AppTheme.dark,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: app ?? const SizedBox.shrink(),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget scope, {
  double width = 390,
}) async {
  tester.view
    ..physicalSize = Size(width, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(scope);
  await tester.pump();
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  late _MockDiscoveryRepository discovery;
  late _FakeSavedApi savedApi;

  setUp(() {
    discovery = _MockDiscoveryRepository();
    savedApi = _FakeSavedApi();
  });

  group('See it in reels', () {
    testWidgets('lists reels tagging the product and plays one in the window', (
      tester,
    ) async {
      addTearDown(ReelWindow.debugResetOpenState);
      await _pump(
        tester,
        ProviderScope(
          overrides: [
            inStoreRepositoryProvider.overrideWithValue(
              _FakeInStoreRepository(_reels),
            ),
            reelsRepositoryProvider.overrideWithValue(FakeReelsRepository()),
          ],
          child: _app(const ProductReelsRail(productId: 'p-1')),
        ),
      );

      expect(find.text(ProductReelsRail.title), findsOneWidget);
      final cards = tester.widgetList<MallReelCard>(find.byType(MallReelCard));
      expect(cards.map((c) => c.reel.id), ['r-1', 'r-2']);
      expect(cards.map((c) => c.reel.isAiGenerated), [true, false]);
      expect(find.text(MallStrings.english.aiGenerated), findsOneWidget);

      await tester.tap(find.byType(MallReelCard).first);
      await _settle(tester);
      // The window over the product page, not a push to the reel screen —
      // and r-1 is AI-generated, so the disclosure comes with it.
      expect(find.byType(ReelWindow), findsOneWidget);
      expect(find.byKey(ReelWindow.aiLabelKey), findsOneWidget);
      expect(find.text('reel r-1'), findsNothing);
    });

    testWidgets('is hidden when no reel tags the product', (tester) async {
      await _pump(
        tester,
        ProviderScope(
          overrides: [
            inStoreRepositoryProvider.overrideWithValue(
              _FakeInStoreRepository(const []),
            ),
          ],
          child: _app(const ProductReelsRail(productId: 'p-1')),
        ),
      );

      expect(find.text(ProductReelsRail.title), findsNothing);
      expect(find.byType(MallReelCard), findsNothing);
    });
  });

  group('review summary', () {
    testWidgets('shows the average, 5 → 1 bars and the photo chip', (
      tester,
    ) async {
      await _pump(
        tester,
        ProviderScope(
          child: _app(const ReviewSummaryView(summary: _summary)),
        ),
      );

      expect(find.text('4.4'), findsOneWidget);
      expect(find.text('1234 reviews'), findsOneWidget);
      expect(find.text(ReviewSummaryView.withPhotosLabel(3)), findsOneWidget);
      double bar(int stars) => tester
          .widget<FractionallySizedBox>(
            find.byKey(ReviewSummaryView.barKey(stars)),
          )
          .widthFactor!;
      expect(bar(5), 0.5);
      expect(bar(4), 0.25);
      expect(bar(1), 0);
    });

    testWidgets('says "No reviews yet" when nothing is reviewed', (
      tester,
    ) async {
      await _pump(
        tester,
        ProviderScope(
          child: _app(
            const ReviewSummaryView(
              summary: ProductReviewSummary(productId: 'p-1'),
            ),
          ),
        ),
      );

      expect(find.text(ReviewSummaryView.noReviewsLabel), findsOneWidget);
      expect(find.byKey(ReviewSummaryView.barKey(5)), findsNothing);
    });

    testWidgets('the block loads the summary and hides when it fails', (
      tester,
    ) async {
      await _pump(
        tester,
        ProviderScope(
          overrides: [
            discoveryRemoteDataSourceProvider.overrideWithValue(
              _SummaryDataSource(_summary),
            ),
          ],
          child: _app(const ReviewSummaryBlock(productId: 'p-1')),
        ),
      );
      expect(find.byKey(ReviewSummaryView.barKey(5)), findsOneWidget);

      await _pump(
        tester,
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            discoveryRemoteDataSourceProvider.overrideWithValue(
              _SummaryDataSource(null),
            ),
          ],
          child: _app(const ReviewSummaryBlock(productId: 'p-1')),
        ),
      );
      expect(find.byKey(ReviewSummaryView.barKey(5)), findsNothing);
      expect(find.text(ReviewSummaryView.noReviewsLabel), findsNothing);
    });
  });

  group('You may also like', () {
    testWidgets('shows skeletons, then saveable cards without the product', (
      tester,
    ) async {
      final pending =
          Completer<Either<NetworkExceptions, List<RelatedProduct>>>();
      when(
        () => discovery.getRelatedProducts('p-1'),
      ).thenAnswer((_) => pending.future);

      await _pump(
        tester,
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(discovery),
            savedProductsSignedInProvider.overrideWithValue(false),
            savedForLaterApiProvider.overrideWithValue(savedApi),
          ],
          child: _app(const RelatedProductsRail(productId: 'p-1')),
        ),
      );
      expect(find.text(RelatedProductsRail.title), findsOneWidget);
      expect(find.byType(SmSkeletonProductCard), findsWidgets);

      pending.complete(right([_related('p-1'), _related('p-2')]));
      await _settle(tester);

      expect(find.byType(SmSkeletonProductCard), findsNothing);
      final cards = tester.widgetList<SaveableMallProductCard>(
        find.byType(SaveableMallProductCard),
      );
      expect(cards.map((c) => c.product.id), ['p-2']);

      await tester.tap(find.text('Linen shirt'));
      await _settle(tester);
      expect(find.text('product p-2'), findsOneWidget);
    });

    testWidgets('is hidden when nothing is related', (tester) async {
      when(
        () => discovery.getRelatedProducts('p-1'),
      ).thenAnswer((_) async => right(const <RelatedProduct>[]));

      await _pump(
        tester,
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(discovery),
            savedProductsSignedInProvider.overrideWithValue(false),
          ],
          child: _app(const RelatedProductsRail(productId: 'p-1')),
        ),
      );
      await _settle(tester);

      expect(find.text(RelatedProductsRail.title), findsNothing);
    });
  });

  testWidgets('the delivery line falls back from transit to processing time', (
    tester,
  ) async {
    await _pump(
      tester,
      ProviderScope(
        child: _app(
          const Column(
            children: [
              DeliveryEstimateLine(
                delivery: ProductDelivery(
                  processingTimeDays: 2,
                  shippingOptions: [
                    ProductShippingOption(
                      kind: ShippingOptionKind.standard,
                      estimatedDaysMin: 1,
                      estimatedDaysMax: 3,
                    ),
                  ],
                ),
              ),
              DeliveryEstimateLine(
                delivery: ProductDelivery(processingTimeDays: 2),
              ),
              DeliveryEstimateLine(delivery: ProductDelivery()),
              DeliveryEstimateLine(delivery: null),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Delivers in 3–5 days'), findsOneWidget);
    expect(find.text('Ships in 2 days'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping_outlined), findsNWidgets(2));
  });

  group('save heart', () {
    Widget twoScreens() => const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MallProductCard.compactWidth,
          child: SaveableMallProductCard(
            product: _shirt,
            size: MallCardSize.compact,
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: MallProductCard.compactWidth,
          child: SaveableMallProductCard(
            product: _shirt,
            size: MallCardSize.compact,
          ),
        ),
      ],
    );

    testWidgets('fills for a signed-in viewer, on every card of the product', (
      tester,
    ) async {
      await _pump(
        tester,
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(
              (ref) => _Session(signedIn: true),
            ),
            savedForLaterApiProvider.overrideWithValue(savedApi),
            savedProductsVariantResolverProvider.overrideWithValue(
              (_) async => 'shirt-m',
            ),
          ],
          child: _app(twoScreens()),
        ),
      );
      final hearts = find.byType(MallSaveButton);
      expect(
        tester.widgetList<MallSaveButton>(hearts).map((b) => b.isSaved),
        [false, false],
      );

      await tester.tap(hearts.first);
      await _settle(tester);

      expect(savedApi.saves, [('p-2', 'shirt-m')]);
      expect(
        tester.widgetList<MallSaveButton>(hearts).map((b) => b.isSaved),
        [true, true],
      );
    });

    testWidgets('asks a guest to sign in and saves nothing', (tester) async {
      await _pump(
        tester,
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(
              (ref) => _Session(signedIn: false),
            ),
            savedForLaterApiProvider.overrideWithValue(savedApi),
          ],
          child: _app(twoScreens()),
        ),
        // The shared sign-in sheet needs a wider screen than a phone with the
        // test font.
        width: 800,
      );

      await tester.tap(find.byType(MallSaveButton).first);
      await _settle(tester);

      expect(find.text(AuthReason.save.prompt), findsOneWidget);
      expect(savedApi.saves, isEmpty);
      expect(
        tester
            .widgetList<MallSaveButton>(find.byType(MallSaveButton))
            .map((b) => b.isSaved),
        [false, false],
      );
    });
  });

  testWidgets('the new sections fit 320 wide at 1.3× text', (tester) async {
    when(
      () => discovery.getRelatedProducts('p-1'),
    ).thenAnswer((_) async => right([_related('p-2'), _related('p-3')]));

    await _pump(
      tester,
      ProviderScope(
        overrides: [
          inStoreRepositoryProvider.overrideWithValue(
            _FakeInStoreRepository(_reels),
          ),
          discoveryRepositoryProvider.overrideWithValue(discovery),
          discoveryRemoteDataSourceProvider.overrideWithValue(
            _SummaryDataSource(_summary),
          ),
          savedProductsSignedInProvider.overrideWithValue(false),
          savedForLaterApiProvider.overrideWithValue(savedApi),
        ],
        child: _app(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DeliveryEstimateLine(
                delivery: ProductDelivery(
                  processingTimeDays: 12,
                  shippingOptions: [
                    ProductShippingOption(
                      kind: ShippingOptionKind.express,
                      estimatedDaysMin: 1,
                      estimatedDaysMax: 30,
                    ),
                  ],
                ),
              ),
              ReviewSummaryBlock(productId: 'p-1'),
              ProductReelsRail(productId: 'p-1'),
              RelatedProductsRail(productId: 'p-1'),
            ],
          ),
          textScale: 1.3,
        ),
      ),
      width: 320,
    );
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(ProductReelsRail.title), findsOneWidget);
    expect(find.text(RelatedProductsRail.title), findsOneWidget);
    expect(find.byKey(ReviewSummaryView.barKey(5)), findsOneWidget);
  });
}
