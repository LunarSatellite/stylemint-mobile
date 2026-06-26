import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/payout_invoice_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Mock data ─────────────────────────────────────────────────────────────────

List<PayoutHistoryEntry> _buildMockEntries() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return [
    // Today — 2 entries
    PayoutHistoryEntry(
      id: 'pay-001',
      title: 'Rs 17,000 Payout to Esewa Wallet',
      accountMask: '****8522',
      dateTime: today.add(const Duration(hours: 10, minutes: 15)),
      status: PayoutStatus.completed,
      subTotalAmount: 17000,
      receiptNo: 'RCP-2026-001',
      txnId: 'TXN-2026-A001',
      payoutTo: 'eSewa — 9840098522',
    ),
    PayoutHistoryEntry(
      id: 'pay-002',
      title: 'Rs 12,500 Payout to NIMB Bank',
      accountMask: '****8909',
      dateTime: today.add(const Duration(hours: 8, minutes: 45)),
      status: PayoutStatus.pending,
      subTotalAmount: 12500,
      receiptNo: 'RCP-2026-002',
      txnId: 'TXN-2026-A002',
      payoutTo: 'NIMB Bank a/c — ****8909',
    ),
    // Yesterday — 2 entries
    PayoutHistoryEntry(
      id: 'pay-003',
      title: 'Rs 10,989.99 Payout to PayPal',
      accountMask: '@shreeteen123',
      dateTime: today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 14, minutes: 30)),
      status: PayoutStatus.completed,
      subTotalAmount: 10989.99,
      receiptNo: 'RCP-2026-003',
      txnId: 'TXN-2026-B001',
      payoutTo: 'PayPal — @shreeteen123',
    ),
    PayoutHistoryEntry(
      id: 'pay-004',
      title: 'Rs 8,500 Payout to Laxmi Bank',
      accountMask: '****7787',
      dateTime: today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 9, minutes: 10)),
      status: PayoutStatus.failed,
      subTotalAmount: 8500,
      receiptNo: 'RCP-2026-004',
      txnId: 'TXN-2026-B002',
      payoutTo: 'Laxmi Bank a/c — ****7787',
    ),
    // 3 days ago — 2 entries
    PayoutHistoryEntry(
      id: 'pay-005',
      title: 'Rs 17,000 Payout to Esewa Wallet',
      accountMask: '****8522',
      dateTime: today
          .subtract(const Duration(days: 3))
          .add(const Duration(hours: 11, minutes: 0)),
      status: PayoutStatus.completed,
      subTotalAmount: 17000,
      receiptNo: 'RCP-2026-005',
      txnId: 'TXN-2026-C001',
      payoutTo: 'eSewa — 9840098522',
    ),
    PayoutHistoryEntry(
      id: 'pay-006',
      title: 'Rs 5,000 Payout to NIMB Bank',
      accountMask: '****8909',
      dateTime: today
          .subtract(const Duration(days: 3))
          .add(const Duration(hours: 7, minutes: 50)),
      status: PayoutStatus.pending,
      subTotalAmount: 5000,
      receiptNo: 'RCP-2026-006',
      txnId: 'TXN-2026-C002',
      payoutTo: 'NIMB Bank a/c — ****8909',
    ),
    // 11 days ago — 2 entries
    PayoutHistoryEntry(
      id: 'pay-007',
      title: 'Rs 12,500 Payout to PayPal',
      accountMask: '@shreeteen123',
      dateTime: today
          .subtract(const Duration(days: 11))
          .add(const Duration(hours: 16, minutes: 20)),
      status: PayoutStatus.completed,
      subTotalAmount: 12500,
      receiptNo: 'RCP-2026-007',
      txnId: 'TXN-2026-D001',
      payoutTo: 'PayPal — @shreeteen123',
    ),
    PayoutHistoryEntry(
      id: 'pay-008',
      title: 'Rs 9,200 Payout to Laxmi Bank',
      accountMask: '****7787',
      dateTime: today
          .subtract(const Duration(days: 11))
          .add(const Duration(hours: 10, minutes: 5)),
      status: PayoutStatus.failed,
      subTotalAmount: 9200,
      receiptNo: 'RCP-2026-008',
      txnId: 'TXN-2026-D002',
      payoutTo: 'Laxmi Bank a/c — ****7787',
    ),
  ];
}

// ── Grouping helpers ──────────────────────────────────────────────────────────

String _groupLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dayDate = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(dayDate).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEE d MMM yyyy').format(dt);
}

String _groupKey(DateTime dt) {
  return DateFormat('yyyy-MM-dd').format(dt);
}

// ── AllPayoutHistoryScreen ────────────────────────────────────────────────────

class AllPayoutHistoryScreen extends StatefulWidget {
  const AllPayoutHistoryScreen({super.key});

  @override
  State<AllPayoutHistoryScreen> createState() => _AllPayoutHistoryScreenState();
}

class _AllPayoutHistoryScreenState extends State<AllPayoutHistoryScreen> {
  final List<PayoutHistoryEntry> _allEntries = _buildMockEntries();
  PayoutStatus? _activeStatusFilter;

  List<PayoutHistoryEntry> get _filtered {
    if (_activeStatusFilter == null) return _allEntries;
    return _allEntries
        .where((e) => e.status == _activeStatusFilter)
        .toList();
  }

  Map<String, List<PayoutHistoryEntry>> get _grouped {
    final map = <String, List<PayoutHistoryEntry>>{};
    for (final entry in _filtered) {
      final key = _groupKey(entry.dateTime);
      map.putIfAbsent(key, () => []).add(entry);
    }
    // Sort keys descending (most recent first)
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  void _openFilterSheet() {
    showModalBottomSheet<PayoutStatus?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (ctx) => _FilterBottomSheet(
        initialStatus: _activeStatusFilter,
        onApply: (status) {
          setState(() => _activeStatusFilter = status);
          Navigator.of(ctx).pop();
        },
        onClear: () {
          setState(() => _activeStatusFilter = null);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('All Payout History',
            style: DesignTokens.sectionInnerTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DesignTokens.textWhite, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined,
                color: DesignTokens.textWhite),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s8,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Filter',
                  leadingIcon: Icons.filter_list_rounded,
                  isActive: _activeStatusFilter != null,
                  onTap: _openFilterSheet,
                ),
                const SizedBox(width: DesignTokens.s8),
                _FilterChip(
                  label: 'Status',
                  trailingIcon: Icons.keyboard_arrow_down_rounded,
                  isActive: _activeStatusFilter != null,
                  onTap: _openFilterSheet,
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Text(
                      'No payouts found.',
                      style: DesignTokens.mediumRegular
                          .copyWith(color: DesignTokens.textMuted),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.s16,
                      DesignTokens.s8,
                      DesignTokens.s16,
                      DesignTokens.s24,
                    ),
                    children: [
                      for (final key in grouped.keys) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: DesignTokens.s16,
                            bottom: DesignTokens.s8,
                          ),
                          child: Text(
                            _groupLabel(grouped[key]!.first.dateTime),
                            style: DesignTokens.smallRegular
                                .copyWith(color: DesignTokens.textMuted),
                          ),
                        ),
                        _DateGroupCard(
                          entries: grouped[key]!,
                          onTap: (entry) => context.push(
                            RouteNames.creatorPayoutInvoice,
                            extra: PayoutInvoiceArgs(entry: entry),
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

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s12, vertical: DesignTokens.s8),
        decoration: BoxDecoration(
          color: isActive
              ? DesignTokens.chipsSelectedFill
              : DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(
            color: isActive
                ? DesignTokens.chipsSelectedBorder
                : DesignTokens.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon,
                  size: 16,
                  color: isActive
                      ? DesignTokens.primaryGreen
                      : DesignTokens.textLight),
              const SizedBox(width: DesignTokens.s4),
            ],
            Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: isActive
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: DesignTokens.s4),
              Icon(trailingIcon,
                  size: 16,
                  color: isActive
                      ? DesignTokens.primaryGreen
                      : DesignTokens.textLight),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Date group card ───────────────────────────────────────────────────────────

class _DateGroupCard extends StatelessWidget {
  const _DateGroupCard({
    required this.entries,
    required this.onTap,
  });

  final List<PayoutHistoryEntry> entries;
  final void Function(PayoutHistoryEntry) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            _PayoutEntryRow(
              entry: entries[i],
              onTap: () => onTap(entries[i]),
            ),
            if (i < entries.length - 1)
              const Divider(
                  color: DesignTokens.borderDefault,
                  height: 1,
                  indent: DesignTokens.s16,
                  endIndent: DesignTokens.s16),
          ],
        ],
      ),
    );
  }
}

// ── Payout entry row ──────────────────────────────────────────────────────────

class _PayoutEntryRow extends StatelessWidget {
  const _PayoutEntryRow({required this.entry, required this.onTap});

  final PayoutHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm, MMM d yyyy').format(entry.dateTime);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/creatordash/universal-currency.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.textWhite),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '${entry.accountMask} · $time',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            _StatusBadge(status: entry.status),
          ],
        ),
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.initialStatus,
    required this.onApply,
    required this.onClear,
  });

  final PayoutStatus? initialStatus;
  final void Function(PayoutStatus?) onApply;
  final VoidCallback onClear;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  DateTime? _fromDate;
  DateTime? _toDate;
  PayoutStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _fromDate : _toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
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
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: DesignTokens.s16,
          right: DesignTokens.s16,
          top: DesignTokens.s20,
          bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Payout History',
                    style: DesignTokens.sectionInnerTitle),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: DesignTokens.textWhite, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s20),
            // Date range
            Text(
              'Date Range',
              style: DesignTokens.mediumSemibold
                  .copyWith(color: DesignTokens.textLight),
            ),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'From',
                    date: _fromDate,
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: _DateField(
                    label: 'To',
                    date: _toDate,
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s20),
            // Status
            Text(
              'Status',
              style: DesignTokens.mediumSemibold
                  .copyWith(color: DesignTokens.textLight),
            ),
            const SizedBox(height: DesignTokens.s8),
            for (final status in PayoutStatus.values)
              _StatusRadioTile(
                status: status,
                selected: _selectedStatus == status,
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
            const SizedBox(height: DesignTokens.s20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.textWhite,
                      side: const BorderSide(color: DesignTokens.borderDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            DesignTokens.buttonRadius),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: DesignTokens.s12),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(_selectedStatus),
                    style: DesignTokens.primaryButtonStyle(),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s12, vertical: DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.s8),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('MMM d, yyyy').format(date!)
                    : label,
                style: DesignTokens.smallRegular.copyWith(
                  color: date != null
                      ? DesignTokens.textWhite
                      : DesignTokens.textMuted,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: DesignTokens.iconLight),
          ],
        ),
      ),
    );
  }
}

class _StatusRadioTile extends StatelessWidget {
  const _StatusRadioTile({
    required this.status,
    required this.selected,
    required this.onChanged,
  });

  final PayoutStatus status;
  final bool selected;
  final void Function(PayoutStatus?) onChanged;

  String get _label => switch (status) {
        PayoutStatus.completed => 'Completed',
        PayoutStatus.pending => 'Pending',
        PayoutStatus.failed => 'Failed',
      };

  @override
  Widget build(BuildContext context) {
    return RadioListTile<PayoutStatus>(
      value: status,
      groupValue: selected ? status : null,
      onChanged: onChanged,
      activeColor: DesignTokens.primaryGreen,
      title: Text(
        _label,
        style: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.textWhite,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

// ── Re-export status badge for reuse in this file ─────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PayoutStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      PayoutStatus.completed => (
          const Color(0xFFB9F8CF),
          const Color(0xFF016630),
          'Completed',
        ),
      PayoutStatus.pending => (
          const Color(0xFFFFF3CD),
          const Color(0xFF856404),
          'Pending',
        ),
      PayoutStatus.failed => (
          const Color(0xFFFFE0E0),
          const Color(0xFFB91C1C),
          'Failed',
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.0,
          color: fg,
        ),
      ),
    );
  }
}
