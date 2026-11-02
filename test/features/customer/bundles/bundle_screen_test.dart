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
import 'package:stylemint_mobile_frontend/features/customer/bundles/bundle_customer_routes.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundle_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundles_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_routes.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';

import 'bundle_fixtures.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockProfileNotifier extends Mock implements ProfileNotifier {}

class _MockRoleNotifier extends Mock implements RoleNotifier {}

class _MockAccountNotifier extends Mock implements AccountNotifier {}

class _MockCartNotifier extends Mock implements CartNotifier {}

class _MockFollowApi extends Mock implements FollowApi {}

class _MockCartRepository extends Mock implements CartRepository {}

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

class _FakeBundlesApi implements BundlesApi {
  Either<BundleFailure, BundleDetail> detail = right(
    readBundleDetail(bundleDetailWire()),
  );
  Either<BundleFailure, Cart>? addResult;
  final adds = <Map<String, Object?>>[];
  int gets = 0;

  @override
  Future<Either<BundleFailure, BundleDetail>> getBundle(String bundleId) async {
    gets++;
    return detail;
  }

  @override
  Future<Either<BundleFailure, List<BundleCard>>> list(BundleListKey key) async =>
      right(const []);

  @override
  Future<Either<BundleFailure, List<ReelTaggedBundle>>> reelBundles(
    String reelId,
  ) async => right(const []);

  @override
  Future<Either<BundleFailure, Cart>> addToCart({
    required String bundleId,
    required int termsVersion,
    required Map<String, String> variants,
    required String idempotencyKey,
    int quantity = 1,
    String? taggedBundleId,
    String? affiliateCode,
  }) async {
    adds.add({
      'bundleId': bundleId,
      'termsVersion': termsVersion,
      'variants': Map<String, String>.of(variants),
      'taggedBundleId': taggedBundleId,
      'key': idempotencyKey,
    });
    return addResult ??
        right(CartDto.fromJson(bundleCartWire()).toDomain());
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeBundlesApi api, {
  String location = '/bundles/b-1?t=tb-9',
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final cartRepo = _MockCartRepository();
  when(() => cartRepo.getCart()).thenAnswer(
    (_) async => right(CartDto.fromJson(bundleCartWire()).toDomain()),
  );
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ...bundleCustomerRoutes,
      GoRoute(path: '/cart', builder: (_, _) => const Text('Cart page')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bundlesApiProvider.overrideWithValue(api),
        cartRepositoryProvider.overrideWithValue(cartRepo),
        sessionControllerProvider.overrideWith((ref) => _SignedInSession()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('items are grouped by shop with list and bundle prices', (
    tester,
  ) async {
    await _pump(tester, _FakeBundlesApi());

    expect(find.text('Trekking kit'), findsOneWidget);
    expect(find.text('Picked by @asha'), findsOneWidget);
    expect(find.byKey(BundleScreen.shopKey('v-peak')), findsOneWidget);
    expect(find.byKey(BundleScreen.shopKey('v-sock')), findsOneWidget);
    expect(find.text('Ships separately'), findsNWidgets(2));
    final total = tester.widget<Text>(find.byKey(BundleScreen.totalKey));
    expect(total.data, 'Rs 11,700');
    final list = tester.widget<Text>(find.byKey(BundleScreen.listTotalKey));
    expect(list.data, 'Rs 13,000');
    expect(find.text('Save Rs 1,300'), findsOneWidget);
  });

  testWidgets('picking a variant re-prices the bundle; a sold-out one '
      'cannot be picked', (tester) async {
    await _pump(tester, _FakeBundlesApi());

    await tester.tap(find.byKey(BundleScreen.variantKey('bi-jacket', 'v-jacket-l')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(BundleScreen.totalKey)).data,
      'Rs 12,600',
    );

    final xl = tester.widget<ChoiceChip>(
      find.byKey(BundleScreen.variantKey('bi-jacket', 'v-jacket-xl')),
    );
    expect(xl.onSelected, isNull);
  });

  testWidgets('Add bundle to cart sends every pick, the terms version and '
      'the reel tag', (tester) async {
    final api = _FakeBundlesApi();
    await _pump(tester, api);

    await tester.tap(find.byKey(BundleScreen.variantKey('bi-jacket', 'v-jacket-l')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BundleScreen.addKey));
    await tester.pumpAndSettle();

    expect(api.adds, hasLength(1));
    final add = api.adds.single;
    expect(add['bundleId'], 'b-1');
    expect(add['termsVersion'], 3);
    expect(add['taggedBundleId'], 'tb-9');
    expect(add['variants'], {'bi-jacket': 'v-jacket-l', 'bi-socks': 'v-socks'});
    expect(find.textContaining('Added "Trekking kit"'), findsOneWidget);
  });

  testWidgets('changed terms reload the bundle and say so', (tester) async {
    final api = _FakeBundlesApi()
      ..addResult = left(
        const BundleFailure(
          BundleFailureKind.conflict,
          code: 'bundle_terms_changed',
        ),
      );
    await _pump(tester, api);
    final before = api.gets;

    await tester.tap(find.byKey(BundleScreen.addKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('This bundle just changed'), findsOneWidget);
    expect(api.gets, greaterThan(before));
  });

  testWidgets('an unavailable bundle says why and cannot be added', (
    tester,
  ) async {
    final api = _FakeBundlesApi()
      ..detail = right(
        readBundleDetail(
          bundleDetailWire(purchasable: false, reason: 'item_out_of_stock'),
        ),
      );
    await _pump(tester, api);

    expect(find.byKey(BundleScreen.unavailableKey), findsOneWidget);
    expect(find.textContaining('out of stock'), findsWidgets);
    final add = tester.widget<FilledButton>(find.byKey(BundleScreen.addKey));
    expect(add.onPressed, isNull);
    expect(find.text('Not available'), findsOneWidget);
  });

  testWidgets('a bare 404 shows "not available", not an error', (
    tester,
  ) async {
    final api = _FakeBundlesApi()
      ..detail = left(const BundleFailure(BundleFailureKind.notFound));
    await _pump(tester, api);

    expect(find.byKey(BundleScreen.notFoundKey), findsOneWidget);
    expect(find.byKey(BundleScreen.addKey), findsNothing);
  });

  test('the route is a bundle page', () {
    expect(BundleRoutes.detail, '/bundles/:bundleId');
  });
}
