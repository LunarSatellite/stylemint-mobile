import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor → Brand Studio → Campaign Brief detail (Vendor §3.1, §10.1). Drives
/// the lifecycle actions on one brief: Lock, Fork, Retire, Recompute ROI.
/// Field-level editing (`PATCH`) isn't wired to a form anywhere in this app
/// yet — this screen is read + lifecycle-actions only.
class CampaignBriefDetailScreen extends ConsumerWidget {
  const CampaignBriefDetailScreen({super.key, required this.briefId});

  final String briefId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = campaignDetailNotifierProvider(briefId);
    final state = ref.watch(provider);

    ref.listen<CampaignDetailState>(provider, (previous, next) {
      next.maybeWhen(
        forked: (newBrief) {
          SmSnackbar.info(
            context,
            'Forked to v${newBrief.version}. Now viewing the new draft.',
          );
          context.pushReplacement(
            RouteNames.vendorCampaignBriefDetail.replaceFirst(
              ':briefId',
              newBrief.id,
            ),
          );
        },
        actionFailure: (_, __) =>
            SmSnackbar.error(context, 'Action failed. Please try again.'),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: const BackButton(color: DesignTokens.textWhite),
        title: const Text(
          'Campaign Brief',
          style: DesignTokens.oneLinerSemibold,
        ),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (_) => SmErrorView(
          message: 'Failed to load this brief.',
          onRetry: () => ref.read(provider.notifier).load(),
        ),
        loadSuccess: (brief) => _Body(brief: brief, isBusy: false),
        actionInProgress: (brief) => _Body(brief: brief, isBusy: true),
        actionFailure: (brief, _) => _Body(brief: brief, isBusy: false),
        // Transient — ref.listen above navigates away immediately.
        forked: (brief) => _Body(brief: brief, isBusy: true),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.brief, required this.isBusy});

  final CampaignBrief brief;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(
      campaignDetailNotifierProvider(brief.id).notifier,
    );

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                brief.title?.isNotEmpty == true
                    ? brief.title!
                    : 'Untitled brief',
                style: DesignTokens.titleMedium,
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            _StatusBadge(state: brief.state),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          brief.parentBriefId != null
              ? 'v${brief.version} • forked from a prior version'
              : 'v${brief.version}',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Commission range', style: DesignTokens.smallRegular),
                  Text(
                    '${(brief.commissionMinPercent * 100).toStringAsFixed(0)}–'
                    '${(brief.commissionMaxPercent * 100).toStringAsFixed(0)}%',
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Boost budget', style: DesignTokens.smallRegular),
                  MoneyText(brief.boostBudget, style: DesignTokens.mediumSemibold),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        _RoiCard(roi: brief.roiProjection),
        const SizedBox(height: DesignTokens.s24),
        _Actions(brief: brief, isBusy: isBusy, notifier: notifier),
      ],
    );
  }
}

class _RoiCard extends StatelessWidget {
  const _RoiCard({required this.roi});

  final RoiProjectionSummary? roi;

  @override
  Widget build(BuildContext context) {
    final projection = roi;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ROI Projection', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          if (projection == null)
            Text(
              'No ROI projection yet. Tap "Refresh ROI" to generate one.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            )
          else ...[
            _RoiRow(
              label: 'Estimated reach',
              low: projection.estimatedReachLow.toString(),
              high: projection.estimatedReachHigh.toString(),
            ),
            const SizedBox(height: DesignTokens.s8),
            _RoiRow(
              label: 'Estimated sales',
              low: projection.estimatedSalesLow.toString(),
              high: projection.estimatedSalesHigh.toString(),
            ),
            const SizedBox(height: DesignTokens.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estimated revenue', style: DesignTokens.smallRegular),
                Text(
                  '${_fmtMoney(projection.estimatedRevenueLow)} – '
                  '${_fmtMoney(projection.estimatedRevenueHigh)}',
                  style: DesignTokens.smallRegular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmtMoney(Money m) => '${m.currency} ${m.amount.toStringAsFixed(0)}';
}

class _RoiRow extends StatelessWidget {
  const _RoiRow({required this.label, required this.low, required this.high});

  final String label;
  final String low;
  final String high;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: DesignTokens.smallRegular),
        Text(
          '$low – $high',
          style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final BrandBriefState state;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (state) {
      BrandBriefState.draft => ('Draft', DesignTokens.textMuted),
      BrandBriefState.locked => ('Locked', DesignTokens.primaryGreen),
      BrandBriefState.retired => ('Retired', DesignTokens.colorInfo),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Text(label, style: DesignTokens.tiny.copyWith(color: color)),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.brief,
    required this.isBusy,
    required this.notifier,
  });

  final CampaignBrief brief;
  final bool isBusy;
  final CampaignDetailNotifier notifier;

  @override
  Widget build(BuildContext context) {
    switch (brief.state) {
      case BrandBriefState.draft:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: isBusy ? null : () => _confirmLock(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  shape: const StadiumBorder(),
                ),
                child: isBusy
                    ? const _ButtonSpinner()
                    : const Text(
                        'Lock Brief',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            _InviteCreatorsButton(briefId: brief.id, isBusy: isBusy),
            const SizedBox(height: DesignTokens.s12),
            _SecondaryRow(
              isBusy: isBusy,
              onRefreshRoi: notifier.recomputeRoi,
              onRetire: () => _confirmRetire(context),
            ),
          ],
        );

      case BrandBriefState.locked:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: OutlinedButton(
                onPressed: isBusy ? null : notifier.fork,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DesignTokens.primaryGreen),
                  foregroundColor: DesignTokens.primaryGreen,
                  shape: const StadiumBorder(),
                ),
                child: isBusy
                    ? const _ButtonSpinner(color: DesignTokens.primaryGreen)
                    : const Text('Fork New Draft'),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            _InviteCreatorsButton(briefId: brief.id, isBusy: isBusy),
            const SizedBox(height: DesignTokens.s12),
            _SecondaryRow(
              isBusy: isBusy,
              onRefreshRoi: notifier.recomputeRoi,
              onRetire: () => _confirmRetire(context),
            ),
          ],
        );

      case BrandBriefState.retired:
        return Text(
          'This brief is retired and read-only.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        );
    }
  }

  Future<void> _confirmLock(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Lock this brief?',
          style: TextStyle(color: DesignTokens.textWhite),
        ),
        content: Text(
          'Once locked, this brief is final. To edit it afterwards, fork a '
          'new version.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lock'),
          ),
        ],
      ),
    );
    if (confirmed == true) await notifier.lock();
  }

  Future<void> _confirmRetire(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Retire this brief?',
          style: TextStyle(color: DesignTokens.textWhite),
        ),
        content: Text(
          'Retired briefs are removed from the active list but stay '
          'queryable for history.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Retire'),
          ),
        ],
      ),
    );
    if (confirmed == true) await notifier.retire();
  }
}

class _InviteCreatorsButton extends StatelessWidget {
  const _InviteCreatorsButton({required this.briefId, required this.isBusy});

  final String briefId;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: isBusy
            ? null
            : () => context.push(
                RouteNames.vendorPartnershipsInvite.replaceFirst(
                  ':campaignId',
                  briefId,
                ),
              ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: DesignTokens.primaryGreen),
          foregroundColor: DesignTokens.primaryGreen,
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
        label: const Text('Invite Creators'),
      ),
    );
  }
}

class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow({
    required this.isBusy,
    required this.onRefreshRoi,
    required this.onRetire,
  });

  final bool isBusy;
  final VoidCallback onRefreshRoi;
  final VoidCallback onRetire;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isBusy ? null : onRefreshRoi,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: DesignTokens.borderDefault),
              shape: const StadiumBorder(),
            ),
            child: const Text('Refresh ROI'),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: OutlinedButton(
            onPressed: isBusy ? null : onRetire,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: DesignTokens.colorError),
              foregroundColor: DesignTokens.colorError,
              shape: const StadiumBorder(),
            ),
            child: const Text('Retire'),
          ),
        ),
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({this.color = Colors.black});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}
