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

  /// `POST /v1/cart-shares/{id}/items` → `CartShareItemDto`. Body is
  /// `AddCartShareItemVm { productId, productVariantId?, quantity }`; the
  /// server resolves the caller from the token. Its validator requires a
  /// product id and a quantity of 1–99, so anything outside that is a 400
  /// rather than a clamp.
  ///
  /// (This used to carry a "no cart-share items endpoint" note from when the
  /// lines had to go through `/v1/cart/lines`. The endpoint exists now and the
  /// call below matches its contract.)
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

  /// `DELETE /v1/cart-shares/{id}/items/{itemId}` → 204. Also exists now; the
  /// removal note this used to carry was written before it did.
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
