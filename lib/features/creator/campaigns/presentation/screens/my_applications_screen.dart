import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/notifiers/campaign_applications_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What came of the campaigns this creator applied to.
class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  static const emptyMessage =
      'You have not applied to a campaign yet. Open Campaigns to see what '
      'brands are running.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campaignApplicationsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('My applications'),
      ),
      body: state.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loadInProgress: () => const Center(child: CircularProgressIndicator()),
        loadFailure: (_) => SmErrorView(
          title: 'Could not load your applications',
          onRetry: () =>
              ref.read(campaignApplicationsNotifierProvider.notifier).load(),
        ),
        loadSuccess: (applications, _, _) {
          if (applications.isEmpty) {
            return const SmEmptyState(
              title: 'No applications yet',
              message: emptyMessage,
              icon: Icons.assignment_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(campaignApplicationsNotifierProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: applications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _ApplicationCard(application: applications[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.application});

  final CampaignApplication application;

  /// Shown when the server sent a state this build does not know about.
  /// Falling back to "Pending" would tell a creator their application is live
  /// when the server may have settled it.
  static const unknownStateLabel = 'Unknown status';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = application.state;

    // The application carries the brief id but no campaign title — the server
    // does not send one on this DTO. Rather than invent a name or fetch every
    // brief up front, the row opens the campaign it belongs to. A campaign
    // that has since closed answers 404 there and says so plainly.
    return Material(
      color: DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          RouteNames.creatorCampaignDetail.replaceFirst(
            ':briefId',
            application.brandBriefId,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StateBadge(state: state),
                  const Spacer(),
                  Text(
                    'v${application.brandBriefVersion}',
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (application.message != null) ...[
                const Text(
                  'Your pitch',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  application.message!,
                  style: const TextStyle(
                    color: DesignTokens.textLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // A decline with no reason stays a decline with no
              // reason. Inventing "No reason given" as if the vendor
              // said it would be worse than showing nothing, so the
              // block simply does not appear.
              if (application.declineReason != null) ...[
                const Text(
                  'Why the brand passed',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  application.declineReason!,
                  style: const TextStyle(
                    color: DesignTokens.textLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (application.canWithdraw)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _withdraw(context, ref),
                    child: const Text('Withdraw'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.surfaceRaised,
        title: const Text('Withdraw this application?'),
        content: const Text(
          'The brand will no longer see it. You can apply to this campaign '
          'again afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final outcome = await ref
        .read(campaignApplicationsNotifierProvider.notifier)
        .withdraw(application.id);

    if (!context.mounted) return;
    final text = switch (outcome) {
      WithdrawOutcome.withdrawn => 'Application withdrawn.',
      WithdrawOutcome.alreadyDecided =>
        'The brand had already decided on this application.',
      WithdrawOutcome.failed => 'Could not withdraw it. Try again.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state});

  final CampaignApplicationState? state;

  @override
  Widget build(BuildContext context) {
    final (label, colour) = switch (state) {
      CampaignApplicationState.pending => (
        'Awaiting the brand',
        DesignTokens.secondaryYellow,
      ),
      CampaignApplicationState.accepted => (
        'Accepted',
        DesignTokens.primaryGreen,
      ),
      CampaignApplicationState.declined => ('Declined', DesignTokens.textMuted),
      CampaignApplicationState.withdrawn => (
        'Withdrawn',
        DesignTokens.textMuted,
      ),
      null => (
        _ApplicationCard.unknownStateLabel,
        DesignTokens.textMuted,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colour,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
