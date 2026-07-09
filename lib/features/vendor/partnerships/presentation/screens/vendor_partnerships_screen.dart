import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/screens/creator_analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/adjust_commission_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── Tab kind ─────────────────────────────────────────────────────────────────

enum _TabKind { active, pending, invited, paused, ended }

extension _TabKindX on _TabKind {
  String get label => switch (this) {
    _TabKind.active => 'Active',
    _TabKind.pending => 'Pending',
    _TabKind.invited => 'Invited',
    _TabKind.paused => 'Paused',
    _TabKind.ended => 'Ended',
  };

  /// Buckets a loaded partnership into exactly one tab. "Pending" is a
  /// creator-initiated request awaiting the vendor's decision; "Invited" is
  /// a vendor-initiated invite awaiting the creator's decision — the
  /// backend uses the same `Invited` state for both, split only by
  /// `initiatedByCreator`. Declined invites are folded into "Ended" since
  /// there's no separate tab for them in this design.
  static _TabKind of(VendorPartnership p) => switch (p.state) {
    PartnershipState.active => _TabKind.active,
    PartnershipState.paused => _TabKind.paused,
    PartnershipState.ended || PartnershipState.declined => _TabKind.ended,
    PartnershipState.invited =>
      p.initiatedByCreator ? _TabKind.pending : _TabKind.invited,
  };
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class VendorPartnershipsScreen extends ConsumerStatefulWidget {
  const VendorPartnershipsScreen({super.key});

  @override
  ConsumerState<VendorPartnershipsScreen> createState() =>
      _VendorPartnershipsScreenState();
}

class _VendorPartnershipsScreenState
    extends ConsumerState<VendorPartnershipsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _TabKind.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnershipsListNotifierProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    ref.listen<PartnershipsState>(partnershipsListNotifierProvider, (
      _,
      next,
    ) {
      next.maybeWhen(
        actionFailure: (_, __) =>
            SmSnackbar.error(context, 'Action failed. Please try again.'),
        orElse: () {},
      );
    });

    final all = state.maybeWhen(
      loadSuccess: (partnerships, _) => partnerships,
      actionInProgress: (partnerships) => partnerships,
      actionFailure: (partnerships, _) => partnerships,
      orElse: () => const <VendorPartnership>[],
    );
    final byTab = <_TabKind, List<VendorPartnership>>{
      for (final tab in _TabKind.values)
        tab: all.where((p) => _TabKindX.of(p) == tab).toList(growable: false),
    };
    final isBusy = state.maybeWhen(
      actionInProgress: (_) => true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: const BackButton(color: DesignTokens.textWhite),
        titleSpacing: 0,
        title: const Text(
          'Creator Partnerships',
          style: DesignTokens.titleMedium,
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: DesignTokens.primaryGreen,
          indicatorWeight: 2,
          labelColor: DesignTokens.primaryGreen,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: [
            for (final tab in _TabKind.values)
              Tab(text: '${tab.label}(${byTab[tab]!.length})'),
          ],
        ),
      ),
      body: Stack(
        children: [
          state.maybeWhen(
            loadInProgress: () => const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
              ),
            ),
            loadFailure: (_) => SmErrorView(
              message: 'Failed to load partnerships.',
              onRetry: () =>
                  ref.read(partnershipsListNotifierProvider.notifier).load(),
            ),
            orElse: () => TabBarView(
              controller: _tabCtrl,
              children: [
                for (final tab in _TabKind.values)
                  _PartnershipsTab(
                    tab: tab,
                    partnerships: byTab[tab]!,
                    isBusy: isBusy,
                  ),
              ],
            ),
          ),
          Positioned(
            left: DesignTokens.s16,
            right: DesignTokens.s16,
            bottom: DesignTokens.s16 + bottomPad,
            child: SizedBox(
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.textDark,
                  shape: const StadiumBorder(),
                  elevation: 4,
                ),
                onPressed: () =>
                    context.push(RouteNames.vendorSendPartnershipRequest),
                child: const Text(
                  'Send Partnership Requests',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF09090B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab body ────────────────────────────────────────────────────────────────

class _PartnershipsTab extends ConsumerWidget {
  const _PartnershipsTab({
    required this.tab,
    required this.partnerships,
    required this.isBusy,
  });

  final _TabKind tab;
  final List<VendorPartnership> partnerships;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (partnerships.isEmpty) {
      return Center(
        child: Text(
          _emptyMessage,
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        88,
      ),
      itemCount: partnerships.length,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) =>
          _PartnershipCard(partnership: partnerships[i], isBusy: isBusy),
    );
  }

  String get _emptyMessage => switch (tab) {
    _TabKind.active => 'No active partnerships yet.',
    _TabKind.pending => 'No pending requests from creators.',
    _TabKind.invited => 'No outstanding invites.',
    _TabKind.paused => 'No paused partnerships.',
    _TabKind.ended => 'No ended partnerships.',
  };
}

// ─── Partnership card ────────────────────────────────────────────────────────

class _PartnershipCard extends ConsumerWidget {
  const _PartnershipCard({required this.partnership, required this.isBusy});

  final VendorPartnership partnership;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = _TabKindX.of(partnership);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: DesignTokens.bgAppBodyLight,
                child: Text(
                  partnership.creatorLabel.characters.first,
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Text(
                  partnership.creatorLabel,
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
              _StatusChip(tab: tab),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Commission: '
              '${(partnership.commissionMinPercent * 100).round()}%'
              '–${(partnership.commissionMaxPercent * 100).round()}%',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if ((partnership.requestMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                partnership.requestMessage!,
                style: DesignTokens.smallRegular,
              ),
            ),
          ],
          if (tab == _TabKind.ended && partnership.endReason != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Ended: ${partnership.endReason}',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          _Actions(partnership: partnership, tab: tab, isBusy: isBusy),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.tab});

  final _TabKind tab;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tab) {
      _TabKind.active => (DesignTokens.statusOngoingBg, DesignTokens.colorInfo),
      _TabKind.pending => (
        DesignTokens.statusOngoingBg,
        DesignTokens.warning500,
      ),
      _TabKind.invited => (
        DesignTokens.statusOngoingBg,
        DesignTokens.warning500,
      ),
      _TabKind.paused => (
        DesignTokens.statusRemainingBg,
        DesignTokens.textMuted,
      ),
      _TabKind.ended => (
        DesignTokens.statusCompletedBg,
        DesignTokens.textMuted,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(tab.label, style: DesignTokens.tiny.copyWith(color: fg)),
    );
  }
}

// ─── Actions ─────────────────────────────────────────────────────────────────

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.partnership,
    required this.tab,
    required this.isBusy,
  });

  final VendorPartnership partnership;
  final _TabKind tab;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(partnershipsListNotifierProvider.notifier);

    switch (tab) {
      case _TabKind.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy
                    ? null
                    : () => notifier.declineRequest(partnership.id),
                style: _outlineStyle(DesignTokens.borderDefault),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy
                    ? null
                    : () => notifier.acceptRequest(partnership.id),
                style: _outlineStyle(DesignTokens.primaryGreen),
                child: const Text('Accept'),
              ),
            ),
          ],
        );

      case _TabKind.invited:
        return Row(
          children: [
            Expanded(
              child: Text(
                "Awaiting creator's response",
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => SmSnackbar.info(
                context,
                'Direct messaging is coming soon.',
              ),
              style: _outlineStyle(DesignTokens.borderDefault),
              child: const Text('Message'),
            ),
          ],
        );

      case _TabKind.active:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      RouteNames.vendorCreatorAnalytics,
                      extra: CreatorAnalyticsArgs(
                        partnershipId: partnership.id,
                      ),
                    ),
                    style: _outlineStyle(DesignTokens.borderDefault),
                    child: const Text('View Analytics'),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      RouteNames.vendorAdjustCommission,
                      extra: AdjustCommissionArgs(
                        partnershipId: partnership.id,
                        creatorLabel: partnership.creatorLabel,
                        currentMinPercent: partnership.commissionMinPercent,
                        currentMaxPercent: partnership.commissionMaxPercent,
                      ),
                    ),
                    style: _outlineStyle(DesignTokens.borderDefault),
                    child: const Text('Adjust Commission'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => SmSnackbar.info(
                      context,
                      'Direct messaging is coming soon.',
                    ),
                    style: _outlineStyle(DesignTokens.borderDefault),
                    child: const Text('Message'),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => notifier.pause(partnership.id),
                    style: _outlineStyle(DesignTokens.warning500),
                    child: const Text('Pause'),
                  ),
                ),
              ],
            ),
          ],
        );

      case _TabKind.paused:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy
                    ? null
                    : () => notifier.resume(partnership.id),
                style: _outlineStyle(DesignTokens.primaryGreen),
                child: const Text('Resume'),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : () => notifier.end(partnership.id),
                style: _outlineStyle(DesignTokens.colorError),
                child: const Text('End'),
              ),
            ),
          ],
        );

      case _TabKind.ended:
        return const SizedBox.shrink();
    }
  }

  ButtonStyle _outlineStyle(Color color) => OutlinedButton.styleFrom(
    side: BorderSide(color: color),
    shape: const StadiumBorder(),
    foregroundColor: color,
    padding: const EdgeInsets.symmetric(vertical: 12),
    textStyle: const TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );
}
