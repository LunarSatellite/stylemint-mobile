import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';

/// Why [addSuggestedProductToCart] takes a whole [CompanionTurn] and not a
/// pair of ids: it makes "add a product this turn did not suggest" something
/// a caller cannot express. There is no overload that takes a bare message id.
abstract class AssistantRepository {
  Future<Either<NetworkExceptions, ConversationList>> listConversations({
    String? cursor,
  });

  Future<Either<NetworkExceptions, ConversationPage>> getConversation(
    String conversationId, {
    String? cursor,
  });

  Future<Either<NetworkExceptions, ChatReply>> sendMessage({
    required String message,
    String? conversationId,
  });

  /// Adds one product **that [turn] suggested** to the caller's own cart.
  ///
  /// Returns `.validation(code: 'companion.not_suggested')` without calling
  /// the API when [turn] did not suggest [productId] — including every case
  /// where [turn] is the customer's own message. The backend refuses both
  /// independently; this is the client-side half of the same rule.
  ///
  /// [idempotencyKey] is the caller's, so retrying one customer decision
  /// reuses it.
  Future<Either<NetworkExceptions, CartAddition>> addSuggestedProductToCart({
    required String conversationId,
    required CompanionTurn turn,
    required String productId,
    required String idempotencyKey,
    int quantity,
  });

  /// Resolves [turn]'s suggested ids to real products, in the order the turn
  /// named them.
  ///
  /// Anything that does not resolve is **omitted**. There is no placeholder:
  /// a card implying a product exists when it does not is worse than a
  /// shorter list.
  Future<List<MallProductVm>> resolveSuggestions(CompanionTurn turn);
}
