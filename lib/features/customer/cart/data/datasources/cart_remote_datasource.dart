import 'package:dio/dio.dart' show ListFormat, Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/basket_scenarios_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/shared/data/option_label.dart';

class CartRemoteDataSource {
  CartRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// A cart line shows the variant's `optionLabel` ("M / Emerald") when the
  /// payload carries one, else the SKU snapshot it was frozen with.
  static CartDto _cart(dynamic response) =>
      CartDto.fromJson(withOptionLabels(response as Map<String, dynamic>));

  Future<CartDto> getCart() async {
    final response = await apiClient.get('/v1/cart');
    return _cart(response);
  }

  /// GET `/v1/cart/optimize` — AI-generated observations grounded only in
  /// the caller's actual cart contents, plus an optional savings tip.
  Future<Map<String, dynamic>> getBasketOptimization() async {
    final response = await apiClient.get('/v1/cart/optimize');
    return response as Map<String, dynamic>;
  }

  /// GET `/v1/cart/scenarios` — Voyager "Counterfactual Basket Laboratory":
  /// the cart as it is next to alternatives (within [budget], lower cost,
  /// ready sooner). [keepLineIds] are never changed and [excludeProductIds]
  /// never come back as swaps. Read-only: the cart is not modified.
  Future<BasketScenariosDto> getScenarios({
    double? budget,
    List<String> keepLineIds = const [],
    List<String> excludeProductIds = const [],
  }) async {
    final response = await apiClient.get(
      '/v1/cart/scenarios',
      queryParameters: {
        'budget': ?budget,
        if (keepLineIds.isNotEmpty) 'keep': keepLineIds,
        if (excludeProductIds.isNotEmpty) 'exclude': excludeProductIds,
      },
      // Repeated keys (?keep=a&keep=b), which ASP.NET binds to Guid[].
      options: Options(
        headers: {'requiresToken': true},
        listFormat: ListFormat.multi,
      ),
    );
    return BasketScenariosDto.fromJson(response as Map<String, dynamic>);
  }

  Future<CartDto> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
    String? reelTagContextId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/cart/lines',
      data: {
        'productId': productId,
        'quantity': quantity,
        // Backend field is ProductVariantId; omit entirely when we don't have
        // one (e.g. reel-tag Add to Cart) — the server resolves the product's
        // single default variant. Day 1 has no real per-variant SKU ids on
        // the client to send here.
        if (variantId != null) 'productVariantId': variantId,
        if (reelTagContextId != null) 'reelTagContextId': reelTagContextId,
      },
      options: _idempotent(idempotencyKey),
    );
    return _cart(response);
  }

  Future<CartDto> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    final response = await apiClient.patch(
      '/v1/cart/lines/$itemId',
      data: {'quantity': quantity},
    );
    return _cart(response);
  }

  Future<CartDto> removeCartItem(String itemId) async {
    final response = await apiClient.authDelete('/v1/cart/lines/$itemId');
    return _cart(response);
  }

  Future<CartDto> applyPromo({
    required String code,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/cart/promo',
      data: {'code': code},
      options: _idempotent(idempotencyKey),
    );
    return _cart(response);
  }

  Future<CartDto> removePromo(String idempotencyKey) async {
    final response = await apiClient.authDelete(
      '/v1/cart/promo',
      options: _idempotent(idempotencyKey),
    );
    return _cart(response);
  }

  Future<void> saveForLater({
    required String lineId,
    required String idempotencyKey,
  }) => apiClient.post(
    '/v1/cart/saved-for-later/from-cart/$lineId',
    options: _idempotent(idempotencyKey),
  );

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
