import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/notifiers/support_notifier.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Tickets', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (failure) => Center(
          child: Text('Failed to load: ${failure.toString()}', style: DesignTokens.smallRegular),
        ),
        loadSuccess: (tickets) {
          if (tickets.isEmpty) {
            return const SmEmptyState(
              message: 'You have no support tickets.',
              icon: Icons.support_agent_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(DesignTokens.s16),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s8),
            itemBuilder: (_, i) => _TicketTile(ticket: tickets[i]),
          );
        },
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});

  final Ticket ticket;

  Color _statusColor() => switch (ticket.status) {
    TicketStatus.open => DesignTokens.primaryGreen,
    TicketStatus.inProgress => DesignTokens.colorInfo,
    TicketStatus.resolved => DesignTokens.colorSuccess,
    TicketStatus.closed => DesignTokens.textMuted,
  };

  String _statusLabel() => switch (ticket.status) {
    TicketStatus.open => 'Open',
    TicketStatus.inProgress => 'In Progress',
    TicketStatus.resolved => 'Resolved',
    TicketStatus.closed => 'Closed',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ticket.subject, style: DesignTokens.mediumSemibold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
                decoration: BoxDecoration(
                  color: _statusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
                ),
                child: Text(
                  _statusLabel(),
                  style: DesignTokens.tiny.copyWith(color: _statusColor()),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(ticket.ticketNumber, style: DesignTokens.smallRegular),
          if (ticket.lastMessagePreview != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              ticket.lastMessagePreview!,
              style: DesignTokens.smallRegular,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Last updated: ${_formatDate(ticket.lastUpdated)}',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
