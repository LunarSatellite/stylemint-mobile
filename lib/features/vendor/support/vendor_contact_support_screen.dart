import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/contact_channels.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/notifiers/support_notifier.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorContactSupportScreen extends ConsumerStatefulWidget {
  const VendorContactSupportScreen({super.key});

  @override
  ConsumerState<VendorContactSupportScreen> createState() =>
      _VendorContactSupportScreenState();
}

class _VendorContactSupportScreenState
    extends ConsumerState<VendorContactSupportScreen> {
  int _selectedTab = 0; // 0=Submitted, 1=In Progress, 2=Resolved

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(supportNotifierProvider.notifier).loadTickets(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactChannels = ref.watch(contactChannelsProvider);
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
        title: Text('Contact Support', style: DesignTokens.oneLinerSemibold),
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
                    _buildWelcomeCard(),
                    const SizedBox(height: DesignTokens.s16),
                    _buildSupportChannels(
                      contactChannels.when(
                        data: (value) => value,
                        loading: () => null,
                        error: (_, __) => null,
                      ),
                      contactChannels.isLoading,
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    _buildQuickActions(),
                    const SizedBox(height: DesignTokens.s20),
                    _buildYourTickets(),
                    const SizedBox(height: DesignTokens.s16),
                  ],
                ),
              ),
            ),
            _buildCreateTicketButton(),
          ],
        ),
      ),
    );
  }

  // ── Welcome card ─────────────────────────────────────────────────────────

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s20,
      ),
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
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'How can we help you today?',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Image.asset(
            'assets/images/vendordashboard/support_illustration.png',
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }

  // ── Support channels ─────────────────────────────────────────────────────

  Widget _buildSupportChannels(
    ContactChannels? contactChannels,
    bool isLoading,
  ) {
    final channels = [
      _Channel(
        icon: Icons.chat_outlined,
        title: 'Vendor Support Chat',
        subtitle: contactChannels == null
            ? (isLoading
                  ? 'Checking availability…'
                  : 'Availability unavailable')
            : contactChannels.liveChatAvailable
            ? 'Available now · ${contactChannels.liveChatHoursLocal}'
            : 'Offline · ${contactChannels.liveChatHoursLocal}',
        onTap: () => SmSnackbar.info(
          context,
          'Live-chat availability is shown above. Chat sessions are not yet available in this app; please create a support ticket.',
        ),
        customIcon: 'assets/images/vendordashboard/icon_chat.png',
        subtitleColor: const Color(0xFF9F9FA9),
      ),
      _Channel(
        icon: Icons.mail_outline,
        title: 'Email Support',
        subtitle: contactChannels?.supportEmail.isNotEmpty == true
            ? contactChannels!.supportEmail
            : isLoading
            ? 'Loading support email…'
            : 'Email unavailable',
        onTap: contactChannels?.supportEmail.isNotEmpty == true
            ? () => unawaited(
                launchUrl(
                  Uri(scheme: 'mailto', path: contactChannels!.supportEmail),
                ),
              )
            : null,
        customIcon: 'assets/images/vendordashboard/icon_email.png',
      ),
      _Channel(
        icon: Icons.phone_outlined,
        title: 'Direct Call',
        subtitle: contactChannels?.directCallPhoneE164.isNotEmpty == true
            ? contactChannels!.directCallPhoneE164
            : isLoading
            ? 'Loading direct-call number…'
            : 'Phone unavailable',
        onTap: contactChannels?.directCallPhoneE164.isNotEmpty == true
            ? () => unawaited(
                launchUrl(
                  Uri(
                    scheme: 'tel',
                    path: contactChannels!.directCallPhoneE164,
                  ),
                ),
              )
            : null,
        customIcon: 'assets/images/vendordashboard/icon_phone.png',
      ),
      _Channel(
        icon: Icons.archive_outlined,
        title: 'Vendor Resources',
        subtitle: 'Articles & Help for Vendors',
        onTap: _showResourcesSheet,
        customIcon: 'assets/images/vendordashboard/icon_resources.png',
      ),
    ];

    return Container(
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: channels.asMap().entries.map((entry) {
          final i = entry.key;
          final ch = entry.value;
          return Column(
            children: [
              ListTile(
                leading: ch.customIcon != null
                    ? Image.asset(ch.customIcon!, width: 40, height: 40)
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppBodyLight,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.inputRadius,
                          ),
                        ),
                        child: Icon(
                          ch.icon,
                          color: DesignTokens.textWhite,
                          size: 20,
                        ),
                      ),
                title: Text(
                  ch.title,
                  style: DesignTokens.smallRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                subtitle: Text(
                  ch.subtitle,
                  style: DesignTokens.smallRegular.copyWith(
                    color: ch.subtitleColor ?? const Color(0xFF9F9FA9),
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: DesignTokens.textMuted,
                  size: 14,
                ),
                onTap: ch.onTap,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s4,
                ),
              ),
              if (i < channels.length - 1)
                const Divider(
                  color: DesignTokens.borderDefault,
                  height: 1,
                  indent: DesignTokens.s16,
                  endIndent: DesignTokens.s16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showResourcesSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
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
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vendor Resources',
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            ...[
              'Vendor Guidelines',
              'Earnings FAQ',
              'Partnership Best Practices',
              'Sales Tips & Tricks',
            ].map(
              (r) => ListTile(
                title: Text(r, style: DesignTokens.oneLinerRegular),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: DesignTokens.textMuted,
                  size: 14,
                ),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
          ],
        ),
      ),
    ).ignore();
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.local_shipping_outlined,
        label: 'Order Fulfillment Issues',
        customIcon: 'assets/images/vendordashboard/icon_truck.png',
      ),
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'Inventory Sync Problems',
        customIcon: 'assets/images/vendordashboard/icon_resources.png',
      ),
      _QuickAction(
        icon: Icons.monetization_on_outlined,
        label: 'Payment/Payout Questions',
        customIcon: 'assets/images/vendordashboard/icon_payment.png',
      ),
      _QuickAction(
        icon: Icons.handshake_outlined,
        label: 'Creator Partnership Help',
        customIcon:
            'assets/images/vendordashboard/Creator Partnership Help.png',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: DesignTokens.s12,
      mainAxisSpacing: DesignTokens.s12,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions
          .map(
            (a) => GestureDetector(
              onTap: () => _showCreateTicketSheet(prefilledIssue: a.label),
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.s16),
                decoration: DesignTokens.cardDecoration(
                  borderColor: DesignTokens.borderDefault,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    a.customIcon != null
                        ? Image.asset(a.customIcon!, width: 28, height: 28)
                        : Icon(a.icon, color: DesignTokens.textWhite, size: 28),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      a.label,
                      style: DesignTokens.smallRegular.copyWith(
                        fontSize: 12,
                        color: const Color(0xFFD4D4D8),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Your Tickets ──────────────────────────────────────────────────────────

  Widget _buildYourTickets() {
    final state = ref.watch(supportNotifierProvider);

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
      _TabItem(label: 'Submitted', count: submitted.length),
      _TabItem(label: 'In Progress', count: inProgress.length),
      _TabItem(label: 'Resolved', count: resolved.length),
    ];

    final currentTickets = [submitted, inProgress, resolved][_selectedTab];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Support Tickets', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s12),
        // Pill tabs
        Row(
          children: tabs.asMap().entries.map((entry) {
            final i = entry.key;
            final tab = entry.value;
            final selected = _selectedTab == i;
            return Padding(
              padding: EdgeInsets.only(
                right: i < tabs.length - 1 ? DesignTokens.s8 : 0,
              ),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: DesignTokens.s8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.primaryGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.borderDefault,
                    ),
                  ),
                  child: Text(
                    '${tab.label}(${tab.count})',
                    style: DesignTokens.smallRegular.copyWith(
                      color: selected
                          ? DesignTokens.textWhite
                          : DesignTokens.textMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (state.maybeWhen(loadInProgress: () => true, orElse: () => false))
          const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
          )
        else if (currentTickets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
            child: Center(
              child: Text(
                'No tickets',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentTickets.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: DesignTokens.s8),
            itemBuilder: (_, i) => _TicketTile(
              ticket: currentTickets[i],
              onTap: () => _showTicketDetail(currentTickets[i]),
            ),
          ),
      ],
    );
  }

  // ── Create ticket button ──────────────────────────────────────────────────

  Widget _buildCreateTicketButton() {
    return Container(
      color: DesignTokens.bgAppFoundation,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: DesignTokens.buttonHeight,
        child: ElevatedButton(
          onPressed: _showCreateTicketSheet,
          style: DesignTokens.primaryButtonStyle(),
          child: Text(
            'Create Support Ticket',
            style: DesignTokens.oneLinerSemibold.copyWith(
              color: DesignTokens.buttonPrimaryText,
            ),
          ),
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
        decoration: DesignTokens.cardDecoration(
          borderColor: DesignTokens.borderDefault,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: DesignTokens.smallRegular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    'Ticket ID: ${ticket.ticketNumber}',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/vendordashboard/calendar.png',
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(ticket.createdAt),
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: DesignTokens.textMuted,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period, ${_dayOrdinal(dt.day)} ${_monthName(dt.month)} ${dt.year}';
  }

  String _dayOrdinal(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) {
      1 => '${d}st',
      2 => '${d}nd',
      3 => '${d}rd',
      _ => '${d}th',
    };
  }

  String _monthName(int m) => const [
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
            Text('Product', style: DesignTokens.oneLinerRegular),
            const SizedBox(height: DesignTokens.s12),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: DesignTokens.s6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
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
            Text(ticket.subject, style: DesignTokens.smallRegular),
            const SizedBox(height: DesignTokens.s16),
            // Created On
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created On',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/vendordashboard/calendar.png',
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(ticket.createdAt),
                      style: DesignTokens.smallRegular,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            // Attachments
            Text(
              'Attachments',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Row(
              children: [
                _buildThumbnail('assets/images/attachment_1.png', false),
                const SizedBox(width: DesignTokens.s8),
                _buildThumbnail('assets/images/attachment_2.png', false),
                const SizedBox(width: DesignTokens.s8),
                _buildThumbnail(
                  'assets/images/vendordashboard/attachment_3.png',
                  true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String asset, bool hasOverflow) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          child: Image.asset(
            asset,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (ctx, e, st) => Container(
              width: 80,
              height: 80,
              color: DesignTokens.bgAppBodyLight,
            ),
          ),
        ),
        if (hasOverflow)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: Center(
                child: Text(
                  '+2',
                  style: DesignTokens.mediumSemibold.copyWith(fontSize: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _statusLabel(TicketStatus s) => switch (s) {
    TicketStatus.open => 'Submitted',
    TicketStatus.inProgress => 'In Progress',
    TicketStatus.resolved => 'Resolved',
  };

  String _formatDateTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period, ${_dayOrdinal(dt.day)} ${_monthName(dt.month)} ${dt.year}';
  }

  String _dayOrdinal(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) {
      1 => '${d}st',
      2 => '${d}nd',
      3 => '${d}rd',
      _ => '${d}th',
    };
  }

  String _monthName(int m) => const [
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

// ── Create ticket sheet ───────────────────────────────────────────────────────

class _CreateTicketSheet extends ConsumerStatefulWidget {
  const _CreateTicketSheet({this.prefilledIssue});

  final String? prefilledIssue;

  @override
  ConsumerState<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends ConsumerState<_CreateTicketSheet> {
  final _descController = TextEditingController();
  SupportCategory? _selectedCategory;
  final List<XFile> _selectedImages = [];
  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _selectedImages.addAll(picked));
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  /// `SupportCategory.id` is the backend's 1-based `SupportCategory` enum
  /// value as a string (see `HelpCategoryDto.Id`), matching the order of
  /// `TicketCategory.values` — so this is a direct index lookup, not a
  /// label guess. Falls back to [TicketCategory.forVendors] when nothing
  /// is selected.
  static TicketCategory _categoryFor(SupportCategory? category) =>
      category == null
      ? TicketCategory.forVendors
      : TicketCategory.values[int.parse(category.id) - 1];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledIssue != null) {
      _descController.text = widget.prefilledIssue!;
    }
    // Warm the categories load so the picker has data by the time it's opened.
    ref.read(categoriesNotifierProvider);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_descController.text.trim().isEmpty) return;
    // Attachments aren't sent: the backend only accepts pre-uploaded
    // attachmentUrls and there is no blob/file upload endpoint anywhere in
    // the API (see stylemint-support skill / API_INTEGRATION_GUIDE.md) — the
    // picker above is left in place for when that endpoint exists.
    unawaited(
      ref
          .read(createTicketNotifierProvider.notifier)
          .submit(
            subject: _descController.text.trim(),
            message: _descController.text.trim(),
            category: _categoryFor(_selectedCategory),
          ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Create Support Ticket',
                      style: DesignTokens.mediumSemibold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: DesignTokens.textMuted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s16),
              GestureDetector(
                onTap: _showCategoryPicker,
                child: Container(
                  height: DesignTokens.inputHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s12,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.inputFieldFill,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.inputRadius,
                    ),
                    border: Border.all(color: DesignTokens.inputFieldBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCategory?.title ?? 'Issue Category',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            color: _selectedCategory != null
                                ? DesignTokens.inputFieldData
                                : DesignTokens.inputFieldPlaceholder,
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
              TextField(
                controller: _descController,
                maxLines: 4,
                style: DesignTokens.oneLinerRegular.copyWith(
                  color: DesignTokens.inputFieldData,
                ),
                decoration: DesignTokens.inputDecoration(
                  hintText: 'Describe Issue',
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              if (_selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: DesignTokens.s8),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            DesignTokens.inputRadius,
                          ),
                          child: Image.file(
                            File(_selectedImages[i].path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(i),
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
                      Text(
                        'Upload Images',
                        style: DesignTokens.oneLinerSemibold,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: DesignTokens.primaryButtonStyle(),
                  child: Text(
                    'Submit Ticket',
                    style: DesignTokens.oneLinerSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                      style: DesignTokens.oneLinerSemibold,
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
                      style: DesignTokens.oneLinerRegular.copyWith(
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
                            style: DesignTokens.oneLinerRegular,
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

// ── Data models ───────────────────────────────────────────────────────────────

class _Channel {
  const _Channel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.customIcon,
    this.subtitleColor,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? customIcon;
  final Color? subtitleColor;
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.customIcon,
  });
  final IconData icon;
  final String label;
  final String? customIcon;
}

class _TabItem {
  const _TabItem({required this.label, required this.count});
  final String label;
  final int count;
}
