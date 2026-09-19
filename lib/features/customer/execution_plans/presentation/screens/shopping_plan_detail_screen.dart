import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/widgets/execution_plan_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/widgets/execution_plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One compiled plan and its steps.
///
/// ## The two buttons this screen has, and the ones it does not
///
/// It can record the shopper's go-ahead — for the plan, and for a step that
/// carries its own gate — and it can cancel. Those write a decision.
///
/// It has no button that carries a step out, because three of the four
/// compiled steps touch a price, stock or money, and §5.9 of the client
/// proposal puts all three on the human side of the line. If the backend
/// ever reports work recorded against a plan the shopper never approved,
/// this screen draws [ExecutionPlanRefusalNotice] instead of the steps.
class ShoppingPlanDetailScreen extends ConsumerWidget {
  const ShoppingPlanDetailScreen({required this.planId, super.key});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionPlansNotifierProvider);
    final notifier = ref.read(executionPlansNotifierProvider.notifier);
    final plan = state.byId(planId);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text(ExecutionPlanCopy.surfaceTitle),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: plan == null
            ? _Missing(loaded: state.loaded)
            : _PlanBody(
                plan: plan,
                busy: state.busyPlanId == plan.id,
                failure: state.failure,
                onDismissFailure: notifier.dismissFailure,
              ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.loaded});

  final bool loaded;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(DesignTokens.s24),
    children: [
      if (!loaded)
        const SizedBox(height: 160, child: SmPageLoader())
      else
        const MallEmptyState(
          key: ValueKey('plan-missing'),
          title: 'This plan is not on your account',
          body: 'Pull down to read your plans again.',
          icon: Icons.search_off_rounded,
        ),
    ],
  );
}

class _PlanBody extends ConsumerWidget {
  const _PlanBody({
    required this.plan,
    required this.busy,
    required this.failure,
    required this.onDismissFailure,
  });

  final CommerceExecutionPlan plan;
  final bool busy;
  final String? failure;
  final VoidCallback onDismissFailure;

  Future<void> _approvePlan(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: ExecutionPlanCopy.approvePlanLabel,
      body: ExecutionPlanCopy.approvePlanMeaning,
      action: 'Give the go-ahead',
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(executionPlansNotifierProvider.notifier)
        .approvePlan(plan.id);
  }

  Future<void> _approveStep(
    BuildContext context,
    WidgetRef ref,
    ExecutionStep step,
  ) async {
    final confirmed = await _confirm(
      context,
      title: ExecutionPlanCopy.approveStepLabel,
      body:
          '${step.purpose}\n\n'
          '${ExecutionPlanCopy.commitmentNote(step.commitments)}\n\n'
          '${ExecutionPlanCopy.approvePlanMeaning}',
      action: 'Give the go-ahead',
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(executionPlansNotifierProvider.notifier)
        .approveStep(plan.id, step.taskKey);
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: ExecutionPlanCopy.cancelPlanLabel,
      body: ExecutionPlanCopy.cancelPlanMeaning,
      action: 'Cancel the plan',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(executionPlansNotifierProvider.notifier).cancel(plan.id);
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
  }) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: Text(title, style: DesignTokens.sectionInnerTitle),
        content: SingleChildScrollView(
          child: Text(body.trim(), style: DesignTokens.smallDescription),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            key: const ValueKey('plan-confirm-action'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planApproved = plan.approvedUtc != null;
    final limit = plan.spendLimit;
    final deadline = plan.mustCompleteByUtc;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(plan.intent, style: DesignTokens.h3),
        ),
        const SizedBox(height: DesignTokens.s12),
        Align(
          alignment: Alignment.centerLeft,
          child: MallStatusPill(
            label: ExecutionPlanCopy.planStatusLabel(
              plan.status,
              rawStatus: plan.rawStatus,
            ),
            tone: ExecutionPlanCopy.planStatusTone(plan.status),
            icon: ExecutionPlanCopy.planStatusIcon(plan.status),
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        const ExecutionPlanBoundaryNotice(),

        if (failure != null) ...[
          const SizedBox(height: DesignTokens.s16),
          ExecutionPlanFailureNotice(
            errorCode: failure!,
            onDismiss: onDismissFailure,
          ),
        ],

        const SizedBox(height: DesignTokens.s16),
        Text(
          limit == null
              ? ExecutionPlanCopy.noSpendLimit
              : '${ExecutionPlanCopy.spendLimitLabel}: ${formatMoney(limit)}. '
                    '${ExecutionPlanCopy.spendLimitMeaning}',
          key: const ValueKey('plan-spend-limit'),
          style: DesignTokens.smallDescription,
        ),
        if (deadline != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            '${ExecutionPlanCopy.deadlineLabel} '
            '${ExecutionPlanCopy.date(deadline)}.',
            style: DesignTokens.smallDescription,
          ),
        ],
        if (planApproved) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            'You gave this plan the go-ahead on '
            '${ExecutionPlanCopy.dateTime(plan.approvedUtc!)}.',
            style: DesignTokens.smallDescription,
          ),
        ],

        // ── Steps, or the refusal that replaces them ──
        const SizedBox(height: DesignTokens.s24),
        if (plan.mustRefuseToRender)
          const ExecutionPlanRefusalNotice()
        else ...[
          Semantics(
            header: true,
            child: const Text(
              ExecutionPlanCopy.stepsTitle,
              style: DesignTokens.sectionInnerTitle,
            ),
          ),
          if (plan.steps.isEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            const Text(
              ExecutionPlanCopy.noSteps,
              key: ValueKey('plan-no-steps'),
              style: DesignTokens.smallDescription,
            ),
          ],
          for (final step in plan.steps) ...[
            const SizedBox(height: DesignTokens.s12),
            ExecutionStepCard(
              step: step,
              planApproved: planApproved,
              busy: busy,
              onApprove: plan.isOpen && step.needsOwnApproval && planApproved
                  ? () => unawaited(_approveStep(context, ref, step))
                  : null,
            ),
          ],

          if (plan.awaitsApproval) ...[
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('plan-approve-button'),
                onPressed: busy
                    ? null
                    : () => unawaited(_approvePlan(context, ref)),
                style: DesignTokens.primaryButtonStyle(),
                child: const Text(ExecutionPlanCopy.approvePlanLabel),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            const Text(
              ExecutionPlanCopy.approvePlanMeaning,
              style: DesignTokens.smallDescription,
            ),
          ],
          if (plan.isOpen) ...[
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('plan-cancel-button'),
                onPressed: busy
                    ? null
                    : () => unawaited(_cancel(context, ref)),
                style: DesignTokens.outlinedButtonStyle(),
                child: const Text(ExecutionPlanCopy.cancelPlanLabel),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
