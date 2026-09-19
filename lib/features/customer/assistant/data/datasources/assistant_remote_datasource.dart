import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

/// `/v1/customer/companion/chat*` — every route is `[Authorize]` and scoped
/// server-side to the JWT subject, so nothing here passes an account id.
///
/// There is deliberately no order, reserve or pay method on this class. The
/// assistant cannot reach checkout, and the shape of this file is the first
/// place that is enforced.
class AssistantRemoteDataSource {
  AssistantRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const String base = '/v1/customer/companion';

  /// POST `/chat` — sends one message and returns both turns.
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String idempotencyKey,
    String? conversationId,
  }) async {
    final response = await apiClient.post(
      '$base/chat',
      data: {'message': message, 'conversationId': conversationId},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// GET `/chat/conversations` — newest first.
  Future<Map<String, dynamic>> listConversations({
    String? cursor,
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      '$base/chat/conversations',
      queryParameters: {'pageSize': pageSize, 'cursor': ?cursor},
    );
    return response as Map<String, dynamic>;
  }

  /// GET `/chat/conversations/{id}` — one oldest-first page of turns.
  Future<Map<String, dynamic>> getConversation(
    String conversationId, {
    String? cursor,
    int pageSize = 50,
  }) async {
    final response = await apiClient.get(
      '$base/chat/conversations/${Uri.encodeComponent(conversationId)}',
      queryParameters: {'pageSize': pageSize, 'cursor': ?cursor},
    );
    return response as Map<String, dynamic>;
  }

  /// POST `/chat/conversations/{id}/cart-additions` — the one action.
  ///
  /// [idempotencyKey] is supplied by the caller, never generated here, so a
  /// retry of the *same* customer decision reuses it and cannot add twice.
  Future<Map<String, dynamic>> addSuggestionToCart({
    required String conversationId,
    required String messageId,
    required String productId,
    required int quantity,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '$base/chat/conversations/${Uri.encodeComponent(conversationId)}'
      '/cart-additions',
      data: {
        'messageId': messageId,
        'productId': productId,
        'quantity': quantity,
      },
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// GET `/v1/public/products/{id}` — used only to resolve a suggested id to
  /// a real product. A product that cannot be resolved is dropped by the
  /// repository rather than drawn as a placeholder.
  Future<Map<String, dynamic>> getProduct(String productId) async {
    final response = await apiClient.get(
      '/v1/public/products/${Uri.encodeComponent(productId)}',
    );
    return response as Map<String, dynamic>;
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {'requiresToken': true, 'Idempotency-Key': idempotencyKey},
  );
}
