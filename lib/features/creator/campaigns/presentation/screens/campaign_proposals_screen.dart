import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_proposal.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/notifiers/campaign_proposals_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Every campaign a vendor has published and opened to creators.
///
/// This is the list the owner described as "the proposal gets listed in the
/// creator list". A campaign appears here only because the server judged it
/// open — nothing on this screen re-decides that.
class CampaignProposalsScreen extends ConsumerStatefulWidget {
  const CampaignProposalsScreen({super.key});

  static const emptyMessage =
      'No brand has an open campaign right now. When one publishes a '
      'campaign you can apply to, it appears here.';

  @override
  ConsumerState<CampaignProposalsScreen> createState() =>
      _CampaignProposalsScreenState();
}

class _CampaignProposalsScreenState
    extends ConsumerState<CampaignProposalsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 400) {
      unawaited(
        ref.read(campaignProposalsNotifierProvider.notifier).loadMore(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campaignProposalsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Campaigns'),
        actions: [
          TextButton(
            onPressed: () => context.push(RouteNames.creatorMyApplications),
            child: const Text('My applications'),
          ),
        ],
      ),
      body: state.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loadInProgress: () => const Center(child: CircularProgressIndicator()),
        loadFailure: (failure) => SmErrorView(
          title: 'Could not load campaigns',
          onRetry: () =>
              ref.read(campaignProposalsNotifierProvider.notifier).load(),
        ),
        loadSuccess: (proposals, hasMore, _, isLoadingMore) {
          if (proposals.isEmpty) {
            return const SmEmptyState(
              title: 'No open campaigns',
              message: CampaignProposalsScreen.emptyMessage,
              icon: Icons.campaign_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(campaignProposalsNotifierProvider.notifier).load(),
            child: ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: proposals.length + (isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i >= proposals.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _ProposalCard(proposal: proposals[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.proposal});

  final CampaignProposal proposal;

  /// Shown when the vendor published without naming the campaign. It reads as
  /// a placeholder on purpose — inventing a title from the brief's contents
  /// would put words in the brand's mouth.
  static const untitledLabel = 'Untitled campaign';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          RouteNames.creatorCampaignDetail.replaceFirst(
            ':briefId',
            proposal.id,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proposal.title ?? untitledLabel,
                style: TextStyle(
                  color: proposal.title == null
                      ? DesignTokens.textMuted
                      : DesignTokens.textWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontStyle: proposal.title == null
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    icon: Icons.percent,
                    label: proposal.commission.label,
                  ),
                  if (proposal.hasProductRestriction)
                    _Chip(
                      icon: Icons.inventory_2_outlined,
                      label: _productsLabel(
                        proposal.productVariantIds.length,
                      ),
                    ),
                  if (proposal.applicationsCloseUtc != null)
                    _Chip(
                      icon: Icons.schedule,
                      label: _closesLabel(proposal.applicationsCloseUtc!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _productsLabel(int n) =>
      '$n product${n == 1 ? '' : 's'}';

  /// A coarse countdown. Deliberately not precise to the minute: the server
  /// owns the window and a client clock that disagreed would either hurry a
  /// creator or reassure them wrongly.
  static String _closesLabel(DateTime closeUtc) {
    final left = closeUtc.difference(DateTime.now().toUtc());
    if (left.isNegative) return 'Closing';
    if (left.inDays >= 1) return 'Closes in ${left.inDays}d';
    if (left.inHours >= 1) return 'Closes in ${left.inHours}h';
    return 'Closes soon';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreenLight,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DesignTokens.primaryGreen),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
