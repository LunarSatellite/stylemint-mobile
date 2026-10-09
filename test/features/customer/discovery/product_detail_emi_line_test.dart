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
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/product_emi_offer.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../smoke/fake_api_client.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

const _price = Money(amount: 25000, currency: 'NPR');

const _product = ProductDetail(
  id: 'p1',
  name: 'Hand-loomed pashmina overcoat',
  description: 'Woven in Kathmandu.',
  images: [],
  price: _price,
  rating: 4.8,
  reviewCount: 3,
  vendorId: 'v1',
  vendorName: 'Himalayan Weaves',
  vendorAvatarUrl: '',
  isInStock: true,
  variants: [],
  specifications: {},
  shippingInfo: '',
  isSaved: false,
  isInCart: false,
  defaultVariantId: 'sku-1',
);

Future<void> _pump(WidgetTester tester, ProductDetail product) async {
  final repository = _MockDiscoveryRepository();
  when(
    () => repository.getProductDetail(any()),
  ).thenAnswer((_) async => right(product));

  await tester.binding.setSurfaceSize(const Size(390, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
        productDetailNotifierProvider.overrideWith(
          (ref, id) => ProductDetailNotifier(repository),
        ),
      ],
      child: const MaterialApp(home: ProductDetailScreen(productId: 'p1')),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('an eligible variant shows "EMI from" under the price', (
    tester,
  ) async {
    await _pump(
      tester,
      _product.copyWith(
        emi: const ProductEmiOffer(
          minDownPaymentPercent: 30,
          tenures: [3, 6],
          variants: {'sku-1': EmiVariantTerms(price: _price, eligible: true)},
        ),
      ),
    );

    // 25,000 at 30 % down over 6 months.
    expect(find.text('EMI from Rs 2,917/month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no offer (a server older than EMI) shows nothing', (
    tester,
  ) async {
    await _pump(tester, _product);
    expect(find.textContaining('EMI from'), findsNothing);
  });

  testWidgets('an ineligible variant shows nothing', (tester) async {
    await _pump(
      tester,
      _product.copyWith(
        emi: const ProductEmiOffer(
          minDownPaymentPercent: 30,
          tenures: [3, 6],
          variants: {'sku-1': EmiVariantTerms(price: _price, eligible: false)},
        ),
      ),
    );
    expect(find.textContaining('EMI from'), findsNothing);
  });
}
