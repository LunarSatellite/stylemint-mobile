import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  final _amountController = TextEditingController();
  String? _selectedMethodId;
  bool _agreedToTerms = false;

  static const double _feePercent = 0.02;
  static const List<int> _quickAmounts = [500, 1000, 3000, 5000, 8000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _processingFee => _amount * _feePercent;
  double get _grandTotal => _amount - _processingFee;

  void _pickQuickAmount(int amount) {
    _amountController.text = amount.toString();
    ref.read(requestPayoutNotifierProvider.notifier).setAmount(amount.toDouble());
    setState(() {});
  }

  String _estimatedArrival() {
    final now = DateTime.now();
    final daysToFriday = (5 - now.weekday + 7) % 7;
    final start = now.add(Duration(days: daysToFriday == 0 ? 7 : daysToFriday));
    final end = start.add(const Duration(days: 2));
    return '${DateFormat('MMM d').format(start)}-${DateFormat('d, yyyy').format(end)}';
  }

  void _openPaymentMethodSheet(List<PayoutMethod> methods) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (_) => _PaymentMethodSheet(
        methods: methods,
        selectedId: _selectedMethodId,
        onSelected: (id) {
          setState(() => _selectedMethodId = id);
          ref.read(requestPayoutNotifierProvider.notifier).setSelectedMethod(id);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openConfirmSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (_) => _ConfirmPayoutSheet(
        onConfirm: () {
          Navigator.of(context).pop();
          ref.read(requestPayoutNotifierProvider.notifier).submit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final earningsState = ref.watch(earningsNotifierProvider);
    final payoutState = ref.watch(requestPayoutNotifierProvider);

    final summary = earningsState.maybeWhen(
      loadSuccess: (s, _, _a) => s,
      orElse: () => null,
    );
    final methods = earningsState.maybeWhen(
      loadSuccess: (_, _a, m) => m,
      orElse: () => const <PayoutMethod>[],
    );

    ref.listen<RequestPayoutState>(requestPayoutNotifierProvider, (_, next) {
      next.maybeWhen(
        success: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payout requested!')),
          );
          context.pop();
        },
        failure: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to request payout')),
          );
        },
        orElse: () {},
      );
    });

    final isSubmitting = payoutState.maybeWhen(submitting: () => true, orElse: () => false);
    final canSubmit = _selectedMethodId != null &&
        _amount > 0 &&
        _agreedToTerms &&
        !isSubmitting;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Request Payout', style: DesignTokens.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance card ────────────────────────────────────────────────
            if (summary != null) ...[
              _BalanceCard(summary: summary),
              const SizedBox(height: DesignTokens.s12),
            ],

            // ── Amount input ────────────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Rs ',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.textWhite,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: DesignTokens.smallRegular.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: DesignTokens.textMuted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            final amt = double.tryParse(val) ?? 0;
                            ref
                                .read(requestPayoutNotifierProvider.notifier)
                                .setAmount(amt);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  Row(
                    children: _quickAmounts
                        .map(
                          (amt) => Expanded(
                            child: GestureDetector(
                              onTap: () => _pickQuickAmount(amt),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: amt == _quickAmounts.last
                                      ? 0
                                      : DesignTokens.s8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DesignTokens.s8,
                                  vertical: DesignTokens.s8,
                                ),
                                decoration: BoxDecoration(
                                  color: DesignTokens.bgAppBodyLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$amt',
                                  style: DesignTokens.smallRegular.copyWith(
                                    color: DesignTokens.textWhite,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  const Divider(color: DesignTokens.borderDefault, height: 1),
                  const SizedBox(height: DesignTokens.s8),
                  Text(
                    'Min Rs 10,000 and Max Rs 70,000',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s12),

            // ── Payment method ──────────────────────────────────────────────
            GestureDetector(
              onTap: () => _openPaymentMethodSheet(methods),
              child: _SectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _selectedMethodId == null || methods.isEmpty
                          ? Text(
                              'Payment Method',
                              style: DesignTokens.oneLinerRegular.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                            )
                          : Text(
                              methods
                                  .firstWhere(
                                    (m) => m.id == _selectedMethodId,
                                    orElse: () => methods.first,
                                  )
                                  .label,
                              style: DesignTokens.oneLinerRegular.copyWith(
                                color: DesignTokens.textWhite,
                              ),
                            ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: DesignTokens.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),

            // ── Payment summary ─────────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _SummaryRow(
                    icon: Icons.wallet_outlined,
                    iconWidget: Image.asset(
                      'assets/images/creatordash/universal-currency.png',
                      width: 16,
                      height: 16,
                    ),
                    label: 'Withdrawal Amount',
                    value: 'Rs ${_amount.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  _SummaryRow(
                    icon: Icons.percent_rounded,
                    label: 'Processing Fee',
                    value: '-Rs ${_processingFee.toStringAsFixed(2)}',
                    valueColor: const Color(0xFFFF4D4F),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  _DashedDivider(),
                  const SizedBox(height: DesignTokens.s12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      Text(
                        'Rs ${_grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.s12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2F45),
                      borderRadius: BorderRadius.circular(DesignTokens.s8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Color(0xFF4DA6FF),
                        ),
                        const SizedBox(width: DesignTokens.s8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Arrival: ${_estimatedArrival()}',
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: DesignTokens.textWhite,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your payout will be deposited to your selected payment method by the above date',
                                style: DesignTokens.smallRegular.copyWith(
                                  color: DesignTokens.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s16),

            // ── Agreement checkbox ──────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (val) =>
                        setState(() => _agreedToTerms = val ?? false),
                    activeColor: DesignTokens.primaryGreen,
                    side: const BorderSide(color: DesignTokens.borderDefault),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'I understand the 2% processing fee and payout cannot be canceled once requested',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s24),

            // ── Submit ──────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: canSubmit ? _openConfirmSheet : null,
                style: DesignTokens.primaryButtonStyle(),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Request Payout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          _BalanceRow(
            iconBg: DesignTokens.primaryGreenDark,
            icon: Icons.savings_outlined,
            iconColor: DesignTokens.primaryGreen,
            iconWidget: Image.asset(
              'assets/images/creatordash/material-symbols_money-bag-rounded.png',
              width: 24,
              height: 24,
            ),
            label: 'Available for Withdrawal',
            amount: formatMoney(summary.availableBalance),
          ),
          const SizedBox(height: DesignTokens.s16),
          _BalanceRow(
            iconBg: DesignTokens.warningFillDark,
            icon: Icons.hourglass_bottom_rounded,
            iconColor: DesignTokens.secondaryYellow,
            iconWidget: Image.asset(
              'assets/images/creatordash/material-symbols_hourglass-top-rounded.png',
              width: 24,
              height: 24,
            ),
            label: 'Pending (Processing from recent sales)',
            amount: formatMoney(summary.pendingBalance),
            suffix: ' (releases in 3 days)',
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
    this.iconWidget,
    this.suffix,
  });

  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final Widget? iconWidget;
  final String label;
  final String amount;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(DesignTokens.s8),
          ),
          alignment: Alignment.center,
          child: iconWidget ?? Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: amount,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    if (suffix != null)
                      TextSpan(
                        text: suffix,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconWidget,
    this.valueColor,
  });

  final IconData icon;
  final Widget? iconWidget;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        iconWidget ?? Icon(icon, size: 16, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? DesignTokens.textWhite,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: dashSpace),
              color: DesignTokens.borderDefault,
            ),
          ),
        );
      },
    );
  }
}

// ── Payment method bottom sheet ───────────────────────────────────────────────

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({
    required this.methods,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PayoutMethod> methods;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  /// Splits "NIC Asia Bank — ****4321" into ("NIC Asia Bank", "••••••••4321").
  (String, String) _parseLabel(PayoutMethod method) {
    final parts = method.label.split(' — ');
    final name = parts.first;
    final raw = parts.length > 1 ? parts[1] : '';
    final identifier = raw.replaceAllMapped(
      RegExp(r'^\*+'),
      (m) => '•' * m.group(0)!.length,
    );
    return (name, identifier);
  }

  Widget _iconWidget(PayoutMethodType type) {
    switch (type) {
      case PayoutMethodType.bankTransfer:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D3A),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.account_balance_rounded,
            color: Colors.white,
            size: 22,
          ),
        );
      case PayoutMethodType.paypal:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF003087),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Text(
            'P',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      case PayoutMethodType.esewa:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1DC472),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Text(
            'e',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s20,
            DesignTokens.s16,
            DesignTokens.s16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select payment method',
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
        for (final method in methods)
          _buildMethodTile(method),
        const SizedBox(height: DesignTokens.s16),
      ],
    );
  }

  Widget _buildMethodTile(PayoutMethod method) {
    final isSelected = method.id == selectedId;
    final (name, identifier) = _parseLabel(method);

    return GestureDetector(
      onTap: () => onSelected(method.id),
      child: Container(
        color: isSelected
            ? const Color(0xFF0D2A1A)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        child: Row(
          children: [
            _iconWidget(method.type),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  if (identifier.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      identifier,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: DesignTokens.primaryGreen,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Confirm payout bottom sheet ───────────────────────────────────────────────

class _ConfirmPayoutSheet extends StatelessWidget {
  const _ConfirmPayoutSheet({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignTokens.s8),
          const Text(
            'Confirm Payout Request',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Center(
            child: Image.asset(
              'assets/images/vendordashboard/infoicon.png',
              width: 56,
              height: 56,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Container(
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2F45),
              borderRadius: BorderRadius.circular(DesignTokens.s8),
              border: Border.all(
                color: const Color(0xFF2D5A8E),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep in mind the following:',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                _BulletPoint(text: 'Weekly Payout Process is live'),
                const SizedBox(height: DesignTokens.s4),
                _BulletPoint(
                  text: 'Earnings from last 7 days pending',
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: DesignTokens.primaryButtonStyle(),
              child: const Text('Confirm'),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.bgAppBodyLight,
                foregroundColor: DesignTokens.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
                elevation: 0,
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            color: DesignTokens.textLight,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
