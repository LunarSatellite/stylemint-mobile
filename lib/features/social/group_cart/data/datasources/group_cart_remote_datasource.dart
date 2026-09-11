import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/data/models/group_cart_dto.dart';

class GroupCartRemoteDataSource {
  GroupCartRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<GroupCartDto>> getGroupCarts() async {
    final response = await apiClient.get('/v1/cart-shares');
    final page = response as Map<String, dynamic>;
    final items = (page['items'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) => GroupCartDto.fromCartShareJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
    return items;
  }

  Future<GroupCartDto> getGroupCart(String cartId) async {
    final response = await apiClient.get('/v1/cart-shares/$cartId');
    return GroupCartDto.fromCartShareJson(response as Map<String, dynamic>);
  }

  Future<GroupCartDto> createGroupCart(
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/cart-shares',
      data: <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );
    return GroupCartDto.fromCartShareJson(response as Map<String, dynamic>);
  }

  Future<GroupCartDto> joinGroupCart(
    String inviteCode,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/cart-shares/invitations/accept',
      // `AcceptCartShareInvitationVm` field is `token`; the accepting
      // account is now resolved from the JWT, not sent in the body.
      data: {'token': inviteCode},
      options: _idempotent(idempotencyKey),
    );
    return GroupCartDto.fromCartShareJson(response as Map<String, dynamic>);
  }

  Future<String> inviteToGroupCart(
    String cartId,
    String invitedAccountId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/cart-shares/$cartId/invite',
      data: {'invitedAccountId': invitedAccountId, 'proposedRole': 2},
      options: _idempotent(idempotencyKey),
    );
    final token = (response as Map<String, dynamic>)['token'] as String? ?? '';
    if (token.isEmpty) {
      throw const FormatException('Cart-share invitation token is missing.');
    }
    return token;
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

  Future<void> checkoutGroupCart(
    String cartId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/cart-shares/$cartId/close',
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
