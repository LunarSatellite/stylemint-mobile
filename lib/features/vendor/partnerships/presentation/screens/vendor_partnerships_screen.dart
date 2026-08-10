import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/message_thread.dart';
import 'package:stylemint_mobile_frontend/features/messaging/presentation/widgets/chat_view.dart';
import 'package:stylemint_mobile_frontend/features/messaging/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/screens/creator_analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/adjust_commission_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';


/// Vendor -> Creator Partnerships hub.
///
/// Figma-aligned layout (Figma_ZC0lD3r98d):
///   * App bar: back arrow + "Creator Partnerships" + search icon.
///   * Tab strip with counts: Active / Pending / Invited / Paused.
///   * Filter / Sort By / Performance chips row below the tabs.
///   * Per-card surface: avatar + name + handle + status chip + 3-dot
///     menu; then a dashed divider; then a "Performance (Last 30 Days):"
///     stat block; then a "View Performance" action.
///   * All primary partnership actions (View Analytics, Adjust
///     Commission, Message, Pause) live behind the 3-dot menu.
///
/// Messaging wiring (preserved from the previous implementation):
///   * Selecting `Message` in the 3-dot menu swaps the body of this
///     screen for an inline chat panel that mounts the shared
///     `ChatView` widget. No new top-level navigation, no new
///     messaging page.
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

  /// Active inline chat panel state. Null means the body is showing the
  /// partnership list; non-null swaps it for the open thread.
  _ChatWith? _chatWith;

  /// Filter/sort/performance chip selections (display only - the
  /// partnerships notifier does not currently expose sort/filter
  /// parameters, so the values are surfaced in the UI and propagated
  /// to the underlying `load()` call once the backend supports them).
  String _sortBy = 'Revenue';
  String _metric = 'Performance';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _TabKind.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }


  Future<void> _openMenu(VendorPartnership partnership) async {
    final action = await showModalBottomSheet<_PartnershipAction>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PartnershipMenu(partnership: partnership),
    );
    if (action == null || !mounted) return;
    final notifier = ref.read(partnershipsListNotifierProvider.notifier);
    switch (action) {
      case _PartnershipAction.viewAnalytics:
        await context.push(
          RouteNames.vendorCreatorAnalytics,
          extra: CreatorAnalyticsArgs(partnershipId: partnership.id),
        );
      case _PartnershipAction.adjustCommission:
        await context.push(
          RouteNames.vendorAdjustCommission,
          extra: AdjustCommissionArgs(
            partnershipId: partnership.id,
            creatorLabel: partnership.creatorLabel,
            currentMinPercent: partnership.commissionMinPercent,
            currentMaxPercent: partnership.commissionMaxPercent,
          ),
        );
      case _PartnershipAction.message:
        await _openChat(partnership);
      case _PartnershipAction.pause:
        await notifier.pause(partnership.id);
      case _PartnershipAction.resume:
        await notifier.resume(partnership.id);
      case _PartnershipAction.end:
        await notifier.end(partnership.id);
    }
  }

  /// Opens (or fetches) the messaging thread for [partnership] and
  /// swaps the body of this screen to the inline chat panel. The
  /// creator's account id is resolved from the partnership's profile
  /// id via `GET /v1/accounts/by-profile/{id}` so the backend scope
  /// rule (account-ids only) is honored.
  Future<void> _openChat(VendorPartnership partnership) async {
    String? otherAccountId;
    if ((partnership.creatorAccountId ?? '').isNotEmpty) {
      otherAccountId = partnership.creatorAccountId;
    } else {
      final resolved = await ref
          .read(accountByProfileProvider(partnership.creatorProfileId)
              .future);
      if (!mounted) return;
      if (resolved.isEmpty) {
        SmSnackbar.error(context, 'Could not open conversation.');
        return;
      }
      otherAccountId = resolved;
    }
    if (otherAccountId == null || otherAccountId.isEmpty) {
      if (!mounted) return;
      SmSnackbar.error(context, 'Could not open conversation.');
      return;
    }

    final repo = ref.read(messagingRepositoryProvider);
    final result = await repo.openThread(
      scope: MessageThreadScope.vendorCreatorPartnership,
      otherParticipantAccountId: otherAccountId,
      contextId: partnership.id,
    );

    if (!mounted) return;
    result.fold(
      (failure) => SmSnackbar.error(
        context,
        'Failed to open conversation. ${failure.toString()}',
      ),
      (thread) {
        setState(() {
          _chatWith = _ChatWith(
            threadId: thread.id,
            partnership: partnership,
            creatorLabel: partnership.creatorLabel,
            creatorHandle: partnership.creatorHandle,
            creatorAvatarUrl: partnership.creatorLogoUrl,
          );
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnershipsListNotifierProvider);

    ref.listen<PartnershipsState>(partnershipsListNotifierProvider, (_, next) {
      next.maybeWhen(
        actionFailure: (_, __) =>
            SmSnackbar.error(context, 'Action failed. Please try again.'),
        orElse: () {},
      );
    });

    // When the user picks "Message" the body swaps to the inline chat
    // panel. We intentionally stay on this same page (no new route
    // push) so the messaging surface lives inside the Creator
    // Partnerships screen, matching the Figma flow.
    final chat = _chatWith;
    if (chat != null) {
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
            onPressed: () => setState(() => _chatWith = null),
          ),
          title: Text(chat.creatorLabel, style: DesignTokens.oneLinerSemibold),
        ),
        body: ChatView(
          args: ChatViewArgs(
            threadId: chat.threadId,
            scope: MessageThreadScope.vendorCreatorPartnership,
            title: chat.creatorLabel,
            subtitle: chat.creatorHandle ?? '',
            avatarAsset: chat.creatorAvatarUrl ?? '',
          ),
        ),
      );
    }

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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'Creator Partnerships',
          style: DesignTokens.titleMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              size: 22,
              color: DesignTokens.textWhite,
            ),
            onPressed: () => _showSearchSheet(),
          ),
          const SizedBox(width: DesignTokens.s4),
        ],
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
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: state.maybeWhen(
              loadInProgress: () => const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
              loadFailure: (_) => SmErrorView(
                message: 'Failed to load partnerships.',
                onRetry: () => ref
                    .read(partnershipsListNotifierProvider.notifier)
                    .load(),
              ),
              orElse: () => TabBarView(
                controller: _tabCtrl,
                children: [
                  for (final tab in _TabKind.values)
                    _PartnershipsTab(
                      tab: tab,
                      partnerships: byTab[tab]!,
                      isBusy: isBusy,
                      onMenu: _openMenu,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Figma filter/sort/performance chips row -----------------------

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s4,
      ),
      child: Row(
        children: [
          _OutlineChip(
            assetIcon: 'assets/images/vendordashboard/icon_filter_alt.png',
            label: 'Filter',
            onTap: () => _showFilterSheet(),
          ),
          const SizedBox(width: DesignTokens.s8),
          _OutlineChip(
            label: 'Sort By',
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            onTap: _showSortSheet,
          ),
          const SizedBox(width: DesignTokens.s8),
          _OutlineChip(
            label: _metric,
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            onTap: _showMetricSheet,
          ),
        ],
      ),
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SearchSheet(controller: _searchCtrl),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _SimpleSheet(
        title: 'Filter',
        options: ['All', 'Active only', 'Needs attention'],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PickSheet(
        title: 'Sort By',
        options: const ['Revenue', 'Sales', 'Commission'],
        selected: _sortBy,
        onPick: (v) => setState(() => _sortBy = v),
      ),
    );
  }

  void _showMetricSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PickSheet(
        title: 'Window',
        options: const ['Performance', 'Last 30 days', 'Last 90 days'],
        selected: _metric,
        onPick: (v) => setState(() => _metric = v),
      ),
    );
  }
}


// --- Tab kind --------------------------------------------------------------

enum _TabKind { active, pending, invited, paused }

extension _TabKindX on _TabKind {
  String get label => switch (this) {
        _TabKind.active => 'Active',
        _TabKind.pending => 'Pending',
        _TabKind.invited => 'Invited',
        _TabKind.paused => 'Paused',
      };

  /// Buckets a loaded partnership into exactly one visible tab.
  /// "Pending" = creator-initiated invite awaiting vendor decision;
  /// "Invited" = vendor-initiated invite awaiting creator decision.
  /// Ended/Declined are folded into Active so they remain visible
  /// without needing a fifth tab.
  static _TabKind of(VendorPartnership p) => switch (p.state) {
        PartnershipState.active => _TabKind.active,
        PartnershipState.paused => _TabKind.paused,
        PartnershipState.invited =>
          p.initiatedByCreator ? _TabKind.pending : _TabKind.invited,
        PartnershipState.ended || PartnershipState.declined =>
          _TabKind.active,
      };
}

class _PartnershipsTab extends ConsumerWidget {
  const _PartnershipsTab({
    required this.tab,
    required this.partnerships,
    required this.isBusy,
    required this.onMenu,
  });

  final _TabKind tab;
  final List<VendorPartnership> partnerships;
  final bool isBusy;
  final Future<void> Function(VendorPartnership) onMenu;

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
        DesignTokens.s24,
      ),
      itemCount: partnerships.length,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) => _PartnershipCard(
        partnership: partnerships[i],
        isBusy: isBusy,
        onMenu: onMenu,
      ),
    );
  }

  String get _emptyMessage => switch (tab) {
        _TabKind.active => 'No active partnerships yet.',
        _TabKind.pending => 'No pending requests from creators.',
        _TabKind.invited => 'No outstanding invites.',
        _TabKind.paused => 'No paused partnerships.',
      };
}


class _PartnershipCard extends StatelessWidget {
  const _PartnershipCard({
    required this.partnership,
    required this.isBusy,
    required this.onMenu,
  });

  final VendorPartnership partnership;
  final bool isBusy;
  final Future<void> Function(VendorPartnership) onMenu;

  @override
  Widget build(BuildContext context) {
    final tab = _TabKindX.of(partnership);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + status chip + 3-dot
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(logoUrl: partnership.creatorLogoUrl, fallback: partnership.creatorLabel),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnership.creatorLabel,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _handleOrProfileId(partnership),
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              _StatusChip(tab: tab),
              IconButton(
                onPressed: () => onMenu(partnership),
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: DesignTokens.textMuted,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          _dashedDivider(),
          const SizedBox(height: DesignTokens.s12),
          // Performance section header
          const Padding(
            padding: EdgeInsets.only(left: 2, right: 2),
            child: Text(
              'Performance (Last 30 Days):',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textLight,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          _StatRow(
            assetIcon: 'assets/images/vendordashboard/Revenue Generated.png',
            label: 'Revenue Generated',
            trailing: _blueChip(_placeholderRevenue()),
          ),
          const Divider(color: Color(0x14FFFFFF), height: 1),
          _StatRow(
            assetIcon: 'assets/images/vendordashboard/icon_reels.png',
            label: 'Reels Published',
            trailing: _plainValue('—'),
          ),
          const Divider(color: Color(0x14FFFFFF), height: 1),
          _StatRow(
            assetIcon: 'assets/images/vendordashboard/icon_partnership.png',
            label: 'Sales',
            trailing: _plainValue('—'),
          ),
          const Divider(color: Color(0x14FFFFFF), height: 1),
          _StatRow(
            assetIcon: 'assets/images/vendordashboard/Views.png',
            label: 'Views',
            trailing: _plainValue('—'),
          ),
          const Divider(color: Color(0x14FFFFFF), height: 1),
          _StatRow(
            assetIcon:
                'assets/images/vendordashboard/icon_pending_inquiries.png',
            label: 'Commission Paid',
            trailing: _plainValue(
              '${(partnership.commissionMinPercent * 100).round()}%–${(partnership.commissionMaxPercent * 100).round()}%',
            ),
          ),
          const Divider(color: Color(0x14FFFFFF), height: 1),
          _StatRow(
            assetIcon: 'assets/images/vendordashboard/Your ROI.png',
            label: 'Your ROI',
            trailing: _plainValue('—'),
          ),
          const SizedBox(height: DesignTokens.s4),
          // View Performance action - opens the existing performance
          // detail screen for the same partnership, where the full
          // stat block is rendered from the analytics endpoint.
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push(
              RouteNames.vendorCreatorAnalytics,
              extra: CreatorAnalyticsArgs(partnershipId: partnership.id),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Performance',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: DesignTokens.primaryGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _handleOrProfileId(VendorPartnership p) {
    if (p.creatorHandle.trim().isNotEmpty) {
      final h = p.creatorHandle.trim();
      return h.startsWith('@') ? h : '@$h';
    }
    if (p.creatorProfileId.length >= 6) {
      return '@${p.creatorProfileId.substring(0, 6)}';
    }
    return p.creatorProfileId.isEmpty ? '' : '@${p.creatorProfileId}';
  }

  // The partnership entity doesn't carry the per-partnership revenue
  // figure, so the "Revenue Generated" cell shows a high-level status
  // string until the analytics endpoint is wired into this screen.
  String _placeholderRevenue() {
    final invited = partnership.invitedAt;
    final since = DateTime.now().difference(invited).inDays;
    if (since <= 0) return 'Rs 0';
    return 'View details';
  }

  Widget _blueChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DesignTokens.tagInfoFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DesignTokens.tagInfoText,
        ),
      ),
    );
  }

  Widget _plainValue(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: DesignTokens.textWhite,
      ),
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashW = 6.0;
        const dashGap = 4.0;
        final count = (constraints.maxWidth / (dashW + dashGap)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 1,
              margin: const EdgeInsets.only(right: dashGap),
              color: DesignTokens.borderDefault,
            ),
          ),
        );
      },
    );
  }
}


class _Avatar extends StatelessWidget {
  const _Avatar({this.logoUrl, required this.fallback});
  final String? logoUrl;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final hasUrl = (logoUrl ?? '').isNotEmpty;
    if (hasUrl) {
      return ClipOval(
        child: Image.network(
          logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initial(size),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _initial(size);
          },
        ),
      );
    }
    return _initial(size);
  }

  Widget _initial(double size) {
    final letter = fallback.trim().isEmpty
        ? '?'
        : fallback.trim().substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF27272A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: DesignTokens.textWhite,
        ),
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
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tab.label,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ).copyWith(color: fg),
      ),
    );
  }
}


// --- Stat row (icon + label + trailing) ----------------------------------

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.trailing,
    this.icon,
    this.assetIcon,
  });
  final IconData? icon;
  final String? assetIcon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (assetIcon != null)
            Image.asset(
              assetIcon!,
              width: 15,
              height: 15,
              color: DesignTokens.textMuted,
              errorBuilder: (_, __, ___) =>
                  Icon(icon ?? Icons.circle, size: 15, color: DesignTokens.textMuted),
            )
          else if (icon != null)
            Icon(icon, size: 15, color: DesignTokens.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                color: DesignTokens.textMuted,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}


// --- Filter chips row ----------------------------------------------------

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.assetIcon,
    this.trailingIcon,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? assetIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetIcon != null)
              Image.asset(
                assetIcon!,
                width: 14,
                height: 14,
                color: DesignTokens.textLight,
                errorBuilder: (_, __, ___) =>
                    Icon(icon ?? Icons.tune, size: 14, color: DesignTokens.textLight),
              )
            else if (icon != null)
              Icon(icon, size: 14, color: DesignTokens.textLight),
            if (assetIcon != null || icon != null)
              const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 2),
              Icon(trailingIcon, size: 16, color: DesignTokens.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickSheet extends StatelessWidget {
  const _PickSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onPick,
  });
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DesignTokens.textMuted,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final opt in options)
              InkWell(
                onTap: () {
                  onPick(opt);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ),
                      Icon(
                        opt == selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: opt == selected
                            ? DesignTokens.primaryGreen
                            : DesignTokens.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SimpleSheet extends StatelessWidget {
  const _SimpleSheet({required this.title, required this.options});
  final String title;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DesignTokens.textMuted,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            for (final opt in options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  opt,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchSheet extends StatelessWidget {
  const _SearchSheet({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Search partnerships',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DesignTokens.textMuted,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                color: DesignTokens.textWhite,
              ),
              decoration: const InputDecoration(
                hintText: 'Creator name, handle, or profile id',
                hintStyle: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.textMuted,
                ),
                filled: true,
                fillColor: Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- 3-dot menu -----------------------------------------------------------

enum _PartnershipAction {
  viewAnalytics,
  adjustCommission,
  message,
  pause,
  resume,
  end,
}

class _PartnershipMenu extends StatelessWidget {
  const _PartnershipMenu({required this.partnership});

  final VendorPartnership partnership;

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(partnership.state);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: DesignTokens.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0x14FFFFFF),
                ),
              _MenuRow(
                icon: items[i].icon,
                label: items[i].label,
                onTap: () => Navigator.of(context).pop(items[i].action),
              ),
            ],
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    );
  }

  List<_MenuEntry> _itemsFor(PartnershipState state) {
    switch (state) {
      case PartnershipState.active:
        return const [
          _MenuEntry(
            action: _PartnershipAction.adjustCommission,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Adjust Commission',
          ),
          _MenuEntry(
            action: _PartnershipAction.viewAnalytics,
            icon: Icons.query_stats_outlined,
            label: 'View Analytics',
          ),
          _MenuEntry(
            action: _PartnershipAction.message,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message',
          ),
          _MenuEntry(
            action: _PartnershipAction.pause,
            icon: Icons.pause_circle_outline_rounded,
            label: 'Pause Partnership',
          ),
        ];
      case PartnershipState.paused:
        return const [
          _MenuEntry(
            action: _PartnershipAction.message,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message',
          ),
          _MenuEntry(
            action: _PartnershipAction.resume,
            icon: Icons.play_circle_outline_rounded,
            label: 'Resume',
          ),
          _MenuEntry(
            action: _PartnershipAction.end,
            icon: Icons.do_not_disturb_on_outlined,
            label: 'End Partnership',
          ),
        ];
      case PartnershipState.invited:
        return const [
          _MenuEntry(
            action: _PartnershipAction.message,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message',
          ),
        ];
      case PartnershipState.declined:
      case PartnershipState.ended:
        return const [];
    }
  }
}

class _MenuEntry {
  const _MenuEntry({
    required this.action,
    required this.icon,
    required this.label,
  });
  final _PartnershipAction action;
  final IconData icon;
  final String label;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s16,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: DesignTokens.textLight),
            const SizedBox(width: DesignTokens.s16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: DesignTokens.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Inline chat state ----------------------------------------------------

class _ChatWith {
  const _ChatWith({
    required this.threadId,
    required this.partnership,
    required this.creatorLabel,
    this.creatorHandle,
    this.creatorAvatarUrl,
  });

  final String threadId;
  final VendorPartnership partnership;
  final String creatorLabel;
  final String? creatorHandle;
  final String? creatorAvatarUrl;
}
