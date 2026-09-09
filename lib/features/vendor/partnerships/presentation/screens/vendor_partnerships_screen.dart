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
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/widgets/pending_partnership_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor -> Creator Partnerships hub.
///
/// Figma-aligned layout:
///   * App bar: back arrow + "Creator Partnerships" + search icon.
///   * Tab strip with counts: Active / Pending / Invited / Paused.
///   * Filter / Sort By / Performance chips row below the tabs.
///   * Per-card surface: avatar + name + handle + status chip + 3-dot menu.
///   * Dashed divider followed by performance statistics.
///   * Primary partnership actions live behind the 3-dot menu.
///
/// Messaging:
///   * Selecting `Message` opens the shared ChatView inline.
///   * No additional top-level messaging route is pushed.
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

  /// Active inline chat panel.
  ///
  /// Null means the partnership list is displayed.
  _ChatWith? _chatWith;

  /// Search query used to filter partnerships locally.
  String _searchQuery = '';

  /// Selected status filter.
  _PartnershipFilter _filter = _PartnershipFilter.all;

  /// Display-only sort selection.
  String _sortBy = 'Revenue';

  /// Performance window selection.
  String _metric = 'Performance';

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    _tabCtrl = TabController(
      length: _TabKind.values.length,
      vsync: this,
    );

    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _searchCtrl.text.trim();

    if (value == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = value;
    });
  }

  Future<void> _openMenu(VendorPartnership partnership) async {
    final action = await showModalBottomSheet<_PartnershipAction>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => _PartnershipMenu(
        partnership: partnership,
      ),
    );

    if (action == null || !mounted) {
      return;
    }

    final notifier =
    ref.read(partnershipsListNotifierProvider.notifier);

    switch (action) {
      case _PartnershipAction.viewAnalytics:
        await context.push(
          RouteNames.vendorCreatorAnalytics,
          extra: CreatorAnalyticsArgs(
            partnershipId: partnership.id,
          ),
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

  /// Opens or fetches the messaging thread for a partnership.
  ///
  /// The creator account ID is resolved from the creator profile when it
  /// isn't already present on the partnership.
  Future<void> _openChat(VendorPartnership partnership) async {
    String? otherAccountId;

    if ((partnership.creatorAccountId ?? '').isNotEmpty) {
      otherAccountId = partnership.creatorAccountId;
    } else {
      try {
        final resolved = await ref.read(
          accountByProfileProvider(
            partnership.creatorProfileId,
          ).future,
        );

        if (!mounted) {
          return;
        }

        if (resolved.isEmpty) {
          SmSnackbar.error(
            context,
            'Could not open conversation.',
          );
          return;
        }

        otherAccountId = resolved;
      } catch (_) {
        if (!mounted) {
          return;
        }

        SmSnackbar.error(
          context,
          'Could not open conversation.',
        );
        return;
      }
    }

    if (otherAccountId == null || otherAccountId.isEmpty) {
      if (!mounted) {
        return;
      }

      SmSnackbar.error(
        context,
        'Could not open conversation.',
      );
      return;
    }

    try {
      final repo = ref.read(messagingRepositoryProvider);

      final result = await repo.openThread(
        scope: MessageThreadScope.vendorCreatorPartnership,
        otherParticipantAccountId: otherAccountId,
        contextId: partnership.id,
      );

      if (!mounted) {
        return;
      }

      result.fold(
            (failure) {
          SmSnackbar.error(
            context,
            'Failed to open conversation. Please try again.',
          );
        },
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
    } catch (error) {
      if (!mounted) {
        return;
      }

      SmSnackbar.error(
        context,
        'Failed to open conversation. $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnershipsListNotifierProvider);

    ref.listen<PartnershipsState>(
      partnershipsListNotifierProvider,
          (_, next) {
        next.maybeWhen(
          actionFailure: (_, __) {
            if (mounted) {
              SmSnackbar.error(
                context,
                'Action failed. Please try again.',
              );
            }
          },
          orElse: () {},
        );
      },
    );

    final chat = _chatWith;

    if (chat != null) {
      return _buildChatScreen(chat);
    }

    final all = state.maybeWhen(
      loadSuccess: (partnerships, _) => partnerships,
      actionInProgress: (partnerships) => partnerships,
      actionFailure: (partnerships, _) => partnerships,
      orElse: () => const <VendorPartnership>[],
    );

    final filtered = _applyFiltersAndSearch(all);

    final byTab = <_TabKind, List<VendorPartnership>>{
      for (final tab in _TabKind.values)
        tab: filtered
            .where((p) => _TabKindX.of(p) == tab)
            .toList(growable: false),
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
            onPressed: _showSearchSheet,
          ),
          const SizedBox(
            width: DesignTokens.s4,
          ),
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
              Tab(
                text: '${tab.label} (${byTab[tab]!.length})',
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          if (_searchQuery.isNotEmpty)
            _buildSearchIndicator(),
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
                    .read(
                  partnershipsListNotifierProvider.notifier,
                )
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

  Widget _buildChatScreen(_ChatWith chat) {
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
          onPressed: () {
            setState(() {
              _chatWith = null;
            });
          },
        ),
        title: Text(
          chat.creatorLabel,
          style: DesignTokens.oneLinerSemibold,
        ),
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

  List<VendorPartnership> _applyFiltersAndSearch(
      List<VendorPartnership> partnerships,
      ) {
    Iterable<VendorPartnership> result = partnerships;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();

      result = result.where((partnership) {
        final name = partnership.creatorLabel.toLowerCase();
        final handle = partnership.creatorHandle.toLowerCase();
        final profileId =
        partnership.creatorProfileId.toLowerCase();

        return name.contains(query) ||
            handle.contains(query) ||
            profileId.contains(query);
      });
    }

    switch (_filter) {
      case _PartnershipFilter.all:
        break;

      case _PartnershipFilter.activeOnly:
        result = result.where(
              (partnership) =>
          _TabKindX.of(partnership) == _TabKind.active,
        );
        break;

      case _PartnershipFilter.needsAttention:
        result = result.where(
              (partnership) =>
          _TabKindX.of(partnership) == _TabKind.pending ||
              _TabKindX.of(partnership) == _TabKind.invited,
        );
        break;
    }

    final sorted = result.toList();

    switch (_sortBy) {
      case 'Commission':
        sorted.sort(
              (a, b) => b.commissionMaxPercent.compareTo(
            a.commissionMaxPercent,
          ),
        );

      case 'Sales':
      // Sales are not exposed by VendorPartnership yet.
      // Keep the backend order until analytics data is available.
        break;

      case 'Revenue':
      default:
      // Revenue is not exposed by VendorPartnership yet.
      // Keep the backend order until analytics data is available.
        break;
    }

    return sorted;
  }

  Widget _buildSearchIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        0,
        DesignTokens.s16,
        DesignTokens.s8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 15,
            color: DesignTokens.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Searching for "$_searchQuery"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textMuted,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
            },
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s4,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _OutlineChip(
              assetIcon:
              'assets/images/vendordashboard/icon_filter_alt.png',
              label: _filter == _PartnershipFilter.all
                  ? 'Filter'
                  : _filter.label,
              onTap: _showFilterSheet,
            ),
            const SizedBox(
              width: DesignTokens.s8,
            ),
            _OutlineChip(
              label: 'Sort By',
              trailingIcon:
              Icons.keyboard_arrow_down_rounded,
              onTap: _showSortSheet,
            ),
            const SizedBox(
              width: DesignTokens.s8,
            ),
            _OutlineChip(
              label: _metric,
              trailingIcon:
              Icons.keyboard_arrow_down_rounded,
              onTap: _showMetricSheet,
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (_) => _SearchSheet(
        controller: _searchCtrl,
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (_) => _PickSheet(
        title: 'Filter',
        options: const [
          'All',
          'Active only',
          'Needs attention',
        ],
        selected: _filter.label,
        onPick: (value) {
          setState(() {
            _filter = _PartnershipFilterX.fromLabel(value);
          });
        },
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (_) => _PickSheet(
        title: 'Sort By',
        options: const [
          'Revenue',
          'Sales',
          'Commission',
        ],
        selected: _sortBy,
        onPick: (value) {
          setState(() {
            _sortBy = value;
          });
        },
      ),
    );
  }

  void _showMetricSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (_) => _PickSheet(
        title: 'Performance Window',
        options: const [
          'Performance',
          'Last 30 days',
          'Last 90 days',
        ],
        selected: _metric,
        onPick: (value) {
          setState(() {
            _metric = value;
          });
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Filter
// -----------------------------------------------------------------------------

enum _PartnershipFilter {
  all,
  activeOnly,
  needsAttention,
}

extension _PartnershipFilterX on _PartnershipFilter {
  String get label {
    switch (this) {
      case _PartnershipFilter.all:
        return 'All';

      case _PartnershipFilter.activeOnly:
        return 'Active only';

      case _PartnershipFilter.needsAttention:
        return 'Needs attention';
    }
  }

  static _PartnershipFilter fromLabel(String value) {
    switch (value) {
      case 'Active only':
        return _PartnershipFilter.activeOnly;

      case 'Needs attention':
        return _PartnershipFilter.needsAttention;

      case 'All':
      default:
        return _PartnershipFilter.all;
    }
  }
}

// -----------------------------------------------------------------------------
// Tabs
// -----------------------------------------------------------------------------

enum _TabKind {
  active,
  pending,
  invited,
  paused,
}

extension _TabKindX on _TabKind {
  String get label {
    switch (this) {
      case _TabKind.active:
        return 'Active';

      case _TabKind.pending:
        return 'Pending';

      case _TabKind.invited:
        return 'Invited';

      case _TabKind.paused:
        return 'Paused';
    }
  }

  /// Buckets a loaded partnership into exactly one visible tab.
  ///
  /// Pending = creator-initiated invite awaiting vendor decision.
  /// Invited = vendor-initiated invite awaiting creator decision.
  /// Ended/Declined are folded into Active so the existing four-tab
  /// design remains unchanged.
  static _TabKind of(VendorPartnership partnership) {
    switch (partnership.state) {
      case PartnershipState.active:
        return _TabKind.active;

      case PartnershipState.paused:
        return _TabKind.paused;

      case PartnershipState.invited:
        return partnership.initiatedByCreator
            ? _TabKind.pending
            : _TabKind.invited;

      case PartnershipState.ended:
      case PartnershipState.declined:
        return _TabKind.active;
    }
  }
}

// -----------------------------------------------------------------------------
// Partnership tab
// -----------------------------------------------------------------------------

class _PartnershipsTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (partnerships.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _emptyMessage,
            textAlign: TextAlign.center,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
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
      separatorBuilder: (_, __) => const SizedBox(
        height: DesignTokens.s12,
      ),
      itemBuilder: (_, index) {
        final partnership = partnerships[index];

        // Pending requests use the dedicated Figma-aligned card.
        if (tab == _TabKind.pending) {
          return PendingPartnershipCard(
            request: partnership,
            isBusy: isBusy,
          );
        }

        return _PartnershipCard(
          partnership: partnership,
          isBusy: isBusy,
          onMenu: onMenu,
        );
      },
    );
  }

  String get _emptyMessage {
    switch (tab) {
      case _TabKind.active:
        return 'No active partnerships yet.';

      case _TabKind.pending:
        return 'No pending requests from creators.';

      case _TabKind.invited:
        return 'No outstanding invites.';

      case _TabKind.paused:
        return 'No paused partnerships.';
    }
  }
}

// -----------------------------------------------------------------------------
// Partnership card
// -----------------------------------------------------------------------------

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
        borderRadius: BorderRadius.circular(
          DesignTokens.cardRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(
                logoUrl: partnership.creatorLogoUrl,
                fallback: partnership.creatorLabel,
              ),
              const SizedBox(
                width: DesignTokens.s12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnership.creatorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _handleOrProfileId(partnership),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: DesignTokens.s8,
              ),
              _StatusChip(tab: tab),
              IconButton(
                onPressed: isBusy
                    ? null
                    : () => onMenu(partnership),
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
          const SizedBox(
            height: DesignTokens.s12,
          ),
          _DashedDivider(),
          const SizedBox(
            height: DesignTokens.s12,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
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
          const SizedBox(
            height: DesignTokens.s8,
          ),
          _StatRow(
            assetIcon:
            'assets/images/vendordashboard/Revenue Generated.png',
            label: 'Revenue Generated',
            trailing: _blueChip(
              _placeholderRevenue(),
            ),
          ),
          const Divider(
            color: Color(0x14FFFFFF),
            height: 1,
          ),
          _StatRow(
            assetIcon:
            'assets/images/vendordashboard/icon_reels.png',
            label: 'Reels Published',
            trailing: _plainValue('—'),
          ),
          const Divider(
            color: Color(0x14FFFFFF),
            height: 1,
          ),
          _StatRow(
            assetIcon:
            'assets/images/vendordashboard/icon_partnership.png',
            label: 'Sales',
            trailing: _plainValue('—'),
          ),
          const Divider(
            color: Color(0x14FFFFFF),
            height: 1,
          ),
          _StatRow(
            assetIcon:
            'assets/images/vendordashboard/Views.png',
            label: 'Views',
            trailing: _plainValue('—'),
          ),
          const Divider(
            color: Color(0x14FFFFFF),
            height: 1,
          ),
          _StatRow(
            assetIcon:
            'assets/images/vendordashboard/icon_pending_inquiries.png',
            label: 'Commission Paid',
            trailing: _plainValue(
              '${(partnership.commissionMinPercent * 100).round()}%'
                  '–'
                  '${(partnership.commissionMaxPercent * 100).round()}%',
            ),
          ),
          const Divider(
            color: Color(0x14FFFFFF),
            height: 1,
          ),
          _StatRow(
            assetIcon:
            'assets/images/vendordashboard/Your ROI.png',
            label: 'Your ROI',
            trailing: _plainValue('—'),
          ),
        ],
      ),
    );
  }

  String _handleOrProfileId(VendorPartnership partnership) {
    final handle = partnership.creatorHandle.trim();

    if (handle.isNotEmpty) {
      return handle.startsWith('@') ? handle : '@$handle';
    }

    final profileId = partnership.creatorProfileId.trim();

    if (profileId.isEmpty) {
      return '';
    }

    if (profileId.length >= 6) {
      return '@${profileId.substring(0, 6)}';
    }

    return '@$profileId';
  }

  String _placeholderRevenue() {
    final invited = partnership.invitedAt;
    final since = DateTime.now().difference(invited).inDays;

    if (since <= 0) {
      return 'Rs 0';
    }

    return 'View details';
  }

  Widget _blueChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
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
}

// -----------------------------------------------------------------------------
// Dashed divider
// -----------------------------------------------------------------------------

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashWidth = 6.0;
        const dashGap = 4.0;

        final count =
        (constraints.maxWidth / (dashWidth + dashGap)).floor();

        return Row(
          children: List.generate(
            count,
                (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(
                right: dashGap,
              ),
              color: DesignTokens.borderDefault,
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Avatar
// -----------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar({
    this.logoUrl,
    required this.fallback,
  });

  final String? logoUrl;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;

    final url = logoUrl?.trim() ?? '';

    if (url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _initial(size);
          },
          loadingBuilder: (_, child, progress) {
            if (progress == null) {
              return child;
            }

            return _initial(size);
          },
        ),
      );
    }

    return _initial(size);
  }

  Widget _initial(double size) {
    final value = fallback.trim();

    final letter = value.isEmpty
        ? '?'
        : value.substring(0, 1).toUpperCase();

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

// -----------------------------------------------------------------------------
// Status chip
// -----------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.tab,
  });

  final _TabKind tab;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;

    switch (tab) {
      case _TabKind.active:
        background = DesignTokens.statusOngoingBg;
        foreground = DesignTokens.colorInfo;

      case _TabKind.pending:
        background = DesignTokens.statusOngoingBg;
        foreground = DesignTokens.warning500;

      case _TabKind.invited:
        background = DesignTokens.statusOngoingBg;
        foreground = DesignTokens.warning500;

      case _TabKind.paused:
        background = DesignTokens.statusRemainingBg;
        foreground = DesignTokens.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tab.label,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Stat row
// -----------------------------------------------------------------------------

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
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        children: [
          if (assetIcon != null)
            Image.asset(
              assetIcon!,
              width: 15,
              height: 15,
              color: DesignTokens.textMuted,
              errorBuilder: (_, __, ___) {
                return Icon(
                  icon ?? Icons.circle,
                  size: 15,
                  color: DesignTokens.textMuted,
                );
              },
            )
          else if (icon != null)
            Icon(
              icon,
              size: 15,
              color: DesignTokens.textMuted,
            ),
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

// -----------------------------------------------------------------------------
// Outline chip
// -----------------------------------------------------------------------------

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3A3A3C),
            ),
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
                  errorBuilder: (_, __, ___) {
                    return Icon(
                      icon ?? Icons.tune,
                      size: 14,
                      color: DesignTokens.textLight,
                    );
                  },
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 14,
                  color: DesignTokens.textLight,
                ),
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
                Icon(
                  trailingIcon,
                  size: 16,
                  color: DesignTokens.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pick sheet
// -----------------------------------------------------------------------------

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
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final option in options)
              InkWell(
                onTap: () {
                  onPick(option);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontFamily:
                            DesignTokens.fontFamily,
                            fontSize: 14,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ),
                      Icon(
                        option == selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: option == selected
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

// -----------------------------------------------------------------------------
// Search sheet
// -----------------------------------------------------------------------------

class _SearchSheet extends StatelessWidget {
  const _SearchSheet({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                'Creator name, handle, or profile id',
                hintStyle: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: DesignTokens.textMuted,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: DesignTokens.textMuted,
                  ),
                  onPressed: controller.clear,
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                contentPadding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search updates the partnership list automatically.',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Partnership menu
// -----------------------------------------------------------------------------

enum _PartnershipAction {
  viewAnalytics,
  adjustCommission,
  message,
  pause,
  resume,
  end,
}

class _PartnershipMenu extends StatelessWidget {
  const _PartnershipMenu({
    required this.partnership,
  });

  final VendorPartnership partnership;

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(partnership.state);

    if (items.isEmpty) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            24,
          ),
          child: Text(
            'No actions available.',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(
          top: DesignTokens.s8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(
                bottom: DesignTokens.s12,
              ),
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
                onTap: () {
                  Navigator.of(context).pop(
                    items[i].action,
                  );
                },
              ),
            ],
            const SizedBox(
              height: DesignTokens.s8,
            ),
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
            Icon(
              icon,
              size: 20,
              color: DesignTokens.textLight,
            ),
            const SizedBox(
              width: DesignTokens.s16,
            ),
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

// -----------------------------------------------------------------------------
// Inline chat state
// -----------------------------------------------------------------------------

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