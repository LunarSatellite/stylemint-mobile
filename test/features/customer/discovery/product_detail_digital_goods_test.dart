import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/product_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../smoke/fake_api_client.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

const _base = ProductDetail(
  id: 'p1',
  name: 'Lightroom preset pack',
  description: 'Twelve presets.',
  images: [],
  price: Money(amount: 900, currency: 'NPR'),
  rating: 4.5,
  reviewCount: 12,
  vendorId: 'v1',
  vendorName: 'Himalayan Weaves',
  vendorAvatarUrl: '',
  isInStock: true,
  variants: [],
  specifications: {},
  shippingInfo: '',
  isSaved: false,
  isInCart: false,
);

/// A product page reachable by deep link: it must load and simply offer no
/// purchase action.
final _digital = _base.copyWith(productKind: ProductKinds.digital);
final _subscription = _base.copyWith(productKind: ProductKinds.subscription);
final _physical = _base.copyWith(productKind: ProductKinds.physical);

Future<void> _pump(
  WidgetTester tester,
  ProductDetail product, {
  required DigitalGoodsPolicy policy,
}) async {
  final repository = _MockDiscoveryRepository();
  when(
    () => repository.getProductDetail(any()),
  ).thenAnswer((_) async => right(product));

  await tester.binding.setSurfaceSize(const Size(390, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
        productDetailNotifierProvider.overrideWith(
          (ref, id) => ProductDetailNotifier(repository),
        ),
      ],
      child: MaterialApp(
        home: DigitalGoodsScope(
          policy: policy,
          child: const ProductDetailScreen(productId: 'p1'),
        ),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

const _blocked = DigitalGoodsPolicy.blockedBy(StoreBillingRule.googlePlay);
const _allowed = DigitalGoodsPolicy.allowed();

void main() {
  group('with digital goods blocked', () {
    testWidgets('a kind-2 page loads with no purchase action', (tester) async {
      await _pump(tester, _digital, policy: _blocked);

      expect(tester.takeException(), isNull);
      expect(find.text('Lightroom preset pack'), findsWidgets);
      expect(find.text('Add to Cart'), findsNothing);
      expect(find.text('Buy Now'), findsNothing);
      expect(find.text('Out of Stock'), findsNothing);
    });

    testWidgets('a kind-4 page offers no purchase action', (tester) async {
      await _pump(tester, _subscription, policy: _blocked);

      expect(tester.takeException(), isNull);
      expect(find.text('Add to Cart'), findsNothing);
      expect(find.text('Buy Now'), findsNothing);
    });

    testWidgets('it says why rather than showing a dead button', (
      tester,
    ) async {
      await _pump(tester, _digital, policy: _blocked);

      expect(find.textContaining('Not available for purchase'), findsOneWidget);
    });

    testWidgets('an in-cart digital product still cannot be bought', (
      tester,
    ) async {
      // A row left in the cart from before this build must not become a
      // checkout path on the product page.
      await _pump(
        tester,
        _digital.copyWith(isInCart: true),
        policy: _blocked,
      );

      expect(find.text('Buy Now'), findsNothing);
    });

    testWidgets('a physical page buys as before', (tester) async {
      await _pump(tester, _physical, policy: _blocked);

      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);
    });

    testWidgets('a page with no stated kind buys as before', (tester) async {
      await _pump(tester, _base, policy: _blocked);

      expect(find.text('Add to Cart'), findsOneWidget);
    });
  });

  group('with digital goods allowed', () {
    testWidgets('a kind-2 page buys as before', (tester) async {
      await _pump(tester, _digital, policy: _allowed);

      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);
      expect(find.textContaining('Not available for purchase'), findsNothing);
    });

    testWidgets('a kind-4 page buys as before', (tester) async {
      await _pump(tester, _subscription, policy: _allowed);

      expect(find.text('Add to Cart'), findsOneWidget);
    });
  });

  group('ProductDetail', () {
    test('isDigitalGood follows the stated kind', () {
      expect(_digital.isDigitalGood, isTrue);
      expect(_subscription.isDigitalGood, isTrue);
      expect(_physical.isDigitalGood, isFalse);
      expect(_base.isDigitalGood, isFalse);
    });

    test('copyWith keeps the kind when the variant chooser applies', () {
      // ProductOptionChooser.applyTo goes through copyWith; a dropped kind
      // there would re-open the purchase bar after a size is picked.
      expect(
        _digital.copyWith(isInStock: false).productKind,
        ProductKinds.digital,
      );
    });
  });
}
