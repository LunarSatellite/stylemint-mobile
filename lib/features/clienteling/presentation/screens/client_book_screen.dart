import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/clienteling_labels.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The store associate's client book — `GET /v1/clienteling/associate/clients`.
///
/// The backend gates this on data, not on a role: an active vendor team
/// membership AND a live per-customer assignment. An account with neither gets
/// an empty list, and the empty state says exactly that.
class ClientBookScreen extends ConsumerWidget {
  const ClientBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientBookNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'Client book',
          style: DesignTokens.oneLinerSemibold,
        ),
      ),
      body: SafeArea(
        child: switch (state) {
          ClientBookLoadInProgress() || ClientBookInitial() => const Center(
            child: SmBrandLoader(),
          ),
          ClientBookLoadFailure(:final failure) => SmErrorView(
            message: NetworkExceptions.getMessage(failure),
            onRetry: () => ref.read(clientBookNotifierProvider.notifier).load(),
          ),
          ClientBookLoadSuccess(
            :final clients,
            :final nextCursor,
            :final isLoadingMore,
          ) =>
            clients.isEmpty
                ? const _ClientBookEmpty()
                : _ClientList(
                    clients: clients,
                    hasMore: nextCursor != null && nextCursor.isNotEmpty,
                    isLoadingMore: isLoadingMore,
                    onLoadMore: () => ref
                        .read(clientBookNotifierProvider.notifier)
                        .loadMore(),
                    onRefresh: () =>
                        ref.read(clientBookNotifierProvider.notifier).load(),
                  ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _ClientBookEmpty extends StatelessWidget {
  const _ClientBookEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s24),
      children: const [
        SizedBox(height: DesignTokens.s48),
        Icon(
          Icons.people_outline,
          size: DesignTokens.iconXLarge,
          color: DesignTokens.textMuted,
        ),
        SizedBox(height: DesignTokens.s16),
        Text(
          'No clients assigned to you',
          textAlign: TextAlign.center,
          style: DesignTokens.oneLinerSemibold,
        ),
        SizedBox(height: DesignTokens.s8),
        Text(
          'A shop grants an associate permission to serve one named customer '
          'at a time. Until a shop you work for does that, there is nothing '
          'here.',
          textAlign: TextAlign.center,
          style: DesignTokens.smallDescription,
        ),
      ],
    );
  }
}

class _ClientList extends StatelessWidget {
  const _ClientList({
    required this.clients,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final List<ClientAssignment> clients;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.s16),
        itemCount: clients.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s12),
        itemBuilder: (context, index) {
          if (index >= clients.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
              child: isLoadingMore
                  ? const Center(child: SmBrandLoader())
                  : Center(
                      child: TextButton(
                        onPressed: onLoadMore,
                        child: const Text('Load more'),
                      ),
                    ),
            );
          }
          return _ClientCard(assignment: clients[index]);
        },
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.assignment});

  final ClientAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final label = clientLabel(
      displayName: assignment.customerDisplayName,
      handle: assignment.customerHandle,
      accountId: assignment.customerAccountId,
    );
    final granted = assignment.grantedUtc;

    return Material(
      color: DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        onTap: () => context.push(
          '${RouteNames.associateClientBook}/${assignment.customerAccountId}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: DesignTokens.oneLinerSemibold),
              if (assignment.customerDisplayName != null &&
                  assignment.customerHandle != null) ...[
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '@${assignment.customerHandle}',
                  style: DesignTokens.smallDescription,
                ),
              ],
              const SizedBox(height: DesignTokens.s8),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s4,
                children: [
                  _StatusChip(status: assignment.status),
                  if (granted != null)
                    Text(
                      'Assigned ${formatRelative(granted)}',
                      style: DesignTokens.smallDescription,
                    ),
                ],
              ),
              if (assignment.note != null) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(assignment.note!, style: DesignTokens.smallRegular),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ClientAssignmentStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == ClientAssignmentStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? DesignTokens.primaryGreenLight
            : DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: Text(
        assignmentStatusLabel(status),
        style: DesignTokens.smallRegular.copyWith(
          color: isActive ? DesignTokens.primaryGreen : DesignTokens.textMuted,
        ),
      ),
    );
  }
}
