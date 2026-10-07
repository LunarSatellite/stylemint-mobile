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
    final cached = state.byId(planId);

    // The cached list is the usual source. Once it has been read and does
    // not hold this plan — most often because that read failed — ask for
    // the plan by id before saying anything about it.
    final direct = cached == null && state.loaded
        ? ref.watch(executionPlanByIdProvider(planId))
        : null;
    // `hasValue` rather than `asData`: it keeps the plan on screen while a
    // re-read of it is in flight instead of flashing the loader.
    final plan =
        cached ??
        (direct != null && direct.hasValue && !direct.hasError
            ? direct.value
            : null);

    Future<void> reload() async {
      ref.invalidate(executionPlanByIdProvider(planId));
      await notifier.refresh();
    }

    final Widget body;
    if (plan != null) {
      body = _PlanBody(
        plan: plan,
        busy: state.busyPlanId == plan.id,
        failure: state.failure,
        onDismissFailure: notifier.dismissFailure,
      );
    } else if (direct == null || direct.isLoading) {
      body = const _Missing(state: _MissingState.loading);
    } else if (direct.hasError) {
      body = _Missing(
        state: _MissingState.unreadable,
        onRetry: () => unawaited(reload()),
      );
    } else {
      body = const _Missing(state: _MissingState.notOnAccount);
    }

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text(ExecutionPlanCopy.surfaceTitle),
      ),
      body: RefreshIndicator(onRefresh: reload, child: body),
    );
  }
}

enum _MissingState { loading, unreadable, notOnAccount }

/// Everything the screen can show when it has no plan to draw — kept apart
/// so "still reading", "could not read" and "not yours" never blur together.
class _Missing extends StatelessWidget {
  const _Missing({required this.state, this.onRetry});

  final _MissingState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(DesignTokens.s24),
    children: [
      switch (state) {
        _MissingState.loading => const SizedBox(
          height: 160,
          child: SmPageLoader(),
        ),
        _MissingState.unreadable => MallErrorState(
          key: const ValueKey('plan-unreadable'),
          title: "Couldn't read this plan",
          body: 'Check your connection and try again.',
          onRetry: onRetry,
        ),
        _MissingState.notOnAccount => const MallEmptyState(
          key: ValueKey('plan-missing'),
          title: 'This plan is not on your account',
          body: 'Pull down to read your plans again.',
          icon: Icons.search_off_rounded,
        ),
      },
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
    if (context.mounted) _rereadDirect(ref);
  }

  /// A plan drawn from the by-id fallback is not refreshed by the list
  /// re-read a change triggers, so it is re-read on its own. When the plan
  /// came from the list this provider is not being watched and this is a
  /// no-op.
  void _rereadDirect(WidgetRef ref) =>
      ref.invalidate(executionPlanByIdProvider(plan.id));

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
    if (context.mounted) _rereadDirect(ref);
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
    if (context.mounted) _rereadDirect(ref);
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
                onPressed: busy ? null : () => unawaited(_cancel(context, ref)),
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
