import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/reel_quick_buy.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/tagged_products_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_item.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../smoke/fake_api_client.dart';
import 'services_fakes.dart';

const _stayTag = TaggedProductEntity(
  id: stayId,
  taggedProductId: 'tag-1',
  name: 'Hotel Barahi',
  imageUrl: '',
  price: Money(amount: 4500, currency: 'NPR'),
  quantity: 1,
  serviceType: ServiceItemType.stay,
  priceLabel: 'from Rs 4,500/night',
);

const _bankTag = TaggedProductEntity(
  id: loanId,
  taggedProductId: 'tag-2',
  name: 'Home Loan',
  imageUrl: '',
  price: Money(amount: 0, currency: 'NPR'),
  quantity: 1,
  serviceType: ServiceItemType.bank,
  addableToCart: false,
);

/// The reel's tag strip at `/host`, with the item page as a stand-in that
/// shows where it was opened.
Future<void> _pump(WidgetTester tester, Widget host) async {
  phoneSize(tester);
  final router = GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(path: '/host', builder: (_, _) => Scaffold(body: host)),
      GoRoute(
        path: RouteNames.productDetail,
        builder: (_, state) => Text('item:${state.uri}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await settle(tester);
}

class _PickerApiClient extends ApiClient {
  _PickerApiClient({this.pickerDeployed = true}) : super(dio: Dio());

  final bool pickerDeployed;
  final calls = <String>[];

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add(uri);
    if (uri == '/v1/tag-picker/items') {
      if (!pickerDeployed) {
        throw DioException(
          requestOptions: RequestOptions(path: uri),
          response: Response(
            requestOptions: RequestOptions(path: uri),
            statusCode: 404,
          ),
        );
      }
      return {
        'items': [
          {
            'productId': stayId,
            'name': 'Hotel Barahi',
            'vendorDisplayName': 'Barahi Group',
            'isService': true,
            'serviceType': 1,
            'displayPrice': {
              'amount': 4500,
              'currency': 'NPR',
              'label': 'from Rs 4,500/night',
            },
            'addableToCart': true,
          },
          {
            'productId': 'p1',
            'name': 'Scarf',
            'vendorDisplayName': 'Weaves',
            'isService': false,
            'displayPrice': {'amount': 1200, 'currency': 'NPR'},
          },
        ],
      };
    }
    return {
      'products': [
        {'productId': 'p1', 'name': 'Scarf', 'price': 1200, 'brandName': 'W'},
      ],
    };
  }
}

void main() {
  group('a service tag on a reel', () {
    testWidgets('shows its price label and opens the item page with the tag', (
      tester,
    ) async {
      await _pump(tester, const TaggedProductsSection(products: [_stayTag]));
      expect(
        tester.widget<Text>(find.byKey(Key('tag-service-price-$stayId'))).data,
        'from Rs 4,500/night',
      );
      await tester.tap(find.byKey(Key('tag-service-open-$stayId')));
      await settle(tester);
      expect(
        find.text(
          'item:${RouteNames.serviceItemPath(stayId, reelTagId: 'tag-1')}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a bank tag says Enquire', (tester) async {
      await _pump(tester, const TaggedProductsSection(products: [_bankTag]));
      expect(
        tester.widget<Text>(find.byKey(Key('tag-service-price-$loanId'))).data,
        'Enquire',
      );
    });

    testWidgets('the reel rail never quick-adds a service: it opens the page', (
      tester,
    ) async {
      bool? opened;
      await _pump(
        tester,
        Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () async =>
                opened = await reelQuickBuy(context, ref, _stayTag),
            child: const Text('rail'),
          ),
        ),
      );
      await tester.tap(find.text('rail'));
      await settle(tester);
      expect(opened, isFalse);
      expect(find.textContaining('item:/product/$stayId?tag=tag-1'), findsOneWidget);
    });
  });

  group('the reel tag picker', () {
    test('lists service items with their price labels', () async {
      final api = _PickerApiClient();
      final items = await ReelImportRemoteDataSource(
        apiClient: api,
      ).searchProducts('barahi');
      expect(api.calls, ['/v1/tag-picker/items']);
      final stay = items.first.toDomain();
      expect(stay.isService, isTrue);
      expect(stay.serviceLabel, 'from Rs 4,500/night');
      expect(items.last.toDomain().serviceLabel, isNull);
    });

    test('before the picker is deployed, products from search', () async {
      final api = _PickerApiClient(pickerDeployed: false);
      final items = await ReelImportRemoteDataSource(
        apiClient: api,
      ).searchProducts('scarf');
      expect(api.calls, ['/v1/tag-picker/items', '/api/v1/customer/search']);
      expect(items.single.productId, 'p1');
    });
  });
}
