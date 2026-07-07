import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/statement_details_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AllPayoutHistoryScreen extends StatelessWidget {
  const AllPayoutHistoryScreen({super.key});

  static const _groups = [
    _PayoutGroup(
      date: 'Jan 2024',
      items: [
        _HistoryEntry(
          id: '1',
          label: 'Rs 3,400 Payout to Bank A/C',
          bankInfo: 'Bank of Kathmandu A/C ******8799',
          amount: 'Rs 3,400.00',
          date: 'Jan 23, 2024',
          status: _Status.completed,
        ),
        _HistoryEntry(
          id: '2',
          label: 'Rs 12,000 Payout to Bank A/C',
          bankInfo: 'Bank of Kathmandu A/C ******8799',
          amount: 'Rs 12,000.00',
          date: 'Jan 10, 2024',
          status: _Status.completed,
        ),
      ],
    ),
    _PayoutGroup(
      date: 'Dec 2024',
      items: [
        _HistoryEntry(
          id: '3',
          label: 'Rs 7,000 Payout to Bank A/C',
          bankInfo: 'Bank of Kathmandu A/C ******8799',
          amount: 'Rs 7,000.00',
          date: 'Dec 20, 2024',
          status: _Status.completed,
        ),
        _HistoryEntry(
          id: '4',
          label: 'Rs 18,500 Payout to eSewa',
          bankInfo: 'eSewa Account ******4512',
          amount: 'Rs 18,500.00',
          date: 'Dec 15, 2024',
          status: _Status.completed,
        ),
        _HistoryEntry(
          id: '5',
          label: 'Rs 5,200 Payout to Bank A/C',
          bankInfo: 'Bank of Kathmandu A/C ******8799',
          amount: 'Rs 5,200.00',
          date: 'Dec 3, 2024',
          status: _Status.pending,
        ),
      ],
    ),
    _PayoutGroup(
      date: 'Nov 2024',
      items: [
        _HistoryEntry(
          id: '6',
          label: 'Rs 9,800 Payout to Bank A/C',
          bankInfo: 'Bank of Kathmandu A/C ******8799',
          amount: 'Rs 9,800.00',
          date: 'Nov 28, 2024',
          status: _Status.completed,
        ),
        _HistoryEntry(
          id: '7',
          label: 'Rs 4,600 Payout to eSewa',
          bankInfo: 'eSewa Account ******4512',
          amount: 'Rs 4,600.00',
          date: 'Nov 14, 2024',
          status: _Status.completed,
        ),
        _HistoryEntry(
          id: '8',
          label: 'Rs 22,000 Payout to Bank A/C',
          bankInfo: 'Bank of Kathmandu A/C ******8799',
          amount: 'Rs 22,000.00',
          date: 'Nov 1, 2024',
          status: _Status.failed,
        ),
      ],
    ),
  ];

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
        title: Text('All Payout History', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.download_outlined,
              color: DesignTokens.textWhite,
              size: 22,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        children: _groups
            .expand(
              (group) => [
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
                    children: group.items.asMap().entries.map((e) {
                      final item = e.value;
                      return Column(
                        children: [
                          if (e.key > 0)
                            const Divider(
                              color: DesignTokens.borderDefault,
                              height: 1,
                            ),
                          _HistoryTile(
                            entry: item,
                            onTap: () => context.push(
                              RouteNames.vendorStatementDetails,
                              extra: VendorPayoutItem(
                                id: item.id,
                                title: item.label,
                                subtitle: item.bankInfo,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: DesignTokens.s12),
              ],
            )
            .toList(),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.onTap});
  final _HistoryEntry entry;
  final VoidCallback onTap;

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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0D2137),
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: Color(0xFF4DA6FF),
                size: 18,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.bankInfo,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.amount,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: entry.status.bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.status.label,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: entry.status.textColor,
                    ),
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

enum _Status {
  completed,
  pending,
  failed;

  String get label {
    switch (this) {
      case completed:
        return 'Completed';
      case pending:
        return 'Pending';
      case failed:
        return 'Failed';
    }
  }

  Color get textColor {
    switch (this) {
      case completed:
        return DesignTokens.primaryGreen;
      case pending:
        return const Color(0xFFFFB800);
      case failed:
        return DesignTokens.colorError;
    }
  }

  Color get bgColor {
    switch (this) {
      case completed:
        return const Color(0xFF0D2A0D);
      case pending:
        return const Color(0xFF2A2000);
      case failed:
        return const Color(0xFF2A0A0A);
    }
  }
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.id,
    required this.label,
    required this.bankInfo,
    required this.amount,
    required this.date,
    required this.status,
  });
  final String id;
  final String label;
  final String bankInfo;
  final String amount;
  final String date;
  final _Status status;
}

class _PayoutGroup {
  const _PayoutGroup({required this.date, required this.items});
  final String date;
  final List<_HistoryEntry> items;
}
