import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/notifiers/support_notifier.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(supportNotifierProvider);
    final categoriesState = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Help Center', style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: [
          TextFormField(
            controller: _searchCtrl,
            style: const TextStyle(color: DesignTokens.textWhite),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Search help articles...',
              prefixIcon: const Icon(Icons.search, color: DesignTokens.inputFieldPlaceholder, size: 20),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),

          const Text('Categories', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s12),

          categoriesState.when(
            initial: () => const _CategoriesLoader(),
            loadInProgress: () => const _CategoriesLoader(),
            loadFailure: (_) => const Center(child: Text('Failed to load categories', style: DesignTokens.smallRegular)),
            loadSuccess: (categories) => Wrap(
              spacing: DesignTokens.s12,
              runSpacing: DesignTokens.s12,
              children: categories.map((cat) => _CategoryCard(category: cat, onTap: () {
                context.push('${RouteNames.support}/contact', extra: cat);
              })).toList(),
            ),
          ),

          const SizedBox(height: DesignTokens.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Tickets', style: DesignTokens.sectionInnerTitle),
              TextButton(
                onPressed: () => context.push('${RouteNames.support}/tickets'),
                child: const Text('View All', style: TextStyle(color: DesignTokens.primaryGreen)),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),

          ticketsState.when(
            initial: () => const _TicketsLoader(),
            loadInProgress: () => const _TicketsLoader(),
            loadFailure: (_) => const Center(child: Text('Failed to load tickets', style: DesignTokens.smallRegular)),
            loadSuccess: (tickets) {
              if (tickets.isEmpty) {
                return const SmEmptyState(
                  message: 'No support tickets yet.',
                  icon: Icons.support_agent_outlined,
                );
              }
              return Column(
                children: tickets.take(3).map((t) => _TicketPreviewTile(ticket: t)).toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${RouteNames.support}/contact'),
        backgroundColor: DesignTokens.primaryGreen,
        icon: const Icon(Icons.headset_mic, color: DesignTokens.textDark),
        label: const Text('Contact Us', style: TextStyle(color: DesignTokens.textDark, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final SupportCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - DesignTokens.s32 - DesignTokens.s12) / 2,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.s12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_mapIcon(category.iconName), color: DesignTokens.primaryGreen, size: 28),
            const SizedBox(height: DesignTokens.s8),
            Text(category.title, style: DesignTokens.mediumSemibold, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: DesignTokens.s4),
            Text(category.description, style: DesignTokens.smallRegular, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  IconData _mapIcon(String name) => switch (name) {
    'order' => Icons.shopping_bag_outlined,
    'payment' => Icons.payment_outlined,
    'account' => Icons.person_outline,
    'delivery' => Icons.local_shipping_outlined,
    'returns' => Icons.assignment_return_outlined,
    _ => Icons.help_outline,
  };
}

class _TicketPreviewTile extends StatelessWidget {
  const _TicketPreviewTile({required this.ticket});

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
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.subject, style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(ticket.ticketNumber, style: DesignTokens.smallRegular),
              ],
            ),
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
    );
  }
}

class _CategoriesLoader extends StatelessWidget {
  const _CategoriesLoader();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignTokens.s12,
      runSpacing: DesignTokens.s12,
      children: List.generate(4, (i) => Container(
        width: (MediaQuery.of(context).size.width - DesignTokens.s32 - DesignTokens.s12) / 2,
        height: 100,
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.s12),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primaryGreen)),
      )),
    );
  }
}

class _TicketsLoader extends StatelessWidget {
  const _TicketsLoader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (_) => Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.s8),
        height: 60,
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.s12),
        ),
      )),
    );
  }
}
