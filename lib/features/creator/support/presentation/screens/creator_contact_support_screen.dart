import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/contact_channels.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/notifiers/support_notifier.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class CreatorContactSupportScreen extends ConsumerStatefulWidget {
  const CreatorContactSupportScreen({super.key});

  @override
  ConsumerState<CreatorContactSupportScreen> createState() =>
      _CreatorContactSupportScreenState();
}

class _CreatorContactSupportScreenState
    extends ConsumerState<CreatorContactSupportScreen> {
  _TicketFilter _activeFilter = _TicketFilter.submitted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(supportNotifierProvider.notifier).loadTickets());
    });
  }

  List<_SupportChannel> _channels(
    BuildContext context,
    ContactChannels? channels,
    bool isLoading,
  ) => [
    _SupportChannel(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Creator Support Chat',
      subtitle: channels == null
          ? isLoading
                ? 'Checking availability…'
                : 'Availability unavailable'
          : channels.liveChatAvailable
          ? 'Available now • ${channels.liveChatHoursLocal}'
          : 'Offline • ${channels.liveChatHoursLocal}',
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Live-chat availability is shown above. Chat sessions are not yet available in this app; please create a support ticket.',
          ),
        ),
      ),
    ),
    _SupportChannel(
      icon: Icons.email_outlined,
      title: 'Email Support',
      subtitle: channels?.supportEmail.isNotEmpty == true
          ? channels!.supportEmail
          : isLoading
          ? 'Loading support email…'
          : 'Email unavailable',
      onTap: channels?.supportEmail.isNotEmpty == true
          ? () => unawaited(
              launchUrl(Uri(scheme: 'mailto', path: channels!.supportEmail)),
            )
          : null,
    ),
    _SupportChannel(
      icon: Icons.phone_outlined,
      title: 'Direct Call',
      subtitle: channels?.directCallPhoneE164.isNotEmpty == true
          ? channels!.directCallPhoneE164
          : isLoading
          ? 'Loading direct-call number…'
          : 'Phone unavailable',
      onTap: channels?.directCallPhoneE164.isNotEmpty == true
          ? () => unawaited(
              launchUrl(
                Uri(scheme: 'tel', path: channels!.directCallPhoneE164),
              ),
            )
          : null,
    ),
    _SupportChannel(
      icon: Icons.library_books_outlined,
      title: 'Creator Resources',
      subtitle: 'Articles & Help for creators',
      onTap: () => _showCreatorResources(context),
    ),
  ];

  static const _topics = [
    _Topic(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Earnings & Payouts',
    ),
    _Topic(icon: Icons.handshake_outlined, label: 'Brand Partnerships'),
    _Topic(icon: Icons.video_library_outlined, label: 'Content & Reels'),
    _Topic(icon: Icons.analytics_outlined, label: 'Analytics Issues'),
  ];

  void _showCreatorResources(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: DesignTokens.bgAppBody,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const _CreatorResourcesSheet(),
      ),
    );
  }

  void _showTicketDetail(BuildContext context, Ticket ticket) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: DesignTokens.bgAppBody,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _TicketDetailSheet(ticket: ticket),
      ),
    );
  }

  void _showCreateTicket(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: DesignTokens.bgAppBody,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const _CreateTicketSheet(),
      ),
    );
  }

  List<Ticket> _filtered(List<Ticket> tickets) =>
      tickets.where((t) => t.status.toFilter == _activeFilter).toList();

  int _count(List<Ticket> tickets, _TicketFilter f) =>
      tickets.where((t) => t.status.toFilter == f).length;

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(supportNotifierProvider);
    final contactChannels = ref.watch(contactChannelsProvider);
    final isLoading = ticketsState.when(
      initial: () => false,
      loadInProgress: () => true,
      loadSuccess: (_) => false,
      loadFailure: (_) => false,
    );
    final tickets = ticketsState.when(
      initial: () => <Ticket>[],
      loadInProgress: () => <Ticket>[],
      loadSuccess: (t) => t,
      loadFailure: (_) => <Ticket>[],
    );
    final visible = _filtered(tickets);

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
        title: const Text(
          'Contact Support',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: SafeArea(
        child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                DesignTokens.s32,
              ),
              children: [
                _WelcomeBanner(),
                const SizedBox(height: DesignTokens.s16),
                _ChannelList(
                  channels: _channels(
                    context,
                    contactChannels.when(
                      data: (value) => value,
                      loading: () => null,
                      error: (_, __) => null,
                    ),
                    contactChannels.isLoading,
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                _TopicsGrid(
                  topics: _topics,
                  // No 1:1 mapping from these creator-facing topic buckets
                  // to the backend's generic TicketCategory taxonomy, so
                  // just open ticket creation rather than guessing a
                  // category — better than a silent no-op.
                  onTopicTap: () => _showCreateTicket(context),
                ),
                const SizedBox(height: DesignTokens.s24),
                const Text(
                  'Your Support Tickets',
                  style: DesignTokens.oneLinerSemibold,
                ),
                const SizedBox(height: DesignTokens.s12),
                _FilterTabs(
                  active: _activeFilter,
                  counts: {
                    _TicketFilter.submitted: _count(
                      tickets,
                      _TicketFilter.submitted,
                    ),
                    _TicketFilter.inProgress: _count(
                      tickets,
                      _TicketFilter.inProgress,
                    ),
                    _TicketFilter.resolved: _count(
                      tickets,
                      _TicketFilter.resolved,
                    ),
                  },
                  onChanged: (f) => setState(() => _activeFilter = f),
                ),
                const SizedBox(height: DesignTokens.s12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: DesignTokens.s24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.s24,
                    ),
                    child: Center(
                      child: Text(
                        'Your ${_activeFilter == _TicketFilter.submitted
                            ? 'submitted'
                            : _activeFilter == _TicketFilter.inProgress
                            ? 'in progress'
                            : 'resolved'} support tickets will show here',
                        textAlign: TextAlign.center,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  ...visible.map(
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'How can we help you today?',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.buttonPrimaryText,
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
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 72,
              height: 72,
              child: Icon(
                Icons.support_agent_rounded,
                size: 44,
                color: DesignTokens.textDark,
              ),
            ),
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
                  top: i == 0
                      ? const Radius.circular(DesignTokens.cardRadius)
                      : Radius.zero,
                  bottom: isLast
                      ? const Radius.circular(DesignTokens.cardRadius)
                      : Radius.zero,
                ),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          ch.icon,
                          size: 20,
                          color: DesignTokens.textLight,
                        ),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick topics 2x2 grid
// ---------------------------------------------------------------------------
class _TopicsGrid extends StatelessWidget {
  final List<_Topic> topics;
  final VoidCallback onTopicTap;
  const _TopicsGrid({required this.topics, required this.onTopicTap});

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
          .map((t) => _TopicCard(topic: t, onTap: onTopicTap))
          .toList(),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final _Topic topic;
  final VoidCallback onTap;
  const _TopicCard({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: InkWell(
        onTap: onTap,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: DesignTokens.textLight,
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
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? DesignTokens.chipsSelectedFill
                      : Colors.transparent,
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
  final Ticket ticket;
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
                    ticket.subject,
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
                    'Ticket ID: ${ticket.ticketNumber}',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
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
                        _formatTicketDate(ticket.createdAt),
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
          top: BorderSide(color: DesignTokens.borderDefault, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
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
// Data models / enums
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

class _Topic {
  final IconData icon;
  final String label;
  const _Topic({required this.icon, required this.label});
}

extension _TicketStatusFilter on TicketStatus {
  _TicketFilter get toFilter {
    switch (this) {
      case TicketStatus.open:
        return _TicketFilter.submitted;
      case TicketStatus.inProgress:
        return _TicketFilter.inProgress;
      case TicketStatus.resolved:
        return _TicketFilter.resolved;
    }
  }
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
                // No help-article backend exists (support module only
                // models tickets, not a CMS) — same as the vendor
                // Resources sheet, this just closes rather than opening
                // content that doesn't exist.
                onTap: () => Navigator.of(context).pop(),
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
        SizedBox(
          height: MediaQuery.of(context).padding.bottom + DesignTokens.s16,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Create Support Ticket bottom sheet
// ---------------------------------------------------------------------------
/// Display label for the backend-aligned support category taxonomy.
String _ticketCategoryLabel(TicketCategory c) {
  switch (c) {
    case TicketCategory.ordersAndShipping:
      return 'Orders & Shipping';
    case TicketCategory.returnsAndRefunds:
      return 'Returns & Refunds';
    case TicketCategory.accountAndSettings:
      return 'Account & Settings';
    case TicketCategory.paymentAndBilling:
      return 'Payment & Billing';
    case TicketCategory.safetyAndPrivacy:
      return 'Safety & Privacy';
    case TicketCategory.forCreators:
      return 'For Creators';
    case TicketCategory.forVendors:
      return 'For Vendors';
    case TicketCategory.deliveryAndCouriers:
      return 'Delivery & Couriers';
  }
}

class _CreateTicketSheet extends ConsumerStatefulWidget {
  const _CreateTicketSheet();

  @override
  ConsumerState<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends ConsumerState<_CreateTicketSheet> {
  TicketCategory? _selectedCategory;
  final _descController = TextEditingController();
  final List<XFile> _images = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) setState(() => _images.addAll(picked));
  }

  Future<void> _submit() async {
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
    await ref
        .read(createTicketNotifierProvider.notifier)
        .submit(
          category: _selectedCategory!,
          subject: _ticketCategoryLabel(_selectedCategory!),
          message: desc,
        );
    if (!mounted) return;
    ref
        .read(createTicketNotifierProvider)
        .when(
          initial: () {},
          submitting: () {},
          success: (_) {
            unawaited(ref.read(supportNotifierProvider.notifier).loadTickets());
            Navigator.pop(context);
          },
          failure: (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.isNoInternet
                      ? 'No internet connection'
                      : 'Failed to submit ticket. Please try again.',
                ),
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref
        .watch(createTicketNotifierProvider)
        .when(
          initial: () => false,
          submitting: () => true,
          success: (_) => false,
          failure: (_) => false,
        );
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
              DesignTokens.s16,
              DesignTokens.s20,
              DesignTokens.s8,
              DesignTokens.s16,
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
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: DesignTokens.textMuted,
                  ),
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
            child: DropdownButtonFormField<TicketCategory>(
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
                  borderSide: const BorderSide(
                    color: DesignTokens.borderDefault,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: DesignTokens.borderDefault,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
              items: TicketCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(_ticketCategoryLabel(c)),
                    ),
                  )
                  .toList(),
              onChanged: isSubmitting
                  ? null
                  : (v) => setState(() => _selectedCategory = v),
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
              enabled: !isSubmitting,
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
                  borderSide: const BorderSide(
                    color: DesignTokens.borderDefault,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: DesignTokens.borderDefault,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: DesignTokens.primaryGreen,
                  ),
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
                  horizontal: DesignTokens.s16,
                ),
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
                onPressed: isSubmitting ? null : _pickImages,
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
                    borderRadius: BorderRadius.circular(
                      DesignTokens.buttonRadius,
                    ),
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
                onPressed: isSubmitting ? null : _submit,
                style: DesignTokens.primaryButtonStyle(),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DesignTokens.buttonPrimaryText,
                        ),
                      )
                    : const Text(
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
              child: const Icon(
                Icons.close,
                size: 12,
                color: DesignTokens.textWhite,
              ),
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
  final Ticket ticket;
  const _TicketDetailSheet({required this.ticket});

  Color _statusBg(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return DesignTokens.chipsSelectedFill;
      case TicketStatus.inProgress:
        return const Color(0xFF1A2B00);
      case TicketStatus.resolved:
        return const Color(0xFF0D1F2D);
    }
  }

  Color _statusAccent(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return DesignTokens.primaryGreen;
      case TicketStatus.inProgress:
        return DesignTokens.secondaryYellow;
      case TicketStatus.resolved:
        return DesignTokens.colorInfo;
    }
  }

  String _statusLabel(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return 'Submitted';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s20,
        DesignTokens.s16,
        safeBottom + DesignTokens.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ticket ID: ${ticket.ticketNumber}',
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
                child: const Icon(
                  Icons.close,
                  size: 20,
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          const Text(
            'Issue Category',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ticket.subject,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _statusBg(ticket.status),
              borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
              border: Border.all(color: _statusAccent(ticket.status)),
            ),
            child: Text(
              _statusLabel(ticket.status),
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _statusAccent(ticket.status),
              ),
            ),
          ),
          ...[
            const SizedBox(height: DesignTokens.s12),
            Text(
              'Last update: ${_formatTicketDate(ticket.lastUpdated)}',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                color: DesignTokens.textWhite,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s16),
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
                      _formatTicketDate(ticket.createdAt),
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                const Text(
                  'No attachments',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    color: DesignTokens.textMuted,
                    fontStyle: FontStyle.italic,
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
String _formatTicketDate(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final min = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  const months = [
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
  ];
  final suffix = _daySuffix(dt.day);
  return '$hour:$min $ampm, ${dt.day}$suffix ${months[dt.month - 1]} ${dt.year}';
}

String _daySuffix(int d) {
  if (d >= 11 && d <= 13) return 'th';
  switch (d % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
