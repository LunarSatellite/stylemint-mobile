import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/screens/creator_analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/adjust_commission_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/message_creator_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── Tab kind ─────────────────────────────────────────────────────────────────

enum _TabKind { active, invited, paused, ended }

// ─── Mock data models ─────────────────────────────────────────────────────────

class _InvitedInvitation {
  const _InvitedInvitation({
    required this.name,
    required this.handle,
    required this.followersLabel,
    required this.stars,
    required this.proposedCommission,
    required this.message,
    this.avatarBg = const Color(0xFF27272A),
  });

  final String name;
  final String handle;
  final String followersLabel;
  final double stars;
  final int proposedCommission;
  final String message;
  final Color avatarBg;
}

class _CreatorPartner {
  const _CreatorPartner({
    required this.name,
    required this.handle,
    required this.category,
    required this.followersLabel,
    required this.stars,
    required this.revenueGenerated,
    required this.reelsPublished,
    required this.sales,
    required this.viewsLabel,
    required this.commissionPaid,
    required this.roi,
    this.avatarBg = const Color(0xFF27272A),
  });

  final String name;
  final String handle;
  final String category;
  final String followersLabel;
  final double stars;
  final String revenueGenerated;
  final int reelsPublished;
  final int sales;
  final String viewsLabel;
  final String commissionPaid;
  final String roi;
  final Color avatarBg;
}

class _PendingRequest {
  const _PendingRequest({
    required this.name,
    required this.handle,
    required this.followersLabel,
    required this.commissionMin,
    required this.commissionMax,
    required this.message,
    this.avatarBg = const Color(0xFF27272A),
  });

  final String name;
  final String handle;
  final String followersLabel;
  final int commissionMin;
  final int commissionMax;
  final String message;
  final Color avatarBg;
}

// ─── Mock data ────────────────────────────────────────────────────────────────

const _activeCreators = [
  _CreatorPartner(
    name: 'Nhuga Fitness',
    handle: '@nhuga_fitness',
    category: 'Sports & Fitness',
    followersLabel: '15k',
    stars: 4.8,
    revenueGenerated: 'Rs 4,56,770.09',
    reelsPublished: 5,
    sales: 389,
    viewsLabel: '127.8m',
    commissionPaid: 'Rs 23,889.98',
    roi: '567%',
    avatarBg: Color(0xFF1A3A6A),
  ),
  _CreatorPartner(
    name: 'Zin Rabia',
    handle: '@rabia.zin',
    category: 'Sports & Fitness',
    followersLabel: '3.2m',
    stars: 4.4,
    revenueGenerated: 'Rs 3,56,876',
    reelsPublished: 8,
    sales: 345,
    viewsLabel: '16.8m',
    commissionPaid: 'Rs 23,889.98',
    roi: '567%',
    avatarBg: Color(0xFF6A2252),
  ),
  _CreatorPartner(
    name: 'Shree Teen',
    handle: '@aileen.ace43',
    category: 'Fashion & Lifestyle',
    followersLabel: '52.3k',
    stars: 4.9,
    revenueGenerated: 'Rs 1,25,569.96',
    reelsPublished: 12,
    sales: 43,
    viewsLabel: '2.2m',
    commissionPaid: 'Rs 23,889.98',
    roi: '567%',
    avatarBg: Color(0xFF3A1A2A),
  ),
  _CreatorPartner(
    name: 'Sarah Addams',
    handle: '@rabia.zin',
    category: 'Fashion & Fitness',
    followersLabel: '101.3k',
    stars: 5.0,
    revenueGenerated: 'Rs 68,986.25',
    reelsPublished: 3,
    sales: 21,
    viewsLabel: '415.2k',
    commissionPaid: 'Rs 23,889.98',
    roi: '567%',
    avatarBg: Color(0xFF2A1A3A),
  ),
];

const _pendingRequests = [
  _PendingRequest(
    name: 'Immovable Royale',
    handle: '@immovableroyale',
    followersLabel: '101k',
    commissionMin: 12,
    commissionMax: 18,
    message:
        "Hi, Ritesh ! We love your sports content and think you'd be a great fit for our new winter collection. Intereseted in a collaboration",
    avatarBg: Color(0xFF4A1A6A),
  ),
  _PendingRequest(
    name: 'Eleven Jane',
    handle: '@eljane2025',
    followersLabel: '2.1m',
    commissionMin: 15,
    commissionMax: 18,
    message:
        'Hi, Ritesh ! We are launching a brand new segment of products targeted to fitness and sports enthusiasts. We really like the content you make in this genre and we are hoping t...',
    avatarBg: Color(0xFF6A2A1A),
  ),
];

const _invitedInvitations = [
  _InvitedInvitation(
    name: 'Sarah Addams',
    handle: '@rabia.zin',
    followersLabel: '101.3k',
    stars: 5.0,
    proposedCommission: 16,
    message:
        "Hi, Sarah ! We love your sports content and think you'd be a great fit for our new winter collection. Interested in a collaboration",
    avatarBg: Color(0xFF2A1A3A),
  ),
  _InvitedInvitation(
    name: 'Ruben Diaz',
    handle: '@diazmednoruns',
    followersLabel: '232k',
    stars: 4.8,
    proposedCommission: 18,
    message:
        "Hi, Ruben ! We love your sports content and think you'd be a great fit for our new winter collection. Interested in a collaboration",
    avatarBg: Color(0xFF3A2A1A),
  ),
];

const _pausedCreators = [
  _CreatorPartner(
    name: 'Shree Teen',
    handle: '@aileen.ace43',
    category: 'Fashion & Lifestyle',
    followersLabel: '52.3k',
    stars: 4.9,
    revenueGenerated: 'Rs 1,25,569.96',
    reelsPublished: 12,
    sales: 43,
    viewsLabel: '2.2m',
    commissionPaid: 'Rs 23,889.98',
    roi: '567%',
    avatarBg: Color(0xFF3A1A2A),
  ),
  _CreatorPartner(
    name: 'Maya Torres',
    handle: '@mayatorres',
    category: 'Beauty & Skincare',
    followersLabel: '7.4k',
    stars: 4.2,
    revenueGenerated: 'Rs 38,100.00',
    reelsPublished: 7,
    sales: 89,
    viewsLabel: '1.1m',
    commissionPaid: 'Rs 5,400.00',
    roi: '180%',
    avatarBg: Color(0xFF4A3A1A),
  ),
];

const _endedCreators = [
  _CreatorPartner(
    name: 'Sarah Addams',
    handle: '@rabia.zin',
    category: 'Fashion & Fitness',
    followersLabel: '101.3k',
    stars: 5.0,
    revenueGenerated: 'Rs 68,986.25',
    reelsPublished: 3,
    sales: 21,
    viewsLabel: '415.2k',
    commissionPaid: 'Rs 23,889.98',
    roi: '567%',
    avatarBg: Color(0xFF2A1A3A),
  ),
  _CreatorPartner(
    name: 'Nhuga Fitness',
    handle: '@nhuga_fitness',
    category: 'Sports & Fitness',
    followersLabel: '15k',
    stars: 4.8,
    revenueGenerated: 'Rs 4,56,770.09',
    reelsPublished: 5,
    sales: 389,
    viewsLabel: '127.8m',
    commissionPaid: 'Rs 23,889.98',
    roi: '567%',
    avatarBg: Color(0xFF1A3A6A),
  ),
  _CreatorPartner(
    name: 'Priya Shah',
    handle: '@priyashah',
    category: 'Food & Cooking',
    followersLabel: '19.2k',
    stars: 4.7,
    revenueGenerated: 'Rs 1,12,300.00',
    reelsPublished: 9,
    sales: 156,
    viewsLabel: '6.3m',
    commissionPaid: 'Rs 14,600.00',
    roi: '390%',
    avatarBg: Color(0xFF5A1A1A),
  ),
  _CreatorPartner(
    name: 'Leon Park',
    handle: '@leonpark',
    category: 'Tech & Gadgets',
    followersLabel: '45.0k',
    stars: 4.3,
    revenueGenerated: 'Rs 2,34,000.00',
    reelsPublished: 11,
    sales: 210,
    viewsLabel: '9.7m',
    commissionPaid: 'Rs 30,200.00',
    roi: '480%',
    avatarBg: Color(0xFF1A2A4A),
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class VendorPartnershipsScreen extends StatefulWidget {
  const VendorPartnershipsScreen({super.key});

  @override
  State<VendorPartnershipsScreen> createState() =>
      _VendorPartnershipsScreenState();
}

class _VendorPartnershipsScreenState extends State<VendorPartnershipsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _tabs = [
    (label: 'Active(4)', count: 4),
    (label: 'Pending(2)', count: 2),
    (label: 'Invited(2)', count: 2),
    (label: 'Paused(2)', count: 2),
    (label: 'Ended(4)', count: 4),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: DesignTokens.textWhite),
            onPressed: () {},
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
            for (final t in _tabs) Tab(text: t.label),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabCtrl,
            children: [
              _PerformanceTab(creators: _activeCreators),
              _PendingTab(),
              _InvitedTab(),
              _PerformanceTab(
                creators: _pausedCreators,
                tabKind: _TabKind.paused,
              ),
              _PerformanceTab(
                creators: _endedCreators,
                tabKind: _TabKind.ended,
              ),
            ],
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

// ─── Performance tab (Active / Invited / Paused / Ended) ─────────────────────

class _PerformanceTab extends StatelessWidget {
  const _PerformanceTab({
    required this.creators,
    this.tabKind = _TabKind.active,
  });

  final List<_CreatorPartner> creators;
  final _TabKind tabKind;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(onFilter: () => _showFilterSheet(context)),
        Expanded(
          child: creators.isEmpty
              ? const Center(
                  child: Text(
                    'No creators here yet.',
                    style: DesignTokens.mediumRegular,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    DesignTokens.s8,
                    DesignTokens.s16,
                    80,
                  ),
                  itemCount: creators.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DesignTokens.s12),
                  itemBuilder: (_, i) => _CreatorCard(
                    creator: creators[i],
                    tabKind: tabKind,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Pending tab ─────────────────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        80,
      ),
      itemCount: _pendingRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) => _PendingCard(request: _pendingRequests[i]),
    );
  }
}

// ─── Invited tab ─────────────────────────────────────────────────────────────

class _InvitedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        80,
      ),
      itemCount: _invitedInvitations.length,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) => _InvitedCard(invitation: _invitedInvitations[i]),
    );
  }
}

class _InvitedCard extends StatelessWidget {
  const _InvitedCard({required this.invitation});

  final _InvitedInvitation invitation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — name · handle inline
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: invitation.avatarBg,
                child: Text(
                  invitation.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: invitation.name,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  ${invitation.handle}',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Proposed commission chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB8E6FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Proposed Commission: ${invitation.proposedCommission}%',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                color: Color(0xFF0D1B2A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Followers + Stars
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 14,
                color: DesignTokens.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '${invitation.followersLabel} Followers',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: Color(0xFFF1C40F),
              ),
              const SizedBox(width: 3),
              Text(
                '${invitation.stars} Stars',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Message card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Message',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  invitation.message,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.textLight,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Cancel Request + Message Creator buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DesignTokens.borderDefault),
                    shape: const StadiumBorder(),
                    foregroundColor: DesignTokens.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Cancel Request'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DesignTokens.primaryGreen),
                    shape: const StadiumBorder(),
                    foregroundColor: DesignTokens.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Message Creator'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Filter bar ──────────────────────────────────────────────────────────────

void _showFilterSheet(BuildContext context) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterBottomSheet(),
    ),
  );
}

void _showActionsSheet(
  BuildContext context,
  _CreatorPartner creator,
  _TabKind tabKind,
) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionsSheet(creator: creator, tabKind: tabKind),
    ),
  );
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.onFilter});

  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s8,
      ),
      child: Row(
        children: [
          _FilterChip(
            icon: Icons.tune_rounded,
            label: 'Filter',
            onTap: onFilter,
          ),
          const SizedBox(width: DesignTokens.s8),
          _FilterChip(
            label: 'Sort By',
            trailing: Icons.keyboard_arrow_down_rounded,
            onTap: () {},
          ),
          const SizedBox(width: DesignTokens.s8),
          _FilterChip(
            label: 'Performance',
            trailing: Icons.keyboard_arrow_down_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final IconData? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: DesignTokens.textLight, size: 15),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textLight,
                fontSize: 13,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 2),
              Icon(trailing, color: DesignTokens.textLight, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Creator performance card ─────────────────────────────────────────────────

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({
    required this.creator,
    this.tabKind = _TabKind.active,
  });

  final _CreatorPartner creator;
  final _TabKind tabKind;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: creator.avatarBg,
                  child: Text(
                    creator.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creator.name,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        creator.handle,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        creator.category,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 14,
                            color: DesignTokens.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${creator.followersLabel} Followers',
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              color: DesignTokens.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFF1C40F),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${creator.stars} Stars',
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              color: DesignTokens.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: DesignTokens.textMuted,
                    size: 20,
                  ),
                  onPressed: () => _showActionsSheet(context, creator, tabKind),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: _DashedDivider(),
          ),
          // Performance section
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance (Last 30 Days):',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.textWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                _PerfRow(
                  asset: 'assets/images/vendordashboard/Revenue Generated.png',
                  label: 'Revenue Generated',
                  value: creator.revenueGenerated,
                  highlight: true,
                ),
                _PerfRow(
                  asset: 'assets/images/vendordashboard/icon_reels.png',
                  label: 'Reels Published',
                  value: '${creator.reelsPublished}',
                ),
                _PerfRow(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Sales',
                  value: '${creator.sales}',
                ),
                _PerfRow(
                  asset: 'assets/images/vendordashboard/Views.png',
                  label: 'Views',
                  value: creator.viewsLabel,
                ),
                _PerfRow(
                  asset: 'assets/images/vendordashboard/icon_payment.png',
                  label: 'Commission Paid',
                  value: creator.commissionPaid,
                ),
                _PerfRow(
                  asset: 'assets/images/vendordashboard/Your ROI.png',
                  label: 'Your ROI',
                  value: creator.roi,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfRow extends StatelessWidget {
  const _PerfRow({
    this.asset,
    this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String? asset;
  final IconData? icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          if (asset != null)
            Image.asset(
              asset!,
              width: 16,
              height: 16,
              color: DesignTokens.textMuted,
            )
          else if (icon != null)
            Icon(icon, size: 16, color: DesignTokens.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                color: DesignTokens.textLight,
                fontSize: 13,
              ),
            ),
          ),
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFB8E6FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  color: Color(0xFF0D1B2A),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                color: DesignTokens.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Pending request card ─────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.request});

  final _PendingRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: request.avatarBg,
                child: Text(
                  request.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        color: DesignTokens.textWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 13,
                          color: DesignTokens.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${request.followersLabel} Followers · ${request.handle}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              color: DesignTokens.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new,
                color: DesignTokens.textMuted,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Commission chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB8E6FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Requested Commission: ${request.commissionMin}% - ${request.commissionMax}%',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                color: Color(0xFF0D1B2A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Message card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Message',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  request.message,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.textLight,
                    fontSize: 13,
                    height: 1.45,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Decline / Accept buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DesignTokens.borderDefault),
                    shape: const StadiumBorder(),
                    foregroundColor: DesignTokens.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DesignTokens.primaryGreen),
                    shape: const StadiumBorder(),
                    foregroundColor: DesignTokens.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Dashed divider ───────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashW = 6.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashW + gap)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 1,
              margin: const EdgeInsets.only(right: gap),
              color: DesignTokens.borderDefault,
            ),
          ),
        );
      },
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────────────────────

enum _SortBy { earnings, name, newest }

enum _Performance { high, medium, low }

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet();

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  DateTime? _dateJoined;
  _SortBy _sortBy = _SortBy.newest;
  RangeValues _commission = const RangeValues(5, 25);
  _Performance _performance = _Performance.high;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Active Partnership',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: DesignTokens.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1 — Date Joined
                  const SizedBox(height: DesignTokens.s16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateJoined ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: DesignTokens.primaryGreen,
                              surface: DesignTokens.bgAppBody,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _dateJoined = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DesignTokens.inputFieldBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dateJoined != null
                                  ? '${_dateJoined!.day}/${_dateJoined!.month}/${_dateJoined!.year}'
                                  : 'Date Joined',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 14,
                                color: _dateJoined != null
                                    ? DesignTokens.textWhite
                                    : DesignTokens.inputFieldPlaceholder,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFF71717B),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 2 — Sort By
                  const SizedBox(height: DesignTokens.s16),
                  _SectionTitle(label: 'Sort By'),
                  const SizedBox(height: DesignTokens.s16),
                  _RadioRow(
                    label: 'Earnings',
                    selected: _sortBy == _SortBy.earnings,
                    onTap: () => setState(() => _sortBy = _SortBy.earnings),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  _RadioRow(
                    label: 'Name',
                    selected: _sortBy == _SortBy.name,
                    onTap: () => setState(() => _sortBy = _SortBy.name),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  _RadioRow(
                    label: 'Newest',
                    selected: _sortBy == _SortBy.newest,
                    onTap: () => setState(() => _sortBy = _SortBy.newest),
                  ),
                  // 3 — Commission Range
                  const SizedBox(height: DesignTokens.s16),
                  _SectionTitle(
                    label:
                        'Commission Range (${_commission.start.round()}%-${_commission.end.round()}%)',
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: DesignTokens.primaryGreen,
                      inactiveTrackColor: const Color(0xFFDEF7E9),
                      rangeThumbShape: const _GreenThumb(),
                      overlayColor: DesignTokens.primaryGreen.withOpacity(0.15),
                    ),
                    child: RangeSlider(
                      values: _commission,
                      min: 0,
                      max: 50,
                      onChanged: (v) => setState(() => _commission = v),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_commission.start.round()}%',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          color: DesignTokens.textLight,
                        ),
                      ),
                      Text(
                        '${_commission.end.round()}%',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ],
                  ),
                  // 4 — Performance
                  const SizedBox(height: DesignTokens.s16),
                  _SectionTitle(label: 'Performance'),
                  const SizedBox(height: DesignTokens.s16),
                  _RadioRow(
                    label: 'High',
                    selected: _performance == _Performance.high,
                    onTap: () =>
                        setState(() => _performance = _Performance.high),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  _RadioRow(
                    label: 'Medium',
                    selected: _performance == _Performance.medium,
                    onTap: () =>
                        setState(() => _performance = _Performance.medium),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  _RadioRow(
                    label: 'Low',
                    selected: _performance == _Performance.low,
                    onTap: () =>
                        setState(() => _performance = _Performance.low),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                ],
              ),
            ),
          ),
          // Sticky Clear & Apply buttons
          Container(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              24,
              DesignTokens.s16,
              0,
            ),
            decoration: const BoxDecoration(
              color: DesignTokens.bgAppFoundation,
              border: Border(
                top: BorderSide(color: DesignTokens.borderDefault),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: DesignTokens.buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _dateJoined = null;
                              _sortBy = _SortBy.newest;
                              _commission = const RangeValues(5, 25);
                              _performance = _Performance.high;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3F3F46),
                            foregroundColor: DesignTokens.textWhite,
                            shape: const StadiumBorder(),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: SizedBox(
                        height: DesignTokens.buttonHeight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryGreen,
                            foregroundColor: const Color(0xFF06190E),
                            shape: const StadiumBorder(),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter sheet sub-widgets ─────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textWhite,
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: DesignTokens.primaryGreen,
              fillColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? DesignTokens.primaryGreen
                    : const Color(0xFF71717B),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: Color(0xFF9F9FA9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom range slider thumb (green fill + white border) ────────────────────

class _GreenThumb extends RangeSliderThumbShape {
  const _GreenThumb();

  static const double _radius = 10;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool isPressed = false,
  }) {
    final canvas = context.canvas;
    // White border
    canvas.drawCircle(
      center,
      _radius,
      Paint()..color = Colors.white,
    );
    // Green fill
    canvas.drawCircle(
      center,
      _radius - 3.3,
      Paint()..color = DesignTokens.primaryGreen,
    );
  }
}

// ─── Creator actions bottom sheet ─────────────────────────────────────────────

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({
    required this.creator,
    this.tabKind = _TabKind.active,
  });

  final _CreatorPartner creator;
  final _TabKind tabKind;

  @override
  Widget build(BuildContext context) {
    // Invited tab has a different, shorter action list
    final actions = switch (tabKind) {
      _TabKind.invited => [
        (icon: Icons.edit_outlined, label: 'Edit Details'),
        (
          icon: Icons.credit_card_outlined,
          label: 'Change Payment Method',
        ),
      ],
      _TabKind.paused => [
        (icon: Icons.currency_exchange_rounded, label: 'Adjust Commission'),
        (icon: Icons.analytics_outlined, label: 'View Analytics'),
        (icon: Icons.chat_bubble_outline_rounded, label: 'Message'),
        (
          icon: Icons.play_circle_outline_rounded,
          label: 'Resume Partnerships',
        ),
      ],
      _TabKind.ended => [
        (icon: Icons.currency_exchange_rounded, label: 'Adjust Commission'),
        (icon: Icons.analytics_outlined, label: 'View Analytics'),
        (icon: Icons.chat_bubble_outline_rounded, label: 'Message'),
        (icon: Icons.send_outlined, label: 'Send Request Again'),
      ],
      _ => [
        (icon: Icons.currency_exchange_rounded, label: 'Adjust Commission'),
        (icon: Icons.analytics_outlined, label: 'View Analytics'),
        (icon: Icons.chat_bubble_outline_rounded, label: 'Message'),
        (
          icon: Icons.pause_circle_outline_rounded,
          label: 'Pause Partnerships',
        ),
      ],
    };

    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Action items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: Column(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  _ActionItem(
                    icon: actions[i].icon,
                    label: actions[i].label,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (actions[i].label == 'View Analytics') {
                        context.push(
                          RouteNames.vendorCreatorAnalytics,
                          extra: CreatorAnalyticsArgs(
                            creatorName: creator.name,
                            handle: creator.handle,
                            followersLabel: creator.followersLabel,
                            commission: 16,
                          ),
                        );
                      } else if (actions[i].label == 'Message') {
                        context.push(
                          RouteNames.vendorMessageCreator,
                          extra: MessageCreatorArgs(
                            creatorName: creator.name,
                            handle: creator.handle,
                          ),
                        );
                      } else if (actions[i].label == 'Adjust Commission') {
                        context.push(
                          RouteNames.vendorAdjustCommission,
                          extra: AdjustCommissionArgs(
                            creatorName: creator.name,
                            handle: creator.handle,
                            followersLabel: creator.followersLabel,
                            currentCommission: 16,
                          ),
                        );
                      }
                    },
                  ),
                  if (i < actions.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: DesignTokens.borderDefault,
                    ),
                ],
              ],
            ),
          ),
          SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: DesignTokens.iconLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: DesignTokens.textWhite,
                  height: 1.5,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: DesignTokens.iconLight,
            ),
          ],
        ),
      ),
    );
  }
}
