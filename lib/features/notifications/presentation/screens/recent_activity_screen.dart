import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';
import 'package:stylemint_mobile_frontend/features/notifications/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

// ── Filter categories ─────────────────────────────────────────────────────────

enum _ActivityCategory {
  all('All'),
  reels('Reels'),
  earnings('Earnings'),
  partnerships('Partnerships'),
  accounts('Accounts');

  const _ActivityCategory(this.label);
  final String label;
}

extension _ActivityCategoryX on ActivityItem {
  _ActivityCategory get category {
    final t = title.toLowerCase();
    if (t.contains('reel') ||
        t.contains('view') ||
        t.contains('published') ||
        t.contains('imported')) {
      return _ActivityCategory.reels;
    }
    if (t.contains('earning') ||
        t.contains('rs ') ||
        t.contains('payout') ||
        t.contains('commission') ||
        t.contains('order') ||
        t.contains('payment')) {
      return _ActivityCategory.earnings;
    }
    if (t.contains('partnership') ||
        t.contains('collaborat') ||
        t.contains('brand') ||
        t.contains('campaign') ||
        t.contains('invite') ||
        t.contains('partner')) {
      return _ActivityCategory.partnerships;
    }
    if (t.contains('milestone') ||
        t.contains('follower') ||
        t.contains('account') ||
        t.contains('profile') ||
        t.contains('achieved')) {
      return _ActivityCategory.accounts;
    }
    return _ActivityCategory.all;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

/// Where the rows come from.
enum RecentActivitySource {
  /// The creator's activity feed (`/v1/creator/activity`). Rows open nothing.
  creatorActivity,

  /// The account's notification inbox (`/v1/notifications/inbox`) — the
  /// buyer's bell. A row opens what the notification is about, exactly as
  /// tapping the push would (see `notification_route.dart`).
  inbox,
}

/// Whether a resolved location may be opened from the inbox. The resolver
/// already refuses backend URLs; this only rules out an empty string.
bool _isOpenable(String? location) => location != null && location.isNotEmpty;

/// The routing view of an inbox [item], or null for a feed row.
NotificationPayload? _payloadOf(ActivityItem item) =>
    item.templateKey == null && item.variablesJson == null
    ? null
    : NotificationPayload.fromInboxJson(
        templateKey: item.templateKey,
        variablesJson: item.variablesJson,
      );

/// Whether tapping [item] goes anywhere, judged without the viewer's roles
/// (which only change where, never whether — except payouts, which always
/// need a vendor or creator role and so always have one here).
bool activityItemOpens(ActivityItem item) {
  final payload = _payloadOf(item);
  if (payload == null) return false;
  if (payload.type?.startsWith('payout.') ?? false) return true;
  return _isOpenable(notificationLocation(payload));
}

class RecentActivityScreen extends ConsumerStatefulWidget {
  const RecentActivityScreen({
    this.source = RecentActivitySource.creatorActivity,
    super.key,
  });

  final RecentActivitySource source;

  @override
  ConsumerState<RecentActivityScreen> createState() =>
      _RecentActivityScreenState();
}

class _RecentActivityScreenState extends ConsumerState<RecentActivityScreen> {
  _ActivityCategory _filter = _ActivityCategory.all;

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (sheetCtx) => _FilterSheet(
        current: _filter,
        onSelected: (cat) {
          setState(() => _filter = cat);
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }

  /// Opens what an inbox row is about — the same destination as tapping its
  /// push, for whichever side of the app the person is on.
  Future<void> _open(ActivityItem item) async {
    final payload = _payloadOf(item);
    if (payload == null) return;
    final router = GoRouter.of(context);
    final viewer = await readNotificationViewer(
      ref,
      location: router.routerDelegate.currentConfiguration.uri.path,
    );
    if (!mounted) return;
    final location = notificationLocation(payload, viewer: viewer);
    if (_isOpenable(location)) unawaited(router.push(location!));
  }

  @override
  Widget build(BuildContext context) {
    final inbox = widget.source == RecentActivitySource.inbox;
    final activity = ref.watch(
      inbox ? notificationInboxProvider : recentActivityProvider,
    );
    final onOpen = inbox
        ? (ActivityItem item) => unawaited(_open(item))
        : null;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Recent Activity', style: DesignTokens.titleMedium),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.filter_list_rounded,
                  color: DesignTokens.textWhite,
                ),
                onPressed: () => _openFilterSheet(context),
              ),
              if (_filter != _ActivityCategory.all)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DesignTokens.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Activity log',
            icon: const Icon(
              Icons.receipt_long_outlined,
              color: DesignTokens.textWhite,
            ),
            // No destination was ever wired up here — was a silent no-op
            // with no tooltip and no feedback at all when tapped.
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Full activity log is coming soon.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Active filter indicator ─────────────────────────────────────
          if (_filter != _ActivityCategory.all)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s12,
                      vertical: DesignTokens.s4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _filter.label,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.buttonPrimaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.s4),
                        GestureDetector(
                          onTap: () => setState(
                            () => _filter = _ActivityCategory.all,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: DesignTokens.s12),

          // ── Activity list ───────────────────────────────────────────────
          Expanded(
            child: activity.when(
              loading: () => const SmPageLoader(),
              error: (_, _e) => Center(
                child: Text(
                  'Failed to load activity.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
              data: (items) {
                final filtered = _filter == _ActivityCategory.all
                    ? items
                    : items.where((i) => i.category == _filter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _filter == _ActivityCategory.all
                          ? 'No activity yet.'
                          : 'No ${_filter.label.toLowerCase()} activity yet.',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  );
                }

                final grouped = _group(filtered);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    0,
                    DesignTokens.s16,
                    DesignTokens.s32,
                  ),
                  itemCount: grouped.length,
                  separatorBuilder: (_, _s) =>
                      const SizedBox(height: DesignTokens.s12),
                  itemBuilder: (_, i) => _ActivityGroup(
                    label: grouped[i].label,
                    items: grouped[i].items,
                    onOpen: onOpen,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_Group> _group(List<ActivityItem> items) {
    final map = <String, List<ActivityItem>>{};
    final order = <String>[];
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    for (final item in items) {
      if (item.occurredAt == null) continue;
      final local = item.occurredAt!.toLocal();
      final day = DateTime(local.year, local.month, local.day);

      final String label;
      if (day == todayDate) {
        label = 'Today';
      } else if (day == yesterdayDate) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEE d MMM yyyy').format(local);
      }

      if (!map.containsKey(label)) {
        map[label] = [];
        order.add(label);
      }
      map[label]!.add(item);
    }

    return order.map((k) => _Group(label: k, items: map[k]!)).toList();
  }
}

class _Group {
  const _Group({required this.label, required this.items});
  final String label;
  final List<ActivityItem> items;
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.current, required this.onSelected});

  final _ActivityCategory current;
  final ValueChanged<_ActivityCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    // Without SafeArea the last option (e.g. "Accounts") renders under
    // the system gesture-nav area on gesture-nav devices, same class of
    // bug as the shipping-address options sheet.
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignTokens.s12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Activity',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          for (final cat in _ActivityCategory.values)
            RadioListTile<_ActivityCategory>(
              value: cat,
              groupValue: current,
              onChanged: (val) {
                if (val != null) onSelected(val);
              },
              activeColor: DesignTokens.primaryGreen,
              title: Text(
                cat.label,
                style: DesignTokens.oneLinerRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
          const SizedBox(height: DesignTokens.s16),
        ],
      ),
    );
  }
}

// ── Activity group card ───────────────────────────────────────────────────────

class _ActivityGroup extends StatelessWidget {
  const _ActivityGroup({
    required this.label,
    required this.items,
    this.onOpen,
  });

  final String label;
  final List<ActivityItem> items;
  final ValueChanged<ActivityItem>? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          for (var i = 0; i < items.length; i++)
            _ActivityRow(
              item: items[i],
              showConnector: i < items.length - 1,
              onOpen: onOpen != null && activityItemOpens(items[i])
                  ? () => onOpen!(items[i])
                  : null,
            ),
        ],
      ),
    );
  }
}

// ── Activity row ──────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.item,
    required this.showConnector,
    this.onOpen,
  });

  final ActivityItem item;
  final bool showConnector;

  /// Opens what the notification is about; null when it is about nothing.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    final row = _content(context);
    if (open == null) return row;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        child: row,
      ),
    );
  }

  Widget _content(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + connector
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: DesignTokens.bgAppBodyLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _iconFor(item.category),
                    size: 20,
                    color: _iconColorFor(item.category),
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1,
                        color: DesignTokens.borderDefault,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          // Text
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: DesignTokens.s4,
                bottom: showConnector ? DesignTokens.s20 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  if (item.occurredAt != null) ...[
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      _timestamp(item.occurredAt!),
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(_ActivityCategory cat) {
    switch (cat) {
      case _ActivityCategory.reels:
        return Icons.play_circle_outline_rounded;
      case _ActivityCategory.earnings:
        return Icons.account_balance_wallet_outlined;
      case _ActivityCategory.partnerships:
        return Icons.handshake_outlined;
      case _ActivityCategory.accounts:
        return Icons.emoji_events_outlined;
      case _ActivityCategory.all:
        return Icons.notifications_none_rounded;
    }
  }

  Color _iconColorFor(_ActivityCategory cat) {
    switch (cat) {
      case _ActivityCategory.reels:
        return DesignTokens.primaryGreen;
      case _ActivityCategory.earnings:
        return DesignTokens.secondaryYellow;
      case _ActivityCategory.partnerships:
        return const Color(0xFF4DA6FF);
      case _ActivityCategory.accounts:
        return const Color(0xFFFF8C42);
      case _ActivityCategory.all:
        return DesignTokens.textWhite;
    }
  }

  String _timestamp(DateTime when) {
    final now = DateTime.now();
    final local = when.toLocal();
    final diff = now.toUtc().difference(when.toUtc());
    final todayDate = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(local.year, local.month, local.day);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && itemDate == todayDate) {
      return '${diff.inHours}h ago';
    }
    if (itemDate == todayDate.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${DateFormat('hh:mm a').format(local)}';
    }
    return '${DateFormat('d MMM').format(local)} at '
        '${DateFormat('hh:mm a').format(local)}';
  }
}
