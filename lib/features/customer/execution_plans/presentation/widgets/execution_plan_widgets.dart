import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/widgets/execution_plan_copy.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The §5.9 boundary, stated above the steps on every plan.
///
/// It is not a disclaimer and it is not collapsible: a shopper who reads it
/// after the steps has already read the steps as a promise.
class ExecutionPlanBoundaryNotice extends StatelessWidget {
  const ExecutionPlanBoundaryNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('plan-boundary-notice'),
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.infoFillDark,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Semantics(
      container: true,
      label:
          '${ExecutionPlanCopy.boundaryTitle}. '
          '${ExecutionPlanCopy.boundaryBody}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.pan_tool_outlined,
                size: 18,
                color: DesignTokens.infoTextLight,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  ExecutionPlanCopy.boundaryTitle,
                  style: DesignTokens.mediumRegular.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.infoTextLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s6),
          const Text(
            ExecutionPlanCopy.boundaryBody,
            style: DesignTokens.smallDescription,
          ),
        ],
      ),
    ),
  );
}

/// What this app draws instead of a plan whose recorded work outran the
/// shopper's go-ahead.
///
/// Drawing the plan would tell them a price, a hold or a payment happened by
/// itself. It refuses, and says why.
class ExecutionPlanRefusalNotice extends StatelessWidget {
  const ExecutionPlanRefusalNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('plan-refusal-notice'),
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: BoxDecoration(
      color: DesignTokens.colorError.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Semantics(
      container: true,
      liveRegion: true,
      label:
          '${ExecutionPlanCopy.refusalTitle}. '
          '${ExecutionPlanCopy.refusalBody}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.gpp_bad_outlined,
                size: 20,
                color: DesignTokens.colorError,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  ExecutionPlanCopy.refusalTitle,
                  style: DesignTokens.mediumRegular.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.colorError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          const Text(
            ExecutionPlanCopy.refusalBody,
            style: DesignTokens.smallDescription,
          ),
        ],
      ),
    ),
  );
}

/// A refused action of the shopper's own, in words they can act on.
class ExecutionPlanFailureNotice extends StatelessWidget {
  const ExecutionPlanFailureNotice({
    required this.errorCode,
    super.key,
    this.onDismiss,
  });

  final String errorCode;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final copy = ExecutionPlanCopy.actionFailure(errorCode);
    return Container(
      key: const ValueKey('plan-action-failure-notice'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Semantics(
        liveRegion: true,
        label: '${copy.title}. ${copy.body}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: DesignTokens.colorError,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Text(
                    copy.title,
                    style: DesignTokens.mediumRegular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.colorError,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s6),
            Text(copy.body, style: DesignTokens.smallDescription),
            if (onDismiss != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDismiss,
                  child: const Text('Got it'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One compiled step.
///
/// Everything on this card is either the backend's own words or a fact the
/// backend holds. Nothing here is ever drawn as done, reserved or paid: the
/// strongest claim it can make is that StyleMint recorded evidence, with the
/// date it did.
class ExecutionStepCard extends StatelessWidget {
  const ExecutionStepCard({
    required this.step,
    required this.planApproved,
    super.key,
    this.onApprove,
    this.busy = false,
  });

  final ExecutionStep step;

  /// Whether the shopper has given the whole plan its go-ahead.
  final bool planApproved;

  /// Offered only for a step that carries its own approval gate and has not
  /// passed it. There is no other button on this card, and in particular no
  /// button that carries the step out.
  final VoidCallback? onApprove;

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final approvalNote = ExecutionPlanCopy.approvalNote(
      step,
      planApproved: planApproved,
    );
    final commitmentNote = ExecutionPlanCopy.commitmentNote(step.commitments);
    final cap = step.budgetCap;
    final evidenceAt = step.completedUtc;
    final approve = onApprove;

    return Container(
      key: ValueKey('plan-step-${step.taskKey}'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${step.sequence}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(step.purpose, style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          // Wrap, not Row: at 320dp and 1.3x a pill and a note beside it is
          // an overflow waiting to happen.
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              MallStatusPill(
                label: ExecutionPlanCopy.stepStatusLabel(step.status),
                tone: ExecutionPlanCopy.stepStatusTone(step.status),
                icon: ExecutionPlanCopy.stepStatusIcon(step.status),
                dense: true,
              ),
              if (step.needsOwnApproval)
                const MallStatusPill(
                  key: ValueKey('plan-step-needs-you'),
                  label: 'Needs you',
                  tone: MallStatusTone.caution,
                  dense: true,
                ),
            ],
          ),
          if (evidenceAt != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Evidence recorded ${ExecutionPlanCopy.dateTime(evidenceAt)}.',
              style: DesignTokens.smallDescription,
            ),
          ],
          if (commitmentNote.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Container(
              key: ValueKey('plan-step-commitment-${step.taskKey}'),
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.s8),
              decoration: BoxDecoration(
                color: DesignTokens.warningFillDark,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.front_hand_outlined,
                    size: 16,
                    color: DesignTokens.warning300,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Text(
                      commitmentNote,
                      style: DesignTokens.smallDescription,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (approvalNote != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(approvalNote, style: DesignTokens.smallDescription),
          ],
          if (cap != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Ceiling for this step: ${formatMoney(cap)}. '
              '${ExecutionPlanCopy.spendLimitMeaning}',
              style: DesignTokens.smallDescription,
            ),
          ],
          if (step.fallbackActivated) ...[
            const SizedBox(height: DesignTokens.s8),
            const Text(
              'A fallback was recorded against this step.',
              style: DesignTokens.smallDescription,
            ),
          ],
          if (approve != null) ...[
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: ValueKey('plan-step-approve-${step.taskKey}'),
                onPressed: busy ? null : approve,
                style: DesignTokens.outlinedButtonStyle(),
                child: const Text(ExecutionPlanCopy.approveStepLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
