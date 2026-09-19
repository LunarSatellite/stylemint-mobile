import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/datasources/assistant_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_recommendation.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/repositories/assistant_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/notifiers/assistant_thread_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';

final assistantRemoteDataSourceProvider = Provider<AssistantRemoteDataSource>(
  (ref) => AssistantRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepositoryImpl(
    remoteDataSource: ref.watch(assistantRemoteDataSourceProvider),
  ),
);

/// The caller's conversation history, newest first.
// ignore: specify_nonobvious_property_types — Riverpod's own inferred type.
final assistantConversationsProvider =
    FutureProvider.autoDispose<ConversationList>((
      ref,
    ) async {
      final result = await ref
          .watch(assistantRepositoryProvider)
          .listConversations();
      return result.fold(
        Future<ConversationList>.error,
        (list) => list,
      );
    });

/// What Minty suggests outside a conversation, each with the basis it really
/// came from. An error yields an empty list rather than a failed screen: the
/// shelf is a garnish on the conversations list, not its subject.
// ignore: specify_nonobvious_property_types — Riverpod's own inferred type.
final companionRecommendationsProvider =
    FutureProvider.autoDispose<List<CompanionRecommendation>>((ref) async {
      final result = await ref
          .watch(assistantRepositoryProvider)
          .getRecommendations(limit: 10);
      return result.getOrElse((_) => const []);
    });

/// What a successful cart addition does to the rest of the app.
///
/// The cart badge is where a shopper already looks for this number, so the
/// count the add returned goes straight there, and the cart is refetched so
/// every other view agrees. It is its own provider so a test can stand it
/// down without standing up the whole cart stack.
final assistantCartSyncProvider = Provider<void Function(int)>(
  (ref) => (count) {
    ref
      ..read(cartItemCountProvider.notifier).observeExternalCount(count)
      ..read(cartNotifierProvider.notifier).fetchCart().ignore();
  },
);

/// One thread. The family argument is the conversation id, or `''` for a
/// conversation that does not exist yet.
// ignore: specify_nonobvious_property_types — Riverpod's own inferred type.
final assistantThreadProvider = StateNotifierProvider.autoDispose
    .family<AssistantThreadNotifier, AssistantThreadState, String>((
      ref,
      conversationId,
    ) {
      return AssistantThreadNotifier(
        ref.watch(assistantRepositoryProvider),
        conversationId: conversationId.isEmpty ? null : conversationId,
      )..onCartCountChanged = ref.watch(assistantCartSyncProvider);
    });

/// The products one turn suggested, resolved to real catalogue entries.
///
/// Unresolvable ids are omitted by the repository, so this list can be
/// shorter than `turn.suggestedProductIds` — and empty, which renders
/// nothing at all rather than an empty shelf.
// ignore: specify_nonobvious_property_types — Riverpod's own inferred type.
final suggestedProductsProvider = FutureProvider.autoDispose
    .family<List<MallProductVm>, CompanionTurn>(
      (ref, turn) =>
          ref.watch(assistantRepositoryProvider).resolveSuggestions(turn),
    );
