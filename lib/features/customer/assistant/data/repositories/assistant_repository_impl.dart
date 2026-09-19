import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/datasources/assistant_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/models/companion_recommendation_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/models/companion_turn_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/models/suggested_product_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_recommendation.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/repositories/assistant_repository.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:uuid/uuid.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl({required this.remoteDataSource});

  final AssistantRemoteDataSource remoteDataSource;

  static const _uuid = Uuid();

  /// The error a refused add carries when the turn did not suggest the
  /// product. Never reaches the network.
  static const String notSuggestedCode = 'companion.not_suggested';

  @override
  Future<Either<NetworkExceptions, ConversationList>> listConversations({
    String? cursor,
  }) => _call(
    () async => conversationListFromJson(
      await remoteDataSource.listConversations(cursor: cursor),
    ),
  );

  @override
  Future<Either<NetworkExceptions, ConversationPage>> getConversation(
    String conversationId, {
    String? cursor,
  }) => _call(
    () async => conversationPageFromJson(
      await remoteDataSource.getConversation(conversationId, cursor: cursor),
    ),
  );

  @override
  Future<Either<NetworkExceptions, ChatReply>> sendMessage({
    required String message,
    String? conversationId,
  }) => _call(
    () async => chatReplyFromJson(
      await remoteDataSource.sendMessage(
        message: message,
        conversationId: conversationId,
        idempotencyKey: _uuid.v4(),
      ),
    ),
  );

  @override
  Future<Either<NetworkExceptions, List<CompanionRecommendation>>>
  getRecommendations({int limit = 10}) => _call(
    () async => CompanionRecommendationListDto.fromJson(
      await remoteDataSource.getRecommendations(limit: limit),
    ).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, CartAddition>> addSuggestedProductToCart({
    required String conversationId,
    required CompanionTurn turn,
    required String productId,
    required String idempotencyKey,
    int quantity = 1,
  }) async {
    // The gate, before any network call: this turn must have suggested this
    // product. A user turn can never pass, because it never carries
    // suggestions.
    if (!turn.suggests(productId)) {
      return left(
        const NetworkExceptions.validation(
          code: notSuggestedCode,
          message: 'That product was not one of these suggestions.',
        ),
      );
    }
    return _call(
      () async => cartAdditionFromJson(
        await remoteDataSource.addSuggestionToCart(
          conversationId: conversationId,
          messageId: turn.id,
          productId: productId,
          quantity: quantity.clamp(1, 10),
          idempotencyKey: idempotencyKey,
        ),
      ),
    );
  }

  @override
  Future<List<MallProductVm>> resolveSuggestions(CompanionTurn turn) async {
    if (!turn.hasSuggestions) return const <MallProductVm>[];
    final resolved = await Future.wait(
      turn.suggestedProductIds.map((id) async {
        try {
          return suggestedProductFromJson(
            await remoteDataSource.getProduct(id),
            fallbackId: id,
          );
        } on Object catch (_) {
          // Deleted, unpublished, or simply not reachable right now. Drop it —
          // never stub a card for a product we cannot show honestly.
          return null;
        }
      }),
    );
    return resolved.whereType<MallProductVm>().toList(growable: false);
  }

  Future<Either<NetworkExceptions, T>> _call<T>(
    Future<T> Function() body,
  ) async {
    try {
      return right(await body());
    } on DioException catch (e) {
      return left(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
