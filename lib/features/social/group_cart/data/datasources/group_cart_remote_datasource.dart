import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/data/models/group_cart_dto.dart';

class GroupCartRemoteDataSource {
  GroupCartRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<GroupCartDto>> getGroupCarts() async {
    final response = await apiClient.get('/v1/cart-shares');
    final items = (response as List<dynamic>?)
        ?.map((e) => GroupCartDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items ?? const [];
  }

  Future<GroupCartDto> getGroupCart(String cartId) async {
    final response = await apiClient.get('/v1/cart-shares/$cartId');
    return GroupCartDto.fromJson(response as Map<String, dynamic>);
  }

  Future<GroupCartDto> createGroupCart(
    String name,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/cart-shares',
      data: {'name': name},
      options: _idempotent(idempotencyKey),
    );
    return GroupCartDto.fromJson(response as Map<String, dynamic>);
  }

  Future<GroupCartDto> joinGroupCart(
    String inviteCode,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/cart-shares/invitations/accept',
      data: {'inviteCode': inviteCode},
      options: _idempotent(idempotencyKey),
    );
    return GroupCartDto.fromJson(response as Map<String, dynamic>);
  }

  /// TODO(swagger): No cart-share items endpoint — cart lines managed via /v1/cart/lines.
  Future<GroupCartItemDto> addToGroupCart(
    String cartId,
    String productId,
    int qty,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/cart-shares/$cartId/items',
      data: {'productId': productId, 'quantity': qty},
      options: _idempotent(idempotencyKey),
    );
    return GroupCartItemDto.fromJson(response as Map<String, dynamic>);
  }

  /// TODO(swagger): No cart-share item removal endpoint.
  Future<void> removeFromGroupCart(
    String cartId,
    String itemId,
    String idempotencyKey,
  ) async {
    await apiClient.authDelete(
      '/v1/cart-shares/$cartId/items/$itemId',
      options: _idempotent(idempotencyKey),
    );
  }

  /// TODO(swagger): No cart-share checkout endpoint — use /v1/cart-shares/{id}/close to finalize.
  Future<void> checkoutGroupCart(
    String cartId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/cart-shares/$cartId/checkout',
      options: _idempotent(idempotencyKey),
    );
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
