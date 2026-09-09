import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/contact_channels.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/notifiers/support_notifier.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(supportNotifierProvider.notifier).loadTickets(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportNotifierProvider);
    final channels = ref.watch(contactChannelsProvider);

    final allTickets = state.maybeWhen(
      loadSuccess: (t) => t,
      orElse: () => <Ticket>[],
    );

    final submitted = allTickets
        .where((t) => t.status == TicketStatus.open)
        .toList();
    final inProgress = allTickets
        .where((t) => t.status == TicketStatus.inProgress)
        .toList();
    final resolved = allTickets
        .where((t) => t.status == TicketStatus.resolved)
        .toList();

    final tabs = [
      (label: 'Submitted', count: submitted.length),
      (label: 'In Progress', count: inProgress.length),
      (label: 'Resolved', count: resolved.length),
    ];
    final currentTickets = [submitted, inProgress, resolved][_selectedTab];

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),
        title: const Text(
          'Contact Support',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Welcome banner ──────────────────────────────────
                    _WelcomeBanner(),
                    const SizedBox(height: DesignTokens.s16),

                    // ── Contact channels ────────────────────────────────
                    _ChannelsCard(
                      channels: channels,
                      onLiveChat: () => _showLiveChatAvailability(context),
                    ),
                    const SizedBox(height: DesignTokens.s16),

                    // ── Quick actions ───────────────────────────────────
                    _QuickActions(onTap: _showCreateTicketSheet),
                    const SizedBox(height: DesignTokens.s20),

                    // ── Your Support Tickets ────────────────────────────
                    Text(
                      'Your Support Tickets',
                      style: DesignTokens.mediumSemibold,
                    ),
                    const SizedBox(height: DesignTokens.s12),

                    // Filter tabs
                    Row(
                      children: [
                        for (var i = 0; i < tabs.length; i++) ...[
                          if (i > 0) const SizedBox(width: DesignTokens.s8),
                          _FilterChip(
                            label: '${tabs[i].label}(${tabs[i].count})',
                            selected: _selectedTab == i,
                            onTap: () => setState(() => _selectedTab = i),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: DesignTokens.s12),

                    // Ticket list or empty state
                    if (state.maybeWhen(
                      loadInProgress: () => true,
                      orElse: () => false,
                    ))
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: DesignTokens.s32,
                          ),
                          child: CircularProgressIndicator(
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      )
                    else if (currentTickets.isEmpty)
                      const _EmptyTickets()
                    else
                      Column(
                        children: [
                          for (final t in currentTickets) ...[
                            _TicketTile(
                              ticket: t,
                              onTap: () => _showTicketDetail(t),
                            ),
                            const SizedBox(height: DesignTokens.s8),
                          ],
                        ],
                      ),

                    const SizedBox(height: DesignTokens.s16),
                  ],
                ),
              ),
            ),

            // ── Pinned button ───────────────────────────────────────────
            Container(
              color: DesignTokens.bgAppFoundation,
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s12,
                DesignTokens.s16,
                DesignTokens.s24,
              ),
              child: SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _showCreateTicketSheet,
                  style: DesignTokens.primaryButtonStyle(),
                  child: Text(
                    'Create Support Ticket',
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetail(Ticket ticket) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (ctx) => _TicketDetailSheet(ticket: ticket),
    ).ignore();
  }

  void _showCreateTicketSheet({String? prefilledIssue}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (ctx) => _CreateTicketSheet(prefilledIssue: prefilledIssue),
    ).ignore();
  }

  void _showLiveChatAvailability(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Live-chat availability is shown above. Chat sessions are not yet available in this app; please create a support ticket.',
        ),
      ),
    );
  }
}

// ── Welcome banner ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreen,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Support',
                  style: DesignTokens.sectionInnerTitle.copyWith(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'How can we help you today?',
                  style: DesignTokens.smallRegular.copyWith(
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          // Decorative illustration
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smartphone_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact channels card ─────────────────────────────────────────────────────

class _ChannelsCard extends StatelessWidget {
  const _ChannelsCard({required this.channels, required this.onLiveChat});

  final AsyncValue<ContactChannels> channels;
  final VoidCallback onLiveChat;

  @override
  Widget build(BuildContext context) {
    final data = channels.when(
      data: (value) => value,
      loading: () => null,
      error: (_, __) => null,
    );
    final isLoading = channels.isLoading;
    final liveChatSubtitle = data == null
        ? (isLoading ? 'Checking availability…' : 'Availability unavailable')
        : data.liveChatAvailable
        ? 'Available now • ${data.liveChatHoursLocal}'
        : 'Offline • ${data.liveChatHoursLocal}';
    final rows =
        <
          ({
            IconData icon,
            String title,
            String subtitle,
            VoidCallback? onTap,
          })
        >[
          (
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Live Chat',
            subtitle: liveChatSubtitle,
            onTap: onLiveChat,
          ),
          (
            icon: Icons.mail_outline_rounded,
            title: 'Email Support',
            subtitle: data?.supportEmail.isNotEmpty == true
                ? data!.supportEmail
                : isLoading
                ? 'Loading support email…'
                : 'Email unavailable',
            onTap: data?.supportEmail.isNotEmpty == true
                ? () =>
                      launchUrl(Uri(scheme: 'mailto', path: data!.supportEmail))
                : null,
          ),
          (
            icon: Icons.phone_outlined,
            title: 'Direct Call',
            subtitle: data?.directCallPhoneE164.isNotEmpty == true
                ? data!.directCallPhoneE164
                : isLoading
                ? 'Loading direct-call number…'
                : 'Phone unavailable',
            onTap: data?.directCallPhoneE164.isNotEmpty == true
                ? () => launchUrl(
                    Uri(scheme: 'tel', path: data!.directCallPhoneE164),
                  )
                : null,
          ),
        ];

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color: DesignTokens.borderDefault,
                indent: DesignTokens.s16,
                endIndent: DesignTokens.s16,
              ),
            _ChannelTile(
              icon: rows[i].icon,
              title: rows[i].title,
              subtitle: rows[i].subtitle,
              onTap: rows[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              child: Icon(
                icon,
                color: DesignTokens.textWhite.withValues(alpha: 0.8),
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Track My Order',
            onTap: onTap,
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: _QuickTile(
            icon: Icons.assignment_return_outlined,
            label: 'Refund & Returns',
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.s20,
          horizontal: DesignTokens.s16,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: DesignTokens.textWhite.withValues(alpha: 0.8),
              size: 26,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s6,
        ),
        decoration: BoxDecoration(
          color: selected ? DesignTokens.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          border: Border.all(
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: selected ? Colors.black : DesignTokens.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
      child: Column(
        children: [
          // Decorative stacked cards
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back card
                Positioned(
                  top: 8,
                  child: Transform.rotate(
                    angle: -0.08,
                    child: _PlaceholderCard(
                      initials: 'SD',
                      color: const Color(0xFF2ECC71),
                    ),
                  ),
                ),
                // Middle card
                Positioned(
                  top: 28,
                  child: Transform.rotate(
                    angle: 0.04,
                    child: _PlaceholderCard(
                      initials: 'AP',
                      color: DesignTokens.colorWarning,
                    ),
                  ),
                ),
                // Front card
                Positioned(
                  top: 52,
                  child: _PlaceholderCard(
                    initials: 'JS',
                    color: const Color(0xFF2ECC71),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Text(
            'No Support Tickets Yet',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'When you create a support ticket you will\nbe able to view it here',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.initials, required this.color});
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: DesignTokens.borderDefault,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: DesignTokens.s6),
                Container(
                  height: 8,
                  width: 80,
                  decoration: BoxDecoration(
                    color: DesignTokens.bgAppBodyLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ticket tile ───────────────────────────────────────────────────────────────

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket, required this.onTap});
  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    'Ticket ID: ${ticket.ticketNumber}',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: DesignTokens.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fmt(ticket.createdAt),
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period, ${_ord(dt.day)} ${_mon(dt.month)} ${dt.year}';
  }

  String _ord(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) {
      1 => '${d}st',
      2 => '${d}nd',
      3 => '${d}rd',
      _ => '${d}th',
    };
  }

  String _mon(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}

// ── Ticket detail sheet ───────────────────────────────────────────────────────

class _TicketDetailSheet extends StatelessWidget {
  const _TicketDetailSheet({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s20,
          DesignTokens.s16,
          DesignTokens.s32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + close
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ticket ID: ${ticket.ticketNumber}',
                    style: DesignTokens.mediumSemibold.copyWith(fontSize: 20),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: DesignTokens.textWhite,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),

            // Issue Category
            Text(
              'Issue Category',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              _issueCategory(ticket.subject),
              style: DesignTokens.mediumRegular,
            ),
            const SizedBox(height: DesignTokens.s12),

            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: DesignTokens.s6,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(ticket.status),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),

            // Description
            Text(
              ticket.subject,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),

            // Info card: Created On + Attachments
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.s16),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppFoundation,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Created On',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                      Text(
                        _fmt(ticket.createdAt),
                        style: DesignTokens.smallRegular,
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  Text(
                    'Attachments',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  // Placeholder attachment thumbnails
                  Row(
                    children: [
                      _Thumbnail(),
                      const SizedBox(width: DesignTokens.s8),
                      _Thumbnail(),
                      const SizedBox(width: DesignTokens.s8),
                      _Thumbnail(overflow: '+2'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _issueCategory(String subject) {
    if (subject.toLowerCase().contains('shipping') ||
        subject.toLowerCase().contains('address')) {
      return 'Shipping Address Issue';
    }
    if (subject.toLowerCase().contains('refund')) return 'Returns & Refunds';
    if (subject.toLowerCase().contains('order')) return 'Order Issue';
    return 'General Inquiry';
  }

  String _statusLabel(TicketStatus s) => switch (s) {
    TicketStatus.open => 'Submitted',
    TicketStatus.inProgress => 'In Progress',
    TicketStatus.resolved => 'Resolved',
  };

  String _fmt(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period, ${_ord(dt.day)} ${_mon(dt.month)} ${dt.year}';
  }

  String _ord(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) {
      1 => '${d}st',
      2 => '${d}nd',
      3 => '${d}rd',
      _ => '${d}th',
    };
  }

  String _mon(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.overflow});
  final String? overflow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBodyLight,
            borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          ),
          child: const Icon(
            Icons.image_outlined,
            color: DesignTokens.textMuted,
            size: 28,
          ),
        ),
        if (overflow != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: Center(
                child: Text(
                  overflow!,
                  style: DesignTokens.mediumSemibold.copyWith(fontSize: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Create ticket sheet ───────────────────────────────────────────────────────

class _CreateTicketSheet extends ConsumerStatefulWidget {
  const _CreateTicketSheet({this.prefilledIssue});
  final String? prefilledIssue;

  @override
  ConsumerState<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends ConsumerState<_CreateTicketSheet> {
  final _orderCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  SupportCategory? _selectedCategory;
  final List<XFile> _images = [];
  final _picker = ImagePicker();

  /// `SupportCategory.id` is the backend's 1-based `SupportCategory` enum
  /// value as a string (see `HelpCategoryDto.Id`), matching the order of
  /// `TicketCategory.values` — so this is a direct index lookup, not a
  /// label guess.
  static TicketCategory _categoryFor(SupportCategory? category) =>
      category == null
      ? TicketCategory.safetyAndPrivacy
      : TicketCategory.values[int.parse(category.id) - 1];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledIssue != null) {
      _descCtrl.text = widget.prefilledIssue!;
    }
    // Warm the categories load so the picker has data by the time it's opened.
    ref.read(categoriesNotifierProvider);
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) setState(() => _images.addAll(picked));
  }

  void _submit() {
    if (_descCtrl.text.trim().isEmpty) return;
    // Attachments aren't sent — see the vendor Contact Support screen's
    // _submit() for why (no blob/file upload endpoint in the backend yet).
    unawaited(
      ref
          .read(createTicketNotifierProvider.notifier)
          .submit(
            subject: _descCtrl.text.trim(),
            message: _descCtrl.text.trim(),
            category: _categoryFor(_selectedCategory),
          ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: DesignTokens.s16,
          right: DesignTokens.s16,
          top: DesignTokens.s20,
          bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Create Support Ticket',
                    style: DesignTokens.sectionInnerTitle,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: DesignTokens.textMuted,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s20),

            // Issue Category dropdown
            GestureDetector(
              onTap: _showCategoryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s16,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.inputFieldFill,
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  border: Border.all(
                    color: _selectedCategory != null
                        ? DesignTokens.primaryGreen
                        : DesignTokens.inputFieldBorder,
                  ),
                ),
                child: _selectedCategory != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Issue Category',
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedCategory!.title,
                                  style: DesignTokens.mediumRegular.copyWith(
                                    color: DesignTokens.inputFieldData,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: DesignTokens.inputFieldDropdownIcon,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Issue Category',
                              style: DesignTokens.mediumRegular.copyWith(
                                color: DesignTokens.inputFieldPlaceholder,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: DesignTokens.inputFieldDropdownIcon,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),

            // Order No. (Optional)
            TextField(
              controller: _orderCtrl,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.inputFieldData,
              ),
              decoration: DesignTokens.inputDecoration(
                hintText: 'Order No. (Optional)',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),

            // Describe Issue
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.inputFieldData,
              ),
              decoration: DesignTokens.inputDecoration(
                hintText: 'Describe Issue',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),

            // Image previews
            if (_images.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: DesignTokens.s8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.inputRadius,
                        ),
                        child: Image.file(
                          File(_images[i].path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
            ],

            // Upload Images
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                  border: Border.all(color: DesignTokens.borderDefault),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.upload_outlined,
                      color: DesignTokens.textWhite,
                      size: 20,
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Text('Upload Images', style: DesignTokens.mediumSemibold),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),

            // Submit
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: _submit,
                style: DesignTokens.primaryButtonStyle(),
                child: Text(
                  'Submit Ticket',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final categoriesState = ref.watch(categoriesNotifierProvider);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: DesignTokens.s12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Issue Category',
                      style: DesignTokens.sectionInnerTitle,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                categoriesState.when(
                  initial: _categoryPickerLoader,
                  loadInProgress: _categoryPickerLoader,
                  loadFailure: (failure) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s16,
                    ),
                    child: Text(
                      'Could not load categories.',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ),
                  loadSuccess: (categories) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final cat in categories)
                        ListTile(
                          title: Text(
                            cat.title,
                            style: DesignTokens.mediumRegular.copyWith(
                              color: DesignTokens.textWhite,
                            ),
                          ),
                          trailing: _selectedCategory?.id == cat.id
                              ? const Icon(
                                  Icons.check,
                                  color: DesignTokens.primaryGreen,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            Navigator.of(ctx).pop();
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
              ],
            ),
          );
        },
      ),
    ).ignore();
  }

  Widget _categoryPickerLoader() => const Padding(
    padding: EdgeInsets.symmetric(vertical: DesignTokens.s24),
    child: Center(child: CircularProgressIndicator()),
  );
}
