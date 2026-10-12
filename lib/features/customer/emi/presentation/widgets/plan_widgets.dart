import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Whole rupees without decimals, anything else with two — the calculator's
/// rule, so a plan reads the same everywhere.
String planMoney(Money money) => formatMoney(
  money,
  decimalDigits: money.amount == money.amount.roundToDouble() ? 0 : 2,
);

/// A due date is a calendar date, not an instant: shown as it is, never
/// shifted by the device's time zone.
String planDate(DateTime date) =>
    DateFormat.yMMMd().format(DateTime(date.year, date.month, date.day));

/// An instant, in the device's own time.
String planInstant(DateTime instant) =>
    DateFormat.yMMMd().add_jm().format(instant.toLocal());

/// The bordered card every plan surface uses. A [Material] rather than a
/// decorated box, so list tiles and switches inside it show their ripple.
class PlanCard extends StatelessWidget {
  const PlanCard({required this.child, this.borderColor, super.key});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: DesignTokens.bgAppBody,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        side: BorderSide(color: borderColor ?? DesignTokens.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: child,
      ),
    ),
  );
}

/// A label and a figure on one line. The figure shrinks rather than
/// truncates: an ellipsised amount reads as a different number.
class PlanRow extends StatelessWidget {
  const PlanRow({
    required this.label,
    required this.value,
    this.emphasised = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: DesignTokens.smallRegular)),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: emphasised
                  ? DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.primaryGreen,
                    )
                  : DesignTokens.smallRegular,
            ),
          ),
        ),
      ],
    ),
  );
}

Color planStatusColour(AgreementStatus status) => switch (status) {
  AgreementStatus.active ||
  AgreementStatus.completed => DesignTokens.primaryGreen,
  AgreementStatus.approved ||
  AgreementStatus.pendingApproval => DesignTokens.colorWarning,
  AgreementStatus.defaulted ||
  AgreementStatus.declined => DesignTokens.colorError,
  AgreementStatus.cancelled ||
  AgreementStatus.expired ||
  AgreementStatus.reversed => DesignTokens.textMuted,
};

class PlanStatusChip extends StatelessWidget {
  const PlanStatusChip({required this.status, this.overdue = false, super.key});

  final AgreementStatus status;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final colour = overdue ? DesignTokens.colorError : planStatusColour(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: Text(
        overdue ? 'Payment overdue' : status.label,
        style: DesignTokens.tiny.copyWith(
          color: colour,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One instalment as a row: when, how much, and where it stands.
class PlanInstalmentTile extends StatelessWidget {
  const PlanInstalmentTile({required this.instalment, super.key});

  final PlanInstalment instalment;

  @override
  Widget build(BuildContext context) {
    final i = instalment;
    final (icon, colour, note) = switch (i.status) {
      InstalmentStatus.paid => (
        Icons.check_circle_rounded,
        DesignTokens.primaryGreen,
        i.paidAt == null ? 'Paid' : 'Paid ${planInstant(i.paidAt!)}',
      ),
      InstalmentStatus.waived => (
        Icons.check_circle_outline_rounded,
        DesignTokens.textMuted,
        i.wasCredited ? 'Covered by a refund' : 'Waived',
      ),
      InstalmentStatus.overdue => (
        Icons.error_rounded,
        DesignTokens.colorError,
        'Overdue',
      ),
      InstalmentStatus.partiallyPaid => (
        Icons.timelapse_rounded,
        DesignTokens.colorWarning,
        '${planMoney(i.paid)} paid',
      ),
      InstalmentStatus.scheduled => (
        Icons.radio_button_unchecked_rounded,
        DesignTokens.textMuted,
        i.dueDate == null ? 'Starts when the plan starts' : 'Due',
      ),
    };
    final due = i.dueDate;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colour),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  due == null
                      ? 'Payment ${i.number}'
                      : 'Payment ${i.number} · ${planDate(due)}',
                  style: DesignTokens.smallRegular,
                ),
                Text(
                  note,
                  style: DesignTokens.tiny.copyWith(color: colour),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                planMoney(switch (i.status) {
                  // What was actually paid — less than scheduled when a refund
                  // covered part of it.
                  InstalmentStatus.paid when i.paid.amount > 0 => i.paid,
                  InstalmentStatus.waived when i.wasCredited => i.credited!,
                  _ when i.status.isSettled => i.scheduled,
                  _ => i.outstanding,
                }),
                style: DesignTokens.smallRegular,
              ),
              if (i.lateFeeDue.amount > 0)
                Text(
                  'incl. ${planMoney(i.lateFeeDue)} late fee',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Opens the payment provider's page in the in-app browser. A provider so a
/// test can stand in for the browser and see which page was opened.
final Provider<Future<void> Function(Uri)> planPaymentLauncherProvider =
    Provider<Future<void> Function(Uri)>(
      (ref) => (uri) async {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } on Object {
          // No browser, or a malformed address: the payment exists and the
          // plan shows its real state, so carry on rather than fail.
        }
      },
    );

/// Pays something on a plan: the buyer picks a rail, the server names the
/// amount and starts the payment, and the provider's page completes it.
///
/// The provider's confirmation reaches the server, not this app, so a plan
/// is updated when the provider says so. Returns true when the hand-off was
/// made — not that the money has arrived.
Future<bool> payOnPlan(
  BuildContext context, {
  required CreditAgreement agreement,
  required PaymentPurpose purpose,
  required Money amount,
}) async {
  final paid = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    backgroundColor: DesignTokens.bgAppBodyLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) =>
        _PaySheet(agreement: agreement, purpose: purpose, amount: amount),
  );
  return paid ?? false;
}

class _PaySheet extends ConsumerStatefulWidget {
  const _PaySheet({
    required this.agreement,
    required this.purpose,
    required this.amount,
  });

  final CreditAgreement agreement;
  final PaymentPurpose purpose;
  final Money amount;

  @override
  ConsumerState<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<_PaySheet> {
  PlanPaymentRail _rail = PlanPaymentRail.eSewa;
  bool _starting = false;
  String? _error;

  /// One key per payment the buyer means to make. A retry after a timeout
  /// reuses it, so the server answers with the same payment instead of
  /// starting a second one; changing the rail is a different payment.
  String _key = const Uuid().v4();

  String get _title => switch (widget.purpose) {
    PaymentPurpose.activation => switch (widget.agreement.kind) {
      PlanKind.prepay => 'Pay the deposit',
      PlanKind.payLater => 'Pay the first payment',
      PlanKind.instalment => 'Pay the down payment',
    },
    PaymentPurpose.instalment => 'Pay what is due',
    PaymentPurpose.payoff => 'Pay off the plan',
  };

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    final result = await ref
        .read(creditRepositoryProvider)
        .startPayment(
          agreementId: widget.agreement.id,
          purpose: widget.purpose,
          rail: _rail,
          idempotencyKey: _key,
        );
    if (!mounted) return;
    await result.fold(
      (failure) async => setState(() {
        _starting = false;
        _error = creditFailureMessage(failure);
      }),
      (start) async {
        final url = start.redirectUrl;
        final uri = url == null ? null : Uri.tryParse(url);
        if (uri != null) await ref.read(planPaymentLauncherProvider)(uri);
        if (mounted) Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s20,
        DesignTokens.s16,
        DesignTokens.s20,
        DesignTokens.s20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.s4),
          Text(
            planMoney(widget.amount),
            key: const Key('plan-pay-amount'),
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          RadioGroup<PlanPaymentRail>(
            groupValue: _rail,
            onChanged: (rail) {
              if (rail == null || _starting) return;
              setState(() {
                _rail = rail;
                _key = const Uuid().v4();
              });
            },
            child: Column(
              children: [
                for (final rail in PlanPaymentRail.values)
                  RadioListTile<PlanPaymentRail>(
                    key: Key('plan-rail-${rail.name}'),
                    value: rail,
                    title: Text(rail.label, style: DesignTokens.smallRegular),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          Text(
            'Payment plans are paid online. Cash on delivery is not available '
            'for them.',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          if (_error != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              _error!,
              key: const Key('plan-pay-error'),
              style: DesignTokens.tiny.copyWith(color: DesignTokens.colorError),
            ),
          ],
          const SizedBox(height: DesignTokens.s16),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: FilledButton(
              key: const Key('plan-pay-confirm'),
              onPressed: _starting ? null : () => unawaited(_start()),
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.buttonPrimaryFill,
                foregroundColor: DesignTokens.buttonPrimaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                ),
              ),
              child: Text(
                _starting ? 'Starting payment…' : 'Pay with ${_rail.label}',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
