import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi_plan.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The plans endpoints answered 404: not deployed yet (or, for one plan,
/// not this seller's). Screens say the feature is being set up rather than
/// showing an error.
bool vendorEmiPlansUnavailable(Object? error) =>
    error is EmiLoadException && error.failure.isNotFound;

/// "Next due" in words: the amount and the date, or why there is none.
String vendorNextDueText(VendorEmiPlan plan) {
  final next = plan.nextInstalment;
  if (plan.status == AgreementStatus.completed) return 'Paid off';
  if (next == null) return plan.status.isClosed ? '—' : 'Nothing due';
  final due = next.dueDate;
  final amount = planMoney(
    next.outstanding.amount > 0 ? next.outstanding : next.scheduled,
  );
  return due == null
      ? '$amount · starts when the plan starts'
      : '$amount on ${planDate(due)}';
}

/// Shown in place of the plans while the backend does not have them yet.
class VendorEmiPlansSettingUp extends StatelessWidget {
  const VendorEmiPlansSettingUp({super.key});

  static const Key viewKey = Key('vendor-emi-plans-setting-up');

  @override
  Widget build(BuildContext context) => Padding(
    key: viewKey,
    padding: const EdgeInsets.all(DesignTokens.s24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.construction_rounded,
          size: 40,
          color: DesignTokens.textMuted,
        ),
        const SizedBox(height: DesignTokens.s12),
        const Text(
          'EMI plan tracking is being set up',
          style: DesignTokens.mediumSemibold,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Soon you will see what each buyer has paid, what is left and '
          'when the next instalment is due. Check back shortly.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// A small red "Overdue" pill.
class VendorEmiOverdueBadge extends StatelessWidget {
  const VendorEmiOverdueBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s8,
      vertical: DesignTokens.s4,
    ),
    decoration: BoxDecoration(
      color: DesignTokens.colorError.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
    ),
    child: Text(
      'Overdue',
      style: DesignTokens.tiny.copyWith(
        color: DesignTokens.colorError,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// The colour an instalment's standing is drawn in.
Color vendorStandingColour(VendorInstalmentStanding s) => switch (s) {
  VendorInstalmentStanding.paid => DesignTokens.primaryGreen,
  VendorInstalmentStanding.overdue => DesignTokens.colorError,
  VendorInstalmentStanding.dueToday ||
  VendorInstalmentStanding.dueSoon => DesignTokens.colorWarning,
  VendorInstalmentStanding.upcoming ||
  VendorInstalmentStanding.notStarted => DesignTokens.textMuted,
};
