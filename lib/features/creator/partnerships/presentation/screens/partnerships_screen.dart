import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/notifiers/partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/widgets/invite_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PartnershipsScreen extends ConsumerStatefulWidget {
  const PartnershipsScreen({super.key});

  @override
  ConsumerState<PartnershipsScreen> createState() =>
      _PartnershipsScreenState();
}

class _PartnershipsScreenState extends ConsumerState<PartnershipsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnershipsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Brand Partnerships', style: DesignTokens.titleMedium),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.primaryGreen,
          labelColor: DesignTokens.primaryGreen,
          unselectedLabelColor: DesignTokens.textMuted,
          tabs: const [
            Tab(text: 'Invites'),
            Tab(text: 'Active'),
          ],
        ),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (invites, active) => TabBarView(
          controller: _tabController,
          children: [
            _buildInvitesTab(invites),
            _buildActiveTab(active),
          ],
        ),
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load partnerships.',
          onRetry:
              () => ref.read(partnershipsNotifierProvider.notifier).load(),
        ),
      ),
    );
  }

  Widget _buildInvitesTab(List<PartnershipInvite> invites) {
    if (invites.isEmpty) {
      return const SmEmptyState(
        message: 'No pending invites.',
        icon: Icons.mail_outline,
      );
    }

    final notifier = ref.read(partnershipsNotifierProvider.notifier);
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () => notifier.load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(DesignTokens.s16),
        itemCount: invites.length,
        itemBuilder: (_, i) => InviteCard(
          invite: invites[i],
          onAccept: () => notifier.accept(invites[i].id),
          onDecline: () => notifier.decline(invites[i].id),
        ),
      ),
    );
  }

  Widget _buildActiveTab(List<ActivePartnership> active) {
    if (active.isEmpty) {
      return const SmEmptyState(
        message: 'No active partnerships.',
        icon: Icons.handshake_outlined,
      );
    }

    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh:
          () => ref.read(partnershipsNotifierProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(DesignTokens.s16),
        itemCount: active.length,
        itemBuilder: (ctx, i) {
          final p = active[i];
          return GestureDetector(
            onTap: () => ctx.push('/creator/partnerships/${p.id}'),
            child: Container(
            margin: const EdgeInsets.only(bottom: DesignTokens.s8),
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(p.vendorLogoUrl),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.vendorName, style: DesignTokens.oneLinerSemibold),
                          Text(
                            '${(p.commissionRate * 100).toStringAsFixed(0)}% commission',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric(label: 'Earned', value: p.totalEarned),
                    _Metric(label: 'Sales', value: '${p.totalSales}'),
                    _Metric(label: 'Products', value: '${p.productsCount}'),
                  ],
                ),
              ],
            ),
          ));
        },
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final val = value;
    return Column(
      children: [
        if (val is Money)
          MoneyText(val, style: DesignTokens.mediumSemibold)
        else
          Text(
            val.toString(),
            style: DesignTokens.mediumSemibold,
          ),
        const SizedBox(height: DesignTokens.s4),
        Text(label, style: DesignTokens.tiny),
      ],
    );
  }
}
