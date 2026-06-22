import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
      body: Column(
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
                  _buildSupportChannels(),
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
    );
  }

  // ── Welcome card ─────────────────────────────────────────────────────────

  Widget _buildWelcomeCard() {
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
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'How can we help you today?',
                  style: DesignTokens.smallRegular.copyWith(
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Image.asset(
            'assets/images/support_illustration.png',
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }

  // ── Support channels ─────────────────────────────────────────────────────

  Widget _buildSupportChannels() {
    final channels = [
      _Channel(
        icon: Icons.chat_outlined,
        title: 'Vendor Support Chat',
        subtitle: 'Available · Wait: 1min',
        onTap: () {},
        customIcon: 'assets/images/icon_chat.png',
        subtitleColor: const Color(0xFF9F9FA9),
      ),
      _Channel(
        icon: Icons.mail_outline,
        title: 'Email Support',
        subtitle: 'Response within 15 min',
        onTap: () {},
        customIcon: 'assets/images/icon_email.png',
      ),
      _Channel(
        icon: Icons.phone_outlined,
        title: 'Creator Hotline (1-800-VENDOR)',
        subtitle: 'Mon-Fri, 9 AM – 6 PM EST',
        onTap: () {},
        customIcon: 'assets/images/icon_phone.png',
      ),
      _Channel(
        icon: Icons.archive_outlined,
        title: 'Vendor Resources',
        subtitle: 'Articles & Help for Vendors',
        onTap: _showResourcesSheet,
        customIcon: 'assets/images/icon_resources.png',
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
                          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                        ),
                        child: Icon(ch.icon, color: DesignTokens.textWhite, size: 20),
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
      builder: (ctx) => Column(
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
              child: Text('Vendor Resources', style: DesignTokens.oneLinerSemibold),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          ...['Vendor Guidelines', 'Earnings FAQ', 'Partnership Best Practices', 'Sales Tips & Tricks']
              .map(
                (r) => ListTile(
                  title: Text(r, style: DesignTokens.oneLinerRegular),
                  trailing: const Icon(Icons.arrow_forward_ios, color: DesignTokens.textMuted, size: 14),
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ),
          const SizedBox(height: DesignTokens.s16),
        ],
      ),
    ).ignore();
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(icon: Icons.local_shipping_outlined, label: 'Order Fulfillment Issues', customIcon: 'assets/images/icon_truck.png'),
      _QuickAction(icon: Icons.inventory_2_outlined, label: 'Inventory Sync Problems', customIcon: 'assets/images/icon_resources.png'),
      _QuickAction(icon: Icons.monetization_on_outlined, label: 'Payment/Payout Questions', customIcon: 'assets/images/icon_payment.png'),
      _QuickAction(icon: Icons.handshake_outlined, label: 'Creator Partnership Help', customIcon: 'assets/images/icon_partnership.png'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: DesignTokens.s12,
      mainAxisSpacing: DesignTokens.s12,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions
          .map(
            (a) => GestureDetector(
              onTap: () => _showCreateTicketSheet(prefilledIssue: a.label),
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.s16),
                decoration: DesignTokens.cardDecoration(),
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

  static final _sampleTickets = [
    Ticket(
      id: '1',
      ticketNumber: '#ST890087',
      subject: 'I cannot add new products to my inventory',
      status: TicketStatus.open,
      createdAt: DateTime(2025, 9, 25, 16, 53),
      lastUpdated: DateTime(2025, 9, 25, 16, 53),
      lastMessagePreview: null,
    ),
    Ticket(
      id: '2',
      ticketNumber: '#ST890086',
      subject: 'My product analytics screen is not loading',
      status: TicketStatus.open,
      createdAt: DateTime(2025, 9, 25, 16, 53),
      lastUpdated: DateTime(2025, 9, 25, 16, 53),
      lastMessagePreview: null,
    ),
    Ticket(
      id: '3',
      ticketNumber: '#ST890085',
      subject: 'Payout not received for last week',
      status: TicketStatus.inProgress,
      createdAt: DateTime(2025, 9, 20, 10, 30),
      lastUpdated: DateTime(2025, 9, 20, 10, 30),
      lastMessagePreview: null,
    ),
    Ticket(
      id: '4',
      ticketNumber: '#ST890084',
      subject: 'Inventory sync issue with bulk upload',
      status: TicketStatus.resolved,
      createdAt: DateTime(2025, 9, 15, 9, 0),
      lastUpdated: DateTime(2025, 9, 15, 9, 0),
      lastMessagePreview: null,
    ),
  ];

  Widget _buildYourTickets() {
    final state = ref.watch(supportNotifierProvider);

    final apiTickets = state.maybeWhen(
      loadSuccess: (t) => t,
      orElse: () => <Ticket>[],
    );

    // Use sample tickets when API returns empty (for preview/testing)
    final allTickets = apiTickets.isEmpty ? _sampleTickets : apiTickets;

    final submitted = allTickets.where((t) => t.status == TicketStatus.open).toList();
    final inProgress = allTickets.where((t) => t.status == TicketStatus.inProgress).toList();
    final resolved = allTickets
        .where((t) => t.status == TicketStatus.resolved || t.status == TicketStatus.closed)
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
              padding: EdgeInsets.only(right: i < tabs.length - 1 ? DesignTokens.s8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s12,
                    vertical: DesignTokens.s6,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? DesignTokens.primaryGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                    border: Border.all(
                      color: selected ? DesignTokens.primaryGreen : DesignTokens.borderDefault,
                    ),
                  ),
                  child: Text(
                    '${tab.label}(${tab.count})',
                    style: DesignTokens.smallRegular.copyWith(
                      color: selected ? Colors.black : DesignTokens.textMuted,
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
          const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen))
        else if (currentTickets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
            child: Center(
              child: Text(
                'No tickets',
                style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentTickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s8),
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
        decoration: DesignTokens.cardDecoration(),
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
                    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite),
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
            const Icon(Icons.arrow_forward_ios, color: DesignTokens.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period, ${_dayOrdinal(dt.day)} ${_monthName(dt.month)} ${dt.year}';
  }

  String _dayOrdinal(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) { 1 => '${d}st', 2 => '${d}nd', 3 => '${d}rd', _ => '${d}th' };
  }

  String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}

// ── Ticket detail sheet ───────────────────────────────────────────────────────

class _TicketDetailSheet extends StatelessWidget {
  const _TicketDetailSheet({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                child: const Icon(Icons.close, color: DesignTokens.textWhite, size: 22),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          // Issue Category
          Text(
            'Issue Category',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text('Product', style: DesignTokens.oneLinerRegular),
          const SizedBox(height: DesignTokens.s12),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: DesignTokens.s6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(ticket.status),
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite),
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
                style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
              ),
              Text(_formatDateTime(ticket.createdAt), style: DesignTokens.smallRegular),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          // Attachments
          Text(
            'Attachments',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              _buildThumbnail('assets/images/attachment_1.png', false),
              const SizedBox(width: DesignTokens.s8),
              _buildThumbnail('assets/images/attachment_2.png', false),
              const SizedBox(width: DesignTokens.s8),
              _buildThumbnail('assets/images/attachment_3.png', true),
            ],
          ),
        ],
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
    TicketStatus.closed => 'Closed',
  };

  String _formatDateTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period, ${_dayOrdinal(dt.day)} ${_monthName(dt.month)} ${dt.year}';
  }

  String _dayOrdinal(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) { 1 => '${d}st', 2 => '${d}nd', 3 => '${d}rd', _ => '${d}th' };
  }

  String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
  String? _selectedCategory;
  final List<XFile> _selectedImages = [];
  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _selectedImages.addAll(picked));
    }
  }

  void _removeImage(int index) => setState(() => _selectedImages.removeAt(index));

  static const _categories = [
    'Product',
    'Order Fulfillment',
    'Inventory',
    'Payment & Payouts',
    'Creator Partnership',
    'Account & Settings',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledIssue != null) {
      _descController.text = widget.prefilledIssue!;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_descController.text.trim().isEmpty) return;
    ref.read(createTicketNotifierProvider.notifier).submit(
      subject: _descController.text.trim(),
      message: _descController.text.trim(),
      categoryId: _selectedCategory,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.s16,
        right: DesignTokens.s16,
        top: DesignTokens.s16,
        bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Create Support Ticket', style: DesignTokens.mediumSemibold)),
              IconButton(
                icon: const Icon(Icons.close, color: DesignTokens.textMuted, size: 20),
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
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.inputFieldFill,
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                border: Border.all(color: DesignTokens.inputFieldBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCategory ?? 'Issue Category',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        color: _selectedCategory != null
                            ? DesignTokens.inputFieldData
                            : DesignTokens.inputFieldPlaceholder,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: DesignTokens.inputFieldDropdownIcon, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          TextField(
            controller: _descController,
            maxLines: 4,
            style: DesignTokens.oneLinerRegular.copyWith(color: DesignTokens.inputFieldData),
            decoration: DesignTokens.inputDecoration(hintText: 'Describe Issue'),
          ),
          const SizedBox(height: DesignTokens.s12),
          if (_selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.s8),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
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
                          child: const Icon(Icons.close, color: Colors.white, size: 12),
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
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                border: Border.all(color: DesignTokens.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_outlined, color: DesignTokens.textWhite, size: 20),
                  const SizedBox(width: DesignTokens.s8),
                  Text('Upload Images', style: DesignTokens.oneLinerSemibold),
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
                style: DesignTokens.oneLinerSemibold.copyWith(color: DesignTokens.buttonPrimaryText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.cardRadius)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignTokens.s12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: DesignTokens.borderDefault, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: DesignTokens.s16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: Align(alignment: Alignment.centerLeft, child: Text('Issue Category', style: DesignTokens.oneLinerSemibold)),
          ),
          const SizedBox(height: DesignTokens.s8),
          ..._categories.map(
            (c) => ListTile(
              title: Text(c, style: DesignTokens.oneLinerRegular),
              onTap: () { setState(() => _selectedCategory = c); Navigator.of(ctx).pop(); },
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
        ],
      ),
    ).ignore();
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _Channel {
  const _Channel({required this.icon, required this.title, required this.subtitle, required this.onTap, this.customIcon, this.subtitleColor});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? customIcon;
  final Color? subtitleColor;
}

class _QuickAction {
  const _QuickAction({required this.icon, required this.label, this.customIcon});
  final IconData icon;
  final String label;
  final String? customIcon;
}

class _TabItem {
  const _TabItem({required this.label, required this.count});
  final String label;
  final int count;
}
