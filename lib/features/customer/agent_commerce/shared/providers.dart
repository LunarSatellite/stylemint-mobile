import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/data/datasources/agent_commerce_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/domain/entities/agent_mandate.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/notifiers/agent_commerce_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/notifiers/saved_items_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/providers.dart';

/// The customer's half of `v1/agent-commerce/*`.
final agentCommerceDataSourceProvider = Provider<AgentCommerceDataSource>(
  (ref) =>
      AgentCommerceRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

/// Mandates, pending baskets and the activity ledger.
///
/// Deliberately *not* `autoDispose`: the screen is reachable from Settings and
/// from a proposal notification, and a customer bouncing between the two
/// should not re-read three endpoints each time. It holds no credential, so
/// there is nothing here that outliving the screen could expose.
final agentCommerceNotifierProvider =
    StateNotifierProvider<AgentCommerceNotifier, AgentCommerceState>(
      (ref) => AgentCommerceNotifier(
        dataSource: ref.watch(agentCommerceDataSourceProvider),
      ),
    );

/// Products the customer can put on a mandate's allowlist.
///
/// Sourced from their saved items, because those are products they have
/// already named — the alternative is sending someone browsing in the middle
/// of granting authority, which is exactly when they should not be shopping.
/// An empty list is a real answer and the sheet says so rather than pretending
/// the allowlist is unavailable.
final agentAllowlistCandidatesProvider =
    Provider<List<AgentAllowlistCandidate>>((ref) {
      final saved = ref.watch(savedItemsNotifierProvider);
      return saved.maybeWhen(
        loadSuccess: (items, _, _) => items
            .map(
              (i) => AgentAllowlistCandidate(
                productId: i.productId,
                title: i.productName,
                subtitle: i.variantLabel,
              ),
            )
            .where((c) => c.productId.isNotEmpty)
            .toList(growable: false),
        orElse: () => const <AgentAllowlistCandidate>[],
      );
    });
