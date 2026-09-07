import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';

class CartRemoteDataSource {
  CartRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CartDto> getCart() async {
    final response = await apiClient.get('/v1/cart');
    return CartDto.fromJson(response as Map<String, dynamic>);
  }

  Future<CartDto> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
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
      },
      options: _idempotent(idempotencyKey),
    );
    return CartDto.fromJson(response as Map<String, dynamic>);
  }

  Future<CartDto> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    final response = await apiClient.patch(
      '/v1/cart/lines/$itemId',
      data: {'quantity': quantity},
    );
    return CartDto.fromJson(response as Map<String, dynamic>);
  }

  Future<CartDto> removeCartItem(String itemId) async {
    final response = await apiClient.authDelete('/v1/cart/lines/$itemId');
    return CartDto.fromJson(response as Map<String, dynamic>);
  }

  Options _idempotent(String idempotencyKey) => Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      );
}
