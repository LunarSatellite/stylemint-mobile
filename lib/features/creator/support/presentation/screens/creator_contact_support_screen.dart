import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorContactSupportScreen extends StatefulWidget {
  const CreatorContactSupportScreen({super.key});

  @override
  State<CreatorContactSupportScreen> createState() =>
      _CreatorContactSupportScreenState();
}

class _CreatorContactSupportScreenState
    extends State<CreatorContactSupportScreen> {
  _TicketFilter _activeFilter = _TicketFilter.submitted;

  List<_SupportChannel> _channels(BuildContext context) => [
    const _SupportChannel(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Creator Support Chat',
      subtitle: 'Available • Wait: 2min',
    ),
    const _SupportChannel(
      icon: Icons.email_outlined,
      title: 'Email Support',
      subtitle: 'Response within 12 hours',
    ),
    const _SupportChannel(
      icon: Icons.phone_outlined,
      title: 'Creator Hotline (1-800-CREATE)',
      subtitle: 'Mon-Fri, 9 AM - 6 PM EST',
    ),
    _SupportChannel(
      icon: Icons.library_books_outlined,
      title: 'Creator Resources',
      subtitle: 'Articles & Help for creators',
      onTap: () => _showCreatorResources(context),
    ),
  ];

  static const _topics = [
    _Topic(icon: Icons.account_balance_wallet_outlined, label: 'Earnings & Payouts'),
    _Topic(icon: Icons.handshake_outlined, label: 'Brand Partnerships'),
    _Topic(icon: Icons.video_library_outlined, label: 'Content & Reels'),
    _Topic(icon: Icons.analytics_outlined, label: 'Analytics Issues'),
  ];

  List<_Ticket> _tickets = [
    _Ticket(
      id: '#ST890087',
      title: 'I cannot import my reels from my instagr...',
      date: '04:53 PM, 25th Sep 2025',
      filter: _TicketFilter.submitted,
      category: 'Content Problems',
      description: 'I cannot import my reels from my instagram',
      seedAttachmentCount: 5,
    ),
    _Ticket(
      id: '#ST890086',
      title: 'My reels view count data is not showing in...',
      date: '04:53 PM, 25th Sep 2025',
      filter: _TicketFilter.submitted,
      category: 'Analytics Issues',
      description:
          'My reels view count data is not showing in the analytics dashboard.',
      seedAttachmentCount: 2,
    ),
    _Ticket(
      id: '#ST890085',
      title: 'Brand partnership payment not received',
      date: '10:00 AM, 20th Sep 2025',
      filter: _TicketFilter.inProgress,
      category: 'Earnings & Payouts',
      description:
          'Brand partnership payment not received after campaign completion.',
    ),
    _Ticket(
      id: '#ST890084',
      title: 'Earnings payout delayed for over a week',
      date: '08:30 AM, 15th Sep 2025',
      filter: _TicketFilter.resolved,
      category: 'Earnings & Payouts',
      description: 'Earnings payout has been delayed for over a week.',
      seedAttachmentCount: 1,
    ),
  ];

  void _showCreatorResources(BuildContext context) {
    unawaited(showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreatorResourcesSheet(),
    ));
  }

  void _showTicketDetail(BuildContext context, _Ticket ticket) {
    unawaited(showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TicketDetailSheet(ticket: ticket),
    ));
  }

  void _showCreateTicket(BuildContext context) {
    unawaited(showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CreateTicketSheet(
        onSubmit: (ticket) => setState(() {
          _tickets = [..._tickets, ticket];
          _activeFilter = _TicketFilter.submitted;
        }),
      ),
    ));
  }

  List<_Ticket> get _visibleTickets =>
      _tickets.where((t) => t.filter == _activeFilter).toList();

  int _count(_TicketFilter f) => _tickets.where((t) => t.filter == f).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Contact Support', style: DesignTokens.sectionInnerTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16, DesignTokens.s8,
                DesignTokens.s16, DesignTokens.s32,
              ),
              children: [
                _WelcomeBanner(),
                const SizedBox(height: DesignTokens.s16),
                _ChannelList(channels: _channels(context)),
                const SizedBox(height: DesignTokens.s16),
                _TopicsGrid(topics: _topics),
                const SizedBox(height: DesignTokens.s24),
                const Text(
                  'Your Support Tickets',
                  style: DesignTokens.oneLinerSemibold,
                ),
                const SizedBox(height: DesignTokens.s12),
                _FilterTabs(
                  active: _activeFilter,
                  counts: {
                    _TicketFilter.submitted: _count(_TicketFilter.submitted),
                    _TicketFilter.inProgress: _count(_TicketFilter.inProgress),
                    _TicketFilter.resolved: _count(_TicketFilter.resolved),
                  },
                  onChanged: (f) => setState(() => _activeFilter = f),
                ),
                const SizedBox(height: DesignTokens.s12),
                ..._visibleTickets.map(
                  (t) => _TicketCard(
                    ticket: t,
                    onTap: () => _showTicketDetail(context, t),
                  ),
                ),
              ],
            ),
          ),
          _BottomButton(
            onTap: () => _showCreateTicket(context),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome banner
// ---------------------------------------------------------------------------
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
                const Text(
                  'Welcome to Support',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How can we help you today?',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    color: DesignTokens.textDark.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Image.asset(
            'assets/images/support/phone.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Support channel list
// ---------------------------------------------------------------------------
class _ChannelList extends StatelessWidget {
  final List<_SupportChannel> channels;
  const _ChannelList({required this.channels});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: List.generate(channels.length, (i) {
          final ch = channels[i];
          final isLast = i == channels.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: ch.onTap ?? () {},
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(DesignTokens.cardRadius) : Radius.zero,
                  bottom: isLast ? const Radius.circular(DesignTokens.cardRadius) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppBodyLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(ch.icon,
                            size: 20, color: DesignTokens.textLight),
                      ),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ch.title,
                              style: const TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DesignTokens.textWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ch.subtitle,
                              style: const TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 12,
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 20, color: DesignTokens.textMuted),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1, thickness: 1, color: DesignTokens.borderDefault,
                    indent: DesignTokens.s16, endIndent: DesignTokens.s16),
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick topics 2x2 grid
// ---------------------------------------------------------------------------
class _TopicsGrid extends StatelessWidget {
  final List<_Topic> topics;
  const _TopicsGrid({required this.topics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: DesignTokens.s12,
      mainAxisSpacing: DesignTokens.s12,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: topics
          .map((t) => _TopicCard(topic: t))
          .toList(),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final _Topic topic;
  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(topic.icon, size: 22, color: DesignTokens.textLight),
              const SizedBox(height: DesignTokens.s8),
              Text(
                topic.label,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.textWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter tabs
// ---------------------------------------------------------------------------
class _FilterTabs extends StatelessWidget {
  final _TicketFilter active;
  final Map<_TicketFilter, int> counts;
  final ValueChanged<_TicketFilter> onChanged;

  const _FilterTabs({
    required this.active,
    required this.counts,
    required this.onChanged,
  });

  static const _labels = {
    _TicketFilter.submitted: 'Submitted',
    _TicketFilter.inProgress: 'In Progress',
    _TicketFilter.resolved: 'Resolved',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _TicketFilter.values.map((f) {
          final isActive = f == active;
          final label = '${_labels[f]}(${counts[f]})';
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.s8),
            child: GestureDetector(
              onTap: () => onChanged(f),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
                decoration: BoxDecoration(
                  color: isActive ? DesignTokens.chipsSelectedFill : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
                  border: Border.all(
                    color: isActive
                        ? DesignTokens.primaryGreen
                        : DesignTokens.chipsDefaultBorder,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? DesignTokens.primaryGreen
                        : DesignTokens.chipsDefaultText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ticket card
// ---------------------------------------------------------------------------
class _TicketCard extends StatelessWidget {
  final _Ticket ticket;
  final VoidCallback onTap;
  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
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
                  ticket.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Ticket ID: ${ticket.id}',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: DesignTokens.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      ticket.date,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: DesignTokens.textMuted),
        ],
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom button
// ---------------------------------------------------------------------------
class _BottomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BottomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
            top: BorderSide(color: DesignTokens.borderDefault, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, DesignTokens.s32),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: DesignTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: onTap,
            style: DesignTokens.primaryButtonStyle(),
            child: const Text(
              'Create Support Ticket',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DesignTokens.buttonPrimaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
enum _TicketFilter { submitted, inProgress, resolved }

class _SupportChannel {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _SupportChannel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}

// ---------------------------------------------------------------------------
// Creator Resources bottom sheet
// ---------------------------------------------------------------------------
class _CreatorResourcesSheet extends StatelessWidget {
  const _CreatorResourcesSheet();

  static const _resources = [
    'Creator Guidelines',
    'Earnings FAQ',
    'Partnership Best Practices',
    'Content Tips & Tricks',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: DesignTokens.borderDefault,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        ...List.generate(_resources.length, (i) {
          final isLast = i == _resources.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _resources[i],
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
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
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: DesignTokens.borderDefault,
                  indent: DesignTokens.s16,
                  endIndent: DesignTokens.s16,
                ),
            ],
          );
        }),
        SizedBox(height: MediaQuery.of(context).padding.bottom + DesignTokens.s16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Create Support Ticket bottom sheet
// ---------------------------------------------------------------------------
class _CreateTicketSheet extends StatefulWidget {
  const _CreateTicketSheet({required this.onSubmit});
  final void Function(_Ticket ticket) onSubmit;

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  String? _selectedCategory;
  final _descController = TextEditingController();
  final List<XFile> _images = [];
  final _picker = ImagePicker();

  static const _categories = [
    'Earnings & Payouts',
    'Brand Partnerships',
    'Content & Reels',
    'Analytics Issues',
    'Account Issues',
    'Other',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) setState(() => _images.addAll(picked));
  }

  void _submit() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue category')),
      );
      return;
    }
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }
    final now = DateTime.now();
    final id = '#ST${800000 + now.millisecondsSinceEpoch % 99999}';
    final ticket = _Ticket(
      id: id,
      title: desc.length > 42 ? '${desc.substring(0, 39)}...' : desc,
      date: _formatTicketDate(now),
      filter: _TicketFilter.submitted,
      category: _selectedCategory!,
      description: desc,
      images: List<XFile>.from(_images),
    );
    Navigator.pop(context);
    widget.onSubmit(ticket);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16, DesignTokens.s20,
              DesignTokens.s8, DesignTokens.s16,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Create Support Ticket',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close,
                      size: 20, color: DesignTokens.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: DesignTokens.s8),
              ],
            ),
          ),
          // Category dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text(
                'Issue Category',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.textMuted,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: DesignTokens.textMuted,
              ),
              dropdownColor: DesignTokens.bgAppBodyLight,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                color: DesignTokens.textWhite,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: DesignTokens.bgAppBodyLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: DesignTokens.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: DesignTokens.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: DesignTokens.primaryGreen),
                ),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          // Describe issue textarea
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: TextFormField(
              controller: _descController,
              maxLines: 5,
              minLines: 4,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                color: DesignTokens.textWhite,
              ),
              decoration: InputDecoration(
                hintText: 'Describe Issue',
                hintStyle: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.textMuted,
                ),
                filled: true,
                fillColor: DesignTokens.bgAppBodyLight,
                contentPadding: const EdgeInsets.all(DesignTokens.s16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: DesignTokens.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: DesignTokens.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: DesignTokens.primaryGreen),
                ),
              ),
            ),
          ),
          // Picked image previews
          if (_images.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16),
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: DesignTokens.s8),
                itemBuilder: (_, i) => _PickedThumb(
                  file: _images[i],
                  onRemove: () => setState(() => _images.removeAt(i)),
                ),
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          // Upload Images
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(
                  Icons.upload_outlined,
                  size: 18,
                  color: DesignTokens.textWhite,
                ),
                label: Text(
                  _images.isEmpty ? 'Upload Images' : 'Add More Images',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.textWhite,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DesignTokens.borderDefault),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          // Submit Ticket
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: _submit,
                style: DesignTokens.primaryButtonStyle(),
                child: const Text(
                  'Submit Ticket',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: safeBottom + DesignTokens.s16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Picked image thumbnail (shown inside create form)
// ---------------------------------------------------------------------------
class _PickedThumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _PickedThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(file.path),
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: DesignTokens.bgAppFoundation,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 12, color: DesignTokens.textWhite),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ticket detail bottom sheet
// ---------------------------------------------------------------------------
class _TicketDetailSheet extends StatelessWidget {
  final _Ticket ticket;
  const _TicketDetailSheet({required this.ticket});

  static const _maxThumbsShown = 3;

  Color _statusBg(_TicketFilter f) {
    switch (f) {
      case _TicketFilter.submitted:
        return DesignTokens.chipsSelectedFill;
      case _TicketFilter.inProgress:
        return const Color(0xFF1A2B00);
      case _TicketFilter.resolved:
        return const Color(0xFF0D1F2D);
    }
  }

  Color _statusBorder(_TicketFilter f) {
    switch (f) {
      case _TicketFilter.submitted:
        return DesignTokens.primaryGreen;
      case _TicketFilter.inProgress:
        return DesignTokens.secondaryYellow;
      case _TicketFilter.resolved:
        return DesignTokens.colorInfo;
    }
  }

  Color _statusText(_TicketFilter f) {
    switch (f) {
      case _TicketFilter.submitted:
        return DesignTokens.primaryGreen;
      case _TicketFilter.inProgress:
        return DesignTokens.secondaryYellow;
      case _TicketFilter.resolved:
        return DesignTokens.colorInfo;
    }
  }

  String _statusLabel(_TicketFilter f) {
    switch (f) {
      case _TicketFilter.submitted:
        return 'Submitted';
      case _TicketFilter.inProgress:
        return 'In Progress';
      case _TicketFilter.resolved:
        return 'Resolved';
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final total = ticket.totalAttachments;
    final showCount = total.clamp(0, _maxThumbsShown);
    final overflow = total - _maxThumbsShown;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16, DesignTokens.s20,
        DesignTokens.s16, safeBottom + DesignTokens.s16,
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
                  'Ticket ID: ${ticket.id}',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    size: 20, color: DesignTokens.textMuted),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          // Issue Category label
          const Text(
            'Issue Category',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          // Category value
          Text(
            ticket.category,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _statusBg(ticket.filter),
              borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
              border: Border.all(color: _statusBorder(ticket.filter)),
            ),
            child: Text(
              _statusLabel(ticket.filter),
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _statusText(ticket.filter),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          // Description
          Text(
            ticket.description,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.textWhite,
              height: 1.5,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          // Info box — always shown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Created on row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Created On',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    Text(
                      ticket.date,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),
                // Attachments label
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                // Thumbnail row OR empty state
                if (total == 0)
                  const Text(
                    'No attachments',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      color: DesignTokens.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Row(
                    children: List.generate(showCount, (i) {
                      final isLast = i == _maxThumbsShown - 1;
                      final hasOverflow = isLast && overflow > 0;
                      final img = i < ticket.images.length
                          ? ticket.images[i]
                          : null;
                      return Padding(
                        padding: EdgeInsets.only(
                            right: i < showCount - 1 ? DesignTokens.s8 : 0),
                        child: _AttachmentThumb(
                          index: i,
                          image: img,
                          overflowCount: hasOverflow ? overflow : 0,
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentThumb extends StatelessWidget {
  final int index;
  final int overflowCount;
  final XFile? image;
  const _AttachmentThumb({
    required this.index,
    required this.overflowCount,
    this.image,
  });

  static const _thumbColors = [
    Color(0xFF2A2A2E),
    Color(0xFF222226),
    Color(0xFF1E1E22),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _thumbColors[index % _thumbColors.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 72,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.file(File(image!.path), fit: BoxFit.cover)
            else
              ColoredBox(color: bg),
            if (overflowCount > 0) ...[
              ColoredBox(
                  color:
                      DesignTokens.bgAppFoundation.withValues(alpha: 0.65)),
              Center(
                child: Text(
                  '+$overflowCount',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Topic {
  final IconData icon;
  final String label;
  const _Topic({required this.icon, required this.label});
}

class _Ticket {
  final String id;
  final String title;
  final String date;
  final _TicketFilter filter;
  final String category;
  final String description;
  final int seedAttachmentCount;
  final List<XFile> images;

  _Ticket({
    required this.id,
    required this.title,
    required this.date,
    required this.filter,
    required this.category,
    required this.description,
    this.seedAttachmentCount = 0,
    List<XFile>? images,
  }) : images = images ?? [];

  int get totalAttachments =>
      images.isNotEmpty ? images.length : seedAttachmentCount;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
String _formatTicketDate(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final min = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final suffix = _daySuffix(dt.day);
  return '$hour:$min $ampm, ${dt.day}$suffix ${months[dt.month - 1]} ${dt.year}';
}

String _daySuffix(int d) {
  if (d >= 11 && d <= 13) return 'th';
  switch (d % 10) {
    case 1: return 'st';
    case 2: return 'nd';
    case 3: return 'rd';
    default: return 'th';
  }
}
