import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/entities/store_actions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/repositories/store_actions_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/presentation/screens/vendor_store_actions_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

class _MockStoreActionsRepository extends Mock
    implements StoreActionsRepository {}

const _soldOut = StoreAction(
  kind: StoreActionKind.soldOutWhileSelling,
  severity: StoreActionSeverity.high,
  productId: 'product-1',
  productName: 'Linen shirt',
  sku: 'LS-M',
  recommendation:
      'Restock Linen shirt (LS-M): it sold out while it was still selling.',
  evidence: ['12 sold in the last 7 days', '0 left in stock'],
  valueAtStake: Money(amount: 9600, currency: 'NPR'),
);

const _photos = StoreAction(
  kind: StoreActionKind.addProductImages,
  severity: StoreActionSeverity.medium,
  productId: 'product-2',
  productName: 'Canvas tote',
  recommendation: 'Add photos to Canvas tote: it is live with no images.',
  evidence: ['Live product', '0 photos'],
);

const _slow = StoreAction(
  kind: StoreActionKind.slowMovingStock,
  severity: StoreActionSeverity.low,
  productId: 'product-3',
  productName: 'Wool coat',
  recommendation:
      'Consider a promotion for Wool coat: 40 in stock and none sold in 30 '
      'days.',
  valueAtStake: Money(amount: 120000, currency: 'NPR'),
);

const _queue = StoreActionQueue(actions: [_soldOut, _photos, _slow]);

void main() {
  late _MockStoreActionsRepository repository;

  setUp(() => repository = _MockStoreActionsRepository());

  void stub(Either<NetworkExceptions, StoreActionQueue> result) {
    when(
      () => repository.getStoreActions(),
    ).thenAnswer((_) async => result);
  }

  Future<GoRouter> pumpScreen(WidgetTester tester, {bool settle = true}) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: RouteNames.vendorStoreActions,
      routes: [
        GoRoute(
          path: RouteNames.vendorStoreActions,
          builder: (_, _) => const VendorStoreActionsScreen(),
        ),
        GoRoute(
          path: RouteNames.vendorEditProductImages,
          builder: (_, state) =>
              Scaffold(body: Text('images for ${state.extra}')),
        ),
        GoRoute(
          path: RouteNames.vendorEditProduct,
          builder: (_, state) => Scaffold(
            body: Text('editing ${state.pathParameters['productId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeActionsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return router;
  }

  testWidgets('shows the brand page loader while loading', (tester) async {
    final pending = Completer<Either<NetworkExceptions, StoreActionQueue>>();
    when(() => repository.getStoreActions()).thenAnswer((_) => pending.future);

    await pumpScreen(tester, settle: false);

    expect(find.byType(SmPageLoader), findsOneWidget);
    expect(find.text('Store to-do'), findsOneWidget);

    pending.complete(right(_queue));
    await tester.pumpAndSettle();
    expect(find.byType(SmPageLoader), findsNothing);
  });

  testWidgets(
    'lists actions in ranked order with severity, message and evidence',
    (tester) async {
      stub(right(_queue));

      await pumpScreen(tester);

      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('Soon'), findsOneWidget);
      expect(find.text('When you can'), findsOneWidget);
      expect(find.text(_soldOut.recommendation), findsOneWidget);
      expect(find.text(_photos.recommendation), findsOneWidget);
      expect(find.text(_slow.recommendation), findsOneWidget);
      expect(find.text('SKU LS-M'), findsOneWidget);
      expect(
        find.text('12 sold in the last 7 days · 0 left in stock'),
        findsOneWidget,
      );
      expect(find.text('Sales at risk: Rs 9,600.00'), findsOneWidget);
      expect(find.text('Stock sitting unsold: Rs 120,000.00'), findsOneWidget);
      expect(find.text('Update stock'), findsOneWidget);
      expect(find.text('Add photos'), findsOneWidget);
      expect(find.text('Edit product'), findsOneWidget);

      double topOf(int index) =>
          tester.getTopLeft(find.byKey(ValueKey('store-action-$index'))).dy;
      expect(topOf(0), lessThan(topOf(1)));
      expect(topOf(1), lessThan(topOf(2)));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('store-action-0')),
          matching: find.text('Linen shirt'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Update stock opens the product editor and re-checks on return', (
    tester,
  ) async {
    stub(right(_queue));
    final router = await pumpScreen(tester);

    await tester.tap(find.text('Update stock'));
    await tester.pumpAndSettle();
    expect(find.text('editing product-1'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('Linen shirt'), findsOneWidget);
    verify(() => repository.getStoreActions()).called(2);
  });

  testWidgets('Returns rising shows its label and opens the product editor', (
    tester,
  ) async {
    const returns = StoreAction(
      kind: StoreActionKind.returnsRising,
      severity: StoreActionSeverity.medium,
      productId: 'product-4',
      productName: 'Wool coat',
      recommendation:
          'Look into returns for Wool coat: read the return reasons and '
          'check the photos and description.',
      evidence: ['6 of 20 sold in the last 30 days came back (30%)'],
    );
    stub(right(const StoreActionQueue(actions: [returns])));

    await pumpScreen(tester);

    expect(find.text('Returns rising'), findsOneWidget);
    expect(find.text('Soon'), findsOneWidget);
    expect(find.text(returns.recommendation), findsOneWidget);
    expect(
      find.text('6 of 20 sold in the last 30 days came back (30%)'),
      findsOneWidget,
    );
    expect(find.textContaining('At stake'), findsNothing);

    await tester.tap(find.text('Edit product'));
    await tester.pumpAndSettle();

    expect(find.text('editing product-4'), findsOneWidget);
  });

  testWidgets('Add photos opens the image editor for that product', (
    tester,
  ) async {
    stub(right(_queue));
    await pumpScreen(tester);

    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();

    expect(find.text('images for product-2'), findsOneWidget);
  });

  testWidgets('shows the all-clear state when there is nothing to do', (
    tester,
  ) async {
    stub(right(const StoreActionQueue(actions: [])));

    await pumpScreen(tester);

    expect(find.text('Nothing needs your attention right now'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('shows a retryable error and recovers on retry', (tester) async {
    stub(left(const NetworkExceptions.serverUnavailable()));

    await pumpScreen(tester);

    expect(find.text('Could not load your store to-do list.'), findsOneWidget);
    expect(find.text('Linen shirt'), findsNothing);

    stub(right(_queue));
    await tester.tap(find.text('Tap to retry'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your store to-do list.'), findsNothing);
    expect(find.text('Linen shirt'), findsOneWidget);
  });
}
