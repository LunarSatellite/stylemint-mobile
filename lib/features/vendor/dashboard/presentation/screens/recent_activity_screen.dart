import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class RecentActivityScreen extends ConsumerStatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  ConsumerState<RecentActivityScreen> createState() =>
      _RecentActivityScreenState();
}

class _RecentActivityScreenState extends ConsumerState<RecentActivityScreen> {
  final Set<_ActivityType> _activeFilters = {};

  List<_ActivityGroup> _filtered(List<_ActivityGroup> groups) {
    if (_activeFilters.isEmpty) return groups;
    return groups
        .map(
          (g) => _ActivityGroup(
            date: g.date,
            items: g.items
                .where((i) => _activeFilters.contains(i.type))
                .toList(),
          ),
        )
        .where((g) => g.items.isNotEmpty)
        .toList();
  }

  List<_ActivityGroup> _groupsFor(VendorActivityState state) {
    return state.maybeWhen(
      loadSuccess: (entries) {
        final byDate = <String, List<_ActivityItem>>{};
        for (final e in entries) {
          final label = _dateGroupLabel(e.occurredUtc);
          (byDate[label] ??= []).add(
            _ActivityItem(
              type: _guessActivityType(e.headline),
              title: e.headline?.isNotEmpty == true ? e.headline! : 'Activity',
              description: e.body ?? '',
              time: formatRelative(e.occurredUtc),
              actionLabel: e.actionUrl != null ? 'View' : null,
            ),
          );
        }
        return byDate.entries
            .map((e) => _ActivityGroup(date: e.key, items: e.value))
            .toList();
      },
      orElse: () => const [],
    );
  }

  static String _dateGroupLabel(DateTime utc) {
    final local = utc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    switch (today.difference(day).inDays) {
      case 0:
        return 'Today';
      case 1:
        return 'Yesterday';
      default:
        return DateFormat('EEE d MMM yyyy').format(local);
    }
  }

  /// The backend's `VendorActivityKind` has no published int-to-label
  /// mapping, so this is a best-effort keyword guess purely for choosing an
  /// icon/color — it never drives filtering logic against real business
  /// meaning, only cosmetic grouping.
  static _ActivityType _guessActivityType(String? headline) {
    final h = (headline ?? '').toLowerCase();
    if (h.contains('ship')) return _ActivityType.orderShipped;
    if (h.contains('payout')) return _ActivityType.payoutReceived;
    if (h.contains('stock') || h.contains('low'))
      return _ActivityType.inventoryLowAlerts;
    if (h.contains('product') && h.contains('add'))
      return _ActivityType.productsAdded;
    if (h.contains('product')) return _ActivityType.productsUpdated;
    if (h.contains('inquiry') || h.contains('question'))
      return _ActivityType.customerInquiry;
    return _ActivityType.orderReceived;
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(vendorActivityNotifierProvider);
    final groups = _filtered(_groupsFor(activityState));
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
        title: Text('Recent Activity', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/vendordashboard/icon_filter_alt.png',
              width: 22,
              height: 22,
            ),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: Image.asset(
              'assets/images/vendordashboard/icon_file_export.png',
              width: 22,
              height: 22,
            ),
            onPressed: () => _exportActivity(groups),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activeFilters.isNotEmpty) _buildActiveFilterChips(),
          Expanded(child: _buildBody(activityState, groups)),
        ],
      ),
    );
  }

  void _exportActivity(List<_ActivityGroup> groups) {
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There is no activity to export yet.')),
      );
      return;
    }

    final lines = <String>['Style Mint — Recent activity', ''];
    for (final group in groups) {
      lines.add(group.date);
      for (final item in group.items) {
        final detail = item.description.isEmpty ? '' : ' — ${item.description}';
        lines.add('• ${item.time}: ${item.title}$detail');
      }
      lines.add('');
    }
    unawaited(SharePlus.instance.share(ShareParams(text: lines.join('\n'))));
  }

  Widget _buildBody(
    VendorActivityState activityState,
    List<_ActivityGroup> groups,
  ) {
    return activityState.maybeWhen(
      loadInProgress: () => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      ),
      loadFailure: (_) => SmErrorView(
        message: 'Failed to load recent activity.',
        onRetry: () => ref.read(vendorActivityNotifierProvider.notifier).load(),
      ),
      orElse: () => groups.isEmpty
          ? Center(
              child: Text(
                _activeFilters.isEmpty
                    ? 'No recent activity yet.'
                    : 'No activity matches the selected filters.',
                style: const TextStyle(color: DesignTokens.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              itemCount: groups.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.s12),
              itemBuilder: (_, gi) => _ActivityGroupCard(group: groups[gi]),
            ),
    );
  }

  Widget _buildActiveFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s6,
      ),
      child: Row(
        children: _activeFilters
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: DesignTokens.s8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DesignTokens.primaryGreen),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        f.label,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          color: DesignTokens.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _activeFilters.remove(f)),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        selected: Set.from(_activeFilters),
        onApply: (filters) => setState(() {
          _activeFilters.clear();
          _activeFilters.addAll(filters);
        }),
        onClear: () => setState(() => _activeFilters.clear()),
      ),
    );
  }
}

class _ActivityGroupCard extends StatelessWidget {
  const _ActivityGroupCard({required this.group});
  final _ActivityGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s8),
          child: Text(
            group.date,
            style: DesignTokens.smallRegular.copyWith(
              color: const Color(0xFFD4D4D8),
              fontSize: 12,
            ),
          ),
        ),
        Container(
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            children: [
              for (int i = 0; i < group.items.length; i++) ...[
                if (i > 0)
                  const Divider(
                    color: DesignTokens.borderDefault,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                _ActivityRow(
                  item: group.items[i],
                  isLast: i == group.items.length - 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.isLast});
  final _ActivityItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline icon + line
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: item.type.iconColor.withValues(alpha: 0.3),
                    ),
                    shape: BoxShape.circle,
                    color: item.type.iconColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    item.type.icon,
                    color: item.type.iconColor,
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 24,
                    color: DesignTokens.borderDefault,
                    margin: const EdgeInsets.only(top: 4),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: DesignTokens.smallRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: DesignTokens.smallRegular.copyWith(
                    color: const Color(0xFFD4D4D8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.time,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (item.actionLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.actionLabel!,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.selected,
    required this.onApply,
    required this.onClear,
  });
  final Set<_ActivityType> selected;
  final ValueChanged<Set<_ActivityType>> onApply;
  final VoidCallback onClear;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<_ActivityType> _current;

  @override
  void initState() {
    super.initState();
    _current = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Recent Activity',
                  style: DesignTokens.mediumSemibold,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: DesignTokens.textMuted,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            ..._ActivityType.values.map(
              (type) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _current.contains(type),
                activeColor: DesignTokens.primaryGreen,
                checkColor: Colors.black,
                title: Text(
                  type.label,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                ),
                onChanged: (v) => setState(
                  () => v! ? _current.add(type) : _current.remove(type),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: DesignTokens.buttonHeight,
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onClear();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2E),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Clear',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: SizedBox(
                    height: DesignTokens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_current);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: DesignTokens.smallRegular.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    );
  }
}

enum _ActivityType {
  orderReceived,
  orderShipped,
  productsAdded,
  productsUpdated,
  payoutReceived,
  inventoryLowAlerts,
  customerInquiry;

  String get label {
    switch (this) {
      case orderReceived:
        return 'Orders Received';
      case orderShipped:
        return 'Orders Shipped';
      case productsAdded:
        return 'Products Added';
      case productsUpdated:
        return 'Products Updated';
      case payoutReceived:
        return 'Payout Received';
      case inventoryLowAlerts:
        return 'Inventory Low Alerts';
      case customerInquiry:
        return 'Customer Inquiries';
    }
  }

  IconData get icon {
    switch (this) {
      case orderReceived:
        return Icons.shopping_bag_outlined;
      case orderShipped:
        return Icons.local_shipping_outlined;
      case productsAdded:
        return Icons.add_box_outlined;
      case productsUpdated:
        return Icons.inventory_2_outlined;
      case payoutReceived:
        return Icons.account_balance_wallet_outlined;
      case inventoryLowAlerts:
        return Icons.warning_amber_outlined;
      case customerInquiry:
        return Icons.chat_bubble_outline;
    }
  }

  Color get iconColor {
    switch (this) {
      case orderReceived:
        return DesignTokens.primaryGreen;
      case orderShipped:
        return const Color(0xFF4DA6FF);
      case productsAdded:
        return DesignTokens.primaryGreen;
      case productsUpdated:
        return const Color(0xFFFFB800);
      case payoutReceived:
        return const Color(0xFF4DA6FF);
      case inventoryLowAlerts:
        return DesignTokens.colorError;
      case customerInquiry:
        return const Color(0xFFFFB800);
    }
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    this.actionLabel,
  });
  final _ActivityType type;
  final String title;
  final String description;
  final String time;
  final String? actionLabel;
}

class _ActivityGroup {
  const _ActivityGroup({required this.date, required this.items});
  final String date;
  final List<_ActivityItem> items;
}
