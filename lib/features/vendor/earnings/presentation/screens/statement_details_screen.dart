import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/notifiers/vendor_earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/all_payout_history_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class StatementDetailsScreen extends ConsumerWidget {
  const StatementDetailsScreen({required this.payoutId, super.key});

  final String payoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(payoutInvoiceNotifierProvider(payoutId));

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
        title: Text('Statement Details', style: DesignTokens.oneLinerSemibold),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load this statement.',
          onRetry: () =>
              ref.read(payoutInvoiceNotifierProvider(payoutId).notifier).load(),
        ),
        loadSuccess: (invoice) => _InvoiceBody(invoice: invoice),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({required this.invoice});

  final VendorPayoutInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final kind = PayoutDestinationKind.fromValue(invoice.destinationKind);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipPath(
            clipper: _ScallopedBottomClipper(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s28,
              ),
              decoration: DesignTokens.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A3A1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          color: DesignTokens.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payout Receipt',
                              style: DesignTokens.smallRegular.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: DesignTokens.textWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat(
                                'MMMM d, yyyy',
                              ).format(invoice.requestedAt.toLocal()),
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  const Divider(color: DesignTokens.borderDefault, height: 1),
                  const SizedBox(height: DesignTokens.s12),

                  _DetailRow(
                    label: 'Receipt No.',
                    value: invoice.invoiceNumber,
                  ),
                  _DetailRow(
                    label: 'Date',
                    value: DateFormat(
                      'MMMM d, yyyy',
                    ).format(invoice.requestedAt.toLocal()),
                  ),
                  _DetailRow(label: 'Payout to', value: kind.label),
                  _DetailRow(
                    label: 'Account',
                    value: invoice.destinationRef,
                  ),
                  if (invoice.providerPayoutId != null)
                    _DetailRow(
                      label: 'TXN',
                      value: invoice.providerPayoutId!,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Status',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: invoice.state.bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: invoice.state.textColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            invoice.state.label,
                            style: DesignTokens.smallRegular.copyWith(
                              color: invoice.state.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: DesignTokens.s4),
                  const Divider(color: DesignTokens.borderDefault, height: 1),
                  const SizedBox(height: DesignTokens.s12),

                  _AmountRow(label: 'Gross Amount', value: invoice.grossAmount),
                  _AmountRow(
                    label: 'Fee',
                    value: invoice.feeAmount,
                    negative: true,
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  const Divider(color: DesignTokens.borderDefault, height: 1),
                  const SizedBox(height: DesignTokens.s12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Payout',
                        style: DesignTokens.mediumSemibold.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      MoneyText(
                        invoice.netAmount,
                        style: DesignTokens.mediumSemibold.copyWith(
                          fontSize: 18,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ],
                  ),
                  if (invoice.lines.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.s16),
                    Text(
                      'From this earnings window',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    ...invoice.lines.map(
                      (l) => _AmountRow(label: l.description, value: l.amount),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: DesignTokens.s16),
          Flexible(
            child: Text(
              value,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.negative = false,
  });
  final String label;
  final Money value;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              if (negative)
                Text(
                  '-',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              MoneyText(
                value,
                style: DesignTokens.smallRegular.copyWith(
                  color: negative
                      ? DesignTokens.colorError
                      : DesignTokens.textWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScallopedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 10.0;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - r);
    double x = size.width;
    while (x > 0) {
      path.arcToPoint(
        Offset(x - r * 2, size.height - r),
        radius: const Radius.circular(r),
        clockwise: true,
      );
      x -= r * 2;
    }
    path.lineTo(0, size.height - r);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
