import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/models/companion_turn_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_recommendation.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/repositories/assistant_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';

const productA = '11111111-1111-1111-1111-111111111111';
const productB = '22222222-2222-2222-2222-222222222222';
const ghostProduct = '33333333-3333-3333-3333-333333333333';

/// A turn exactly as the API sends one.
Map<String, dynamic> turnJson({
  required String id,
  required String role,
  required String message,
  String? suggested,
  int? mood,
  int? contextType,
}) => {
  'id': id,
  'accountId': 'acc-1',
  'threadId': 'conv-1',
  'role': role,
  'message': message,
  'mood': mood,
  'contextType': contextType,
  'productIdsSuggested': suggested,
  'reelIdsSuggested': null,
  'createdUtc': '2026-09-19T08:00:00Z',
  'updatedUtc': '2026-09-19T08:00:00Z',
  'rowVersion': 'AAA=',
};

CompanionTurn turnFrom({
  required String id,
  required String role,
  required String message,
  String? suggested,
}) => companionTurnFromJson(
  turnJson(id: id, role: role, message: message, suggested: suggested),
);

MallProductVm productVm(String id, String name) => MallProductVm(
  id: id,
  name: name,
  price: const Money(amount: 2499, currency: 'NPR'),
  brandName: 'Tundra',
);

/// Records every call so a test can assert the one action happened once.
class FakeAssistantRepository implements AssistantRepository {
  FakeAssistantRepository({
    this.turns = const <CompanionTurn>[],
    this.resolved = const <String, String>{},
    this.failAddOnce = false,
  });

  List<CompanionTurn> turns;

  /// productId -> display name. An id absent here does not resolve.
  Map<String, String> resolved;

  /// Makes the first add fail, so a retry can be observed.
  bool failAddOnce;

  final List<({String turnId, String productId, String key})> addCalls = [];
  final List<String> sentMessages = [];
  final List<String?> conversationCursors = [];

  /// Appended by [sendMessage]; override to shape a reply.
  CompanionTurn Function(String message)? replyBuilder;

  /// What [getRecommendations] answers. Empty by default, so a screen test
  /// that does not care about the shelf gets no shelf.
  List<CompanionRecommendation> recommendations = const [];

  @override
  Future<Either<NetworkExceptions, ConversationList>> listConversations({
    String? cursor,
  }) async => right(
    const ConversationList(items: <ConversationSummary>[]),
  );

  @override
  Future<Either<NetworkExceptions, List<CompanionRecommendation>>>
  getRecommendations({int limit = 10}) async =>
      right(recommendations.take(limit).toList());

  @override
  Future<Either<NetworkExceptions, ConversationPage>> getConversation(
    String conversationId, {
    String? cursor,
  }) async {
    conversationCursors.add(cursor);
    return right(
      ConversationPage(
        conversation: ConversationSummary(
          id: conversationId,
          title: 'A conversation',
          messageCount: turns.length,
          lastMessageUtc: DateTime.utc(2026, 9, 19),
        ),
        turns: turns,
        totalTurns: turns.length,
      ),
    );
  }

  @override
  Future<Either<NetworkExceptions, ChatReply>> sendMessage({
    required String message,
    String? conversationId,
  }) async {
    sentMessages.add(message);
    final user = turnFrom(
      id: 'u-${sentMessages.length}',
      role: 'user',
      message: message,
    );
    final reply =
        replyBuilder?.call(message) ??
        turnFrom(
          id: 'm-${sentMessages.length}',
          role: 'minty',
          message: 'Here is an idea.',
        );
    turns = [...turns, user, reply];
    return right(
      ChatReply(
        conversationId: conversationId ?? 'conv-1',
        userTurn: user,
        reply: reply,
      ),
    );
  }

  @override
  Future<Either<NetworkExceptions, CartAddition>> addSuggestedProductToCart({
    required String conversationId,
    required CompanionTurn turn,
    required String productId,
    required String idempotencyKey,
    int quantity = 1,
  }) async {
    // Mirrors the real repository's gate so a widget test exercises it too.
    if (!turn.suggests(productId)) {
      return left(
        const NetworkExceptions.validation(
          code: 'companion.not_suggested',
          message: 'That product was not one of these suggestions.',
        ),
      );
    }
    addCalls.add((turnId: turn.id, productId: productId, key: idempotencyKey));
    if (failAddOnce) {
      failAddOnce = false;
      return left(const NetworkExceptions.noInternetConnection());
    }
    return right(
      CartAddition(
        conversationId: conversationId,
        messageId: turn.id,
        productId: productId,
        quantity: quantity,
        cartItemCount: 3,
        addedUtc: DateTime.utc(2026, 9, 19),
      ),
    );
  }

  @override
  Future<List<MallProductVm>> resolveSuggestions(CompanionTurn turn) async => [
    for (final id in turn.suggestedProductIds)
      if (resolved[id] case final String name) productVm(id, name),
  ];
}
