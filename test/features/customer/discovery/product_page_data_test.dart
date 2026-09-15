import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_delivery_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_review_summary_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reel_save_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/datasources/saved_for_later_api.dart';

/// Answers every GET with the body registered for its path.
class _JsonApiClient extends ApiClient {
  _JsonApiClient(this.bodies) : super(dio: Dio());

  final Map<String, Object> bodies;
  final List<String> requested = [];

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requested.add(uri);
    return bodies[uri];
  }
}

class _Online implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

void main() {
  group('review summary', () {
    test('reads the contract fixture', () {
      final summary = ProductReviewSummaryDto.fromJson({
        'productId': 'p-1',
        'averageRating': 3.67,
        'ratingCount': 3,
        'reviewCount': 4,
        'withPhotosCount': 2,
        'distribution': [
          {'stars': 5, 'count': 1},
          {'stars': 4, 'count': 1},
          {'stars': 3, 'count': 0},
          {'stars': 2, 'count': 1},
          {'stars': 1, 'count': 0},
        ],
      });

      expect(summary.productId, 'p-1');
      expect(summary.averageRating, 3.67);
      expect(summary.ratingCount, 3);
      expect(summary.reviewCount, 4);
      expect(summary.withPhotosCount, 2);
      expect(summary.distribution, {5: 1, 4: 1, 3: 0, 2: 1, 1: 0});
      expect(summary.shareFor(5), closeTo(1 / 3, 0.0001));
      expect(summary.shareFor(3), 0);
    });

    test(
      'fills missing star rows, ignores bad ones and clamps the average',
      () {
        final summary = ProductReviewSummaryDto.fromJson({
          'averageRating': 7,
          'distribution': [
            {'stars': 9, 'count': 4},
            {'stars': 4, 'count': -2},
            'junk',
          ],
        });

        expect(summary.averageRating, 5);
        expect(summary.distribution, {5: 0, 4: 0, 3: 0, 2: 0, 1: 0});
        expect(summary.reviewCount, 0);
        expect(summary.shareFor(4), 0);
      },
    );

    test('is fetched from the summary route', () async {
      final client = _JsonApiClient({
        '/v1/public/products/p-1/reviews/summary': {
          'productId': 'p-1',
          'reviewCount': 1,
          'ratingCount': 1,
          'averageRating': 5,
          'distribution': [
            {'stars': 5, 'count': 1},
          ],
        },
      });
      final summary = await DiscoveryRemoteDataSource(
        apiClient: client,
      ).getReviewSummary('p-1');

      expect(summary.reviewCount, 1);
      expect(summary.countFor(5), 1);
    });
  });

  group('related products', () {
    test('maps the nested ProductDto list to cards', () async {
      final client = _JsonApiClient({
        '/v1/public/products/p-1/related': [
          {
            'id': 'p-2',
            'name': 'Linen shirt',
            'averageRating': 4.5,
            'images': [
              {'cdnUrl': 'https://cdn/side.jpg', 'isPrimary': false},
              {'cdnUrl': 'https://cdn/front.jpg', 'isPrimary': true},
            ],
            'variants': [
              {'id': 'v-1', 'priceAmount': 1500, 'priceCurrency': 'NPR'},
              {
                'id': 'v-2',
                'isDefault': true,
                'priceAmount': 1299.5,
                'priceCurrency': 'NPR',
              },
            ],
          },
          {'id': 'p-3', 'name': 'No media'},
        ],
      });
      final related = (await DiscoveryRemoteDataSource(
        apiClient: client,
      ).getRelatedProducts('p-1')).map((dto) => dto.toDomain()).toList();

      expect(related, hasLength(2));
      expect(related.first.id, 'p-2');
      expect(related.first.imageUrl, 'https://cdn/front.jpg');
      expect(related.first.price.amount, 1299.5);
      expect(related.first.price.currency, 'NPR');
      expect(related.first.rating, 4.5);
      expect(related.last.imageUrl, '');
      expect(related.last.price.amount, 0);
    });
  });

  group('delivery', () {
    Map<String, dynamic> option(
      Object kind, {
      int min = 0,
      int max = 0,
      num fee = 100,
      bool enabled = true,
    }) => {
      'kind': kind,
      'feeAmount': fee,
      'feeCurrency': 'NPR',
      'estimatedDaysMin': min,
      'estimatedDaysMax': max,
      'isEnabled': enabled,
    };

    test('adds processing time to the transit range of delivery options', () {
      final delivery = ProductDeliveryDto.fromJson({
        'processingTimeDays': 2,
        'shippingOptions': [
          option(1, min: 1, max: 3, fee: 150),
          option('Express', min: 1, max: 1, fee: 0),
          option(3),
        ],
      });

      expect(delivery.processingTimeDays, 2);
      expect(delivery.shippingOptions.map((o) => o.kind), [
        ShippingOptionKind.standard,
        ShippingOptionKind.express,
        ShippingOptionKind.pickup,
      ]);
      expect(delivery.estimateLabel, 'Delivers in 3–5 days');
      expect(delivery.hasFreeDelivery, isTrue);
    });

    test('a single transit time reads as one number', () {
      final delivery = ProductDeliveryDto.fromJson({
        'processingTimeDays': 1,
        'shippingOptions': [option('standard', min: 3, max: 3)],
      });

      expect(delivery.estimateLabel, 'Delivers in 4 days');
      expect(delivery.hasFreeDelivery, isFalse);
    });

    test('falls back to processing time without usable transit times', () {
      expect(
        ProductDeliveryDto.fromJson({
          'processingTimeDays': 3,
          'shippingOptions': [
            option(1, min: 2, max: 4, fee: 0, enabled: false),
            option('Pickup', fee: 0),
          ],
        }).estimateLabel,
        'Ships in 3 days',
      );
      expect(
        const ProductDelivery(processingTimeDays: 1).estimateLabel,
        'Ships in 1 day',
      );
    });

    test('says nothing when neither is known', () {
      final delivery = ProductDeliveryDto.fromJson(const {});

      expect(delivery.estimateLabel, isNull);
      expect(delivery.hasFreeDelivery, isFalse);
      expect(ProductDeliveryDto.parseKind('drone'), ShippingOptionKind.unknown);
    });

    test('the repository attaches delivery to the product detail', () async {
      final client = _JsonApiClient({
        '/v1/public/products/p-1': {
          'id': 'p-1',
          'vendorAccountId': 'vendor-1',
          'name': 'Linen shirt',
          'processingTimeDays': 2,
          'shippingOptions': [option(1, min: 2, max: 4)],
        },
      });
      final result = await DiscoveryRepositoryImpl(
        remoteDataSource: DiscoveryRemoteDataSource(apiClient: client),
        networkInfo: _Online(),
      ).getProductDetail('p-1');

      final product = result.getOrElse((_) => throw StateError('failed'));
      expect(product.name, 'Linen shirt');
      expect(product.delivery?.estimateLabel, 'Delivers in 4–6 days');
    });
  });

  test('saved-for-later rows need a row id and a product id', () {
    final rows = SavedForLaterEntry.listFromJson([
      {'id': 's-1', 'productId': 'p-1', 'productVariantId': 'v-1'},
      {'id': '', 'productId': 'p-2'},
      {'id': 's-3'},
      'junk',
    ]);

    expect(rows, const [
      SavedForLaterEntry(
        savedItemId: 's-1',
        productId: 'p-1',
        variantId: 'v-1',
      ),
    ]);
    expect(SavedForLaterEntry.listFromJson(null), isEmpty);
  });

  test('reel save result falls back to the requested state', () {
    final full = ReelSaveResult.fromJson(
      const {'reelId': 'r-1', 'saved': true, 'saveCount': 18},
      reelId: 'r-1',
      requestedSaved: false,
    );
    final empty = ReelSaveResult.fromJson(
      null,
      reelId: 'r-2',
      requestedSaved: false,
    );

    expect((full.reelId, full.saved, full.saveCount), ('r-1', true, 18));
    expect((empty.reelId, empty.saved, empty.saveCount), ('r-2', false, null));
  });
}
