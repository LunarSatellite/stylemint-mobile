import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/entities/reach.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/presentation/notifiers/reach_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/presentation/widgets/boost_campaign_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ReachScreen extends ConsumerWidget {
  const ReachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reachNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Reach', style: DesignTokens.titleMedium),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (targets, campaigns, analytics) {
          if (targets.isEmpty && campaigns.isEmpty) {
            return const SmEmptyState(
              message: 'No publish targets or boost campaigns yet.',
              icon: Icons.rocket_launch_outlined,
            );
          }
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh:
                () => ref.read(reachNotifierProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: [
                _AnalyticsSection(analytics: analytics),
                const SizedBox(height: DesignTokens.s24),
                if (targets.isNotEmpty) ...[
                  Text('Publish Targets', style: DesignTokens.h3),
                  const SizedBox(height: DesignTokens.s8),
                  ...targets.map(
                    (t) => Container(
                      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
                      padding: const EdgeInsets.all(DesignTokens.s12),
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBody,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.cardRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            t.platform.icon,
                            color: t.platform.color,
                            size: 20,
                          ),
                          const SizedBox(width: DesignTokens.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.platform.displayName,
                                  style: DesignTokens.mediumSemibold,
                                ),
                                Text(
                                  _formatDateTime(t.scheduledAt),
                                  style: DesignTokens.tiny,
                                ),
                              ],
                            ),
                          ),
                          _PublishStatusBadge(status: t.status),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s24),
                ],
                if (campaigns.isNotEmpty) ...[
                  Text('Boost Campaigns', style: DesignTokens.h3),
                  const SizedBox(height: DesignTokens.s8),
                  ...campaigns.map(
                    (c) => BoostCampaignCard(campaign: c),
                  ),
                ],
              ],
            ),
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load reach data.',
          onRetry:
              () => ref.read(reachNotifierProvider.notifier).load(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _PublishStatusBadge extends StatelessWidget {
  const _PublishStatusBadge({required this.status});

  final PublishStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      PublishStatus.scheduled => (DesignTokens.colorInfo, 'Scheduled'),
      PublishStatus.published => (DesignTokens.primaryGreen, 'Published'),
      PublishStatus.failed => (DesignTokens.colorError, 'Failed'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Text(label, style: DesignTokens.tiny.copyWith(color: color)),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({required this.analytics});

  final ReachAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics', style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AnalyticItem(
                label: 'Impressions',
                value: _formatCount(analytics.totalImpressions),
              ),
              _AnalyticItem(
                label: 'Clicks',
                value: _formatCount(analytics.totalClicks),
              ),
              _AnalyticItem(
                label: 'Engagements',
                value: _formatCount(analytics.totalEngagements),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              Text('Total Spent: ', style: DesignTokens.smallRegular),
              MoneyText(
                analytics.totalSpent,
                style: DesignTokens.mediumSemibold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _AnalyticItem extends StatelessWidget {
  const _AnalyticItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s4),
        Text(label, style: DesignTokens.tiny),
      ],
    );
  }
}
