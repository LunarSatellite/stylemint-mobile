import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/widgets/execution_plan_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/widgets/execution_plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// **Shopping plans** — the shopper's half of `v1/commerce-execution-plans`.
///
/// They say what they are trying to buy; StyleMint compiles that into steps
/// and writes them down. That is the whole of it. Every step that would touch
/// a price, stock or money is theirs to carry out in checkout, and this
/// screen has no button that would do it for them — see §5.9 in
/// [ExecutionPlanCopy].
class ShoppingPlansScreen extends ConsumerStatefulWidget {
  const ShoppingPlansScreen({super.key});

  @override
  ConsumerState<ShoppingPlansScreen> createState() =>
      _ShoppingPlansScreenState();
}

class _ShoppingPlansScreenState extends ConsumerState<ShoppingPlansScreen> {
  final TextEditingController _intent = TextEditingController();
  final TextEditingController _limit = TextEditingController();
  int _maximumItems = kExecutionPlanDefaultItems;

  @override
  void dispose() {
    _intent.dispose();
    _limit.dispose();
    super.dispose();
  }

  /// The typed limit, or null when the field is empty or unreadable. An
  /// unreadable limit is never silently turned into zero — zero would mean
  /// "may spend nothing", which the backend rejects and the shopper did not
  /// say.
  double? get _spendLimit {
    final raw = _limit.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    return value != null && value > 0 ? value : null;
  }

  Future<void> _compile() async {
    final intent = _intent.text.trim();
    if (intent.isEmpty) return;
    FocusScope.of(context).unfocus();
    final planId = await ref
        .read(executionPlansNotifierProvider.notifier)
        .compile(
          intent: intent,
          maximumSpend: _spendLimit,
          maximumItems: _maximumItems,
        );
    if (!mounted || planId == null) return;
    _intent.clear();
    _limit.clear();
    unawaited(
      context.push(
        RouteNames.settingsShoppingPlan.replaceFirst(':planId', planId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(executionPlansNotifierProvider);
    final notifier = ref.read(executionPlansNotifierProvider.notifier);
    final open = state.open;
    final closed = state.closed;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text(ExecutionPlanCopy.surfaceTitle),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s8,
            DesignTokens.s16,
            DesignTokens.s32,
          ),
          children: [
            const Text(
              ExecutionPlanCopy.surfaceIntro,
              style: DesignTokens.mediumRegular,
            ),
            const SizedBox(height: DesignTokens.s16),
            const ExecutionPlanBoundaryNotice(),
            const SizedBox(height: DesignTokens.s16),
            _ComposeCard(
              intent: _intent,
              limit: _limit,
              maximumItems: _maximumItems,
              compiling: state.compiling,
              onItemsChanged: (value) => setState(() => _maximumItems = value),
              onSubmit: () => unawaited(_compile()),
            ),
            if (state.failure != null) ...[
              const SizedBox(height: DesignTokens.s16),
              ExecutionPlanFailureNotice(
                errorCode: state.failure!,
                onDismiss: notifier.dismissFailure,
              ),
            ],
            if (state.loadFailed) ...[
              const SizedBox(height: DesignTokens.s16),
              const Text(
                ExecutionPlanCopy.loadFailed,
                key: ValueKey('plans-load-failed'),
                style: DesignTokens.smallDescription,
              ),
            ],
            if (state.loaded && state.plans.isEmpty) ...[
              const SizedBox(height: DesignTokens.s24),
              const MallEmptyState(
                key: ValueKey('plans-empty'),
                title: ExecutionPlanCopy.emptyTitle,
                body: ExecutionPlanCopy.emptyBody,
                icon: Icons.checklist_rtl_outlined,
              ),
            ],
            if (open.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s24),
              const _SectionHeader(title: 'Open plans'),
              for (final plan in open) ...[
                const SizedBox(height: DesignTokens.s12),
                _PlanCard(plan: plan),
              ],
            ],
            if (closed.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s24),
              const _SectionHeader(title: 'Finished and cancelled'),
              for (final plan in closed) ...[
                const SizedBox(height: DesignTokens.s12),
                _PlanCard(plan: plan),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({
    required this.intent,
    required this.limit,
    required this.maximumItems,
    required this.compiling,
    required this.onItemsChanged,
    required this.onSubmit,
  });

  final TextEditingController intent;
  final TextEditingController limit;
  final int maximumItems;
  final bool compiling;
  final ValueChanged<int> onItemsChanged;
  final VoidCallback onSubmit;

  static const List<int> _itemChoices = <int>[3, 5, 10, 20];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: DesignTokens.cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ExecutionPlanCopy.composeTitle,
          style: DesignTokens.sectionInnerTitle,
        ),
        const SizedBox(height: DesignTokens.s12),
        TextField(
          key: const ValueKey('plan-intent-field'),
          controller: intent,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: ExecutionPlanCopy.composeHint,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        TextField(
          key: const ValueKey('plan-limit-field'),
          controller: limit,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
          ],
          decoration: const InputDecoration(
            labelText: ExecutionPlanCopy.composeLimitLabel,
            helperText: ExecutionPlanCopy.composeLimitHelp,
            helperMaxLines: 3,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        // Column rather than Row: a label and a dropdown side by side is the
        // first thing to overflow at 320dp and 1.3x.
        const Text(
          ExecutionPlanCopy.composeItemsLabel,
          style: DesignTokens.smallDescription,
        ),
        const SizedBox(height: DesignTokens.s4),
        DropdownButton<int>(
          key: const ValueKey('plan-items-field'),
          value: maximumItems,
          isExpanded: true,
          items: [
            for (final choice in _itemChoices)
              DropdownMenuItem<int>(
                value: choice,
                child: Text('$choice items'),
              ),
          ],
          onChanged: (value) => value == null ? null : onItemsChanged(value),
        ),
        const SizedBox(height: DesignTokens.s16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const ValueKey('plan-compile-button'),
            onPressed: compiling ? null : onSubmit,
            style: DesignTokens.primaryButtonStyle(),
            child: Text(
              compiling
                  ? ExecutionPlanCopy.composeWorking
                  : ExecutionPlanCopy.composeSubmit,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final CommerceExecutionPlan plan;

  @override
  Widget build(BuildContext context) {
    final needsYou = plan.stepsNeedingYou.length;
    return InkWell(
      key: ValueKey('plan-card-${plan.id}'),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => unawaited(
        context.push(
          RouteNames.settingsShoppingPlan.replaceFirst(':planId', plan.id),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.intent, style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                MallStatusPill(
                  label: ExecutionPlanCopy.planStatusLabel(
                    plan.status,
                    rawStatus: plan.rawStatus,
                  ),
                  tone: ExecutionPlanCopy.planStatusTone(plan.status),
                  icon: ExecutionPlanCopy.planStatusIcon(plan.status),
                  dense: true,
                ),
                if (needsYou > 0)
                  MallStatusPill(
                    label: needsYou == 1
                        ? '1 step needs you'
                        : '$needsYou steps need you',
                    tone: MallStatusTone.caution,
                    dense: true,
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Written down ${ExecutionPlanCopy.date(plan.createdUtc)} · '
              '${plan.steps.length} '
              '${plan.steps.length == 1 ? 'step' : 'steps'}',
              style: DesignTokens.smallDescription,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(title, style: DesignTokens.sectionInnerTitle),
  );
}
