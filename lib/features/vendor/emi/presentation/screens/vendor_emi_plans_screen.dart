import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/vendor_emi_plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The seller's EMI plans once approved: who is paying (display name only),
/// for what, on which order, and how far along — collected, remaining, next
/// due, overdue. Filtered on the device: the server sends every plan.
class VendorEmiPlansScreen extends ConsumerStatefulWidget {
  const VendorEmiPlansScreen({
    this.initialFilter = VendorEmiPlanFilter.active,
    super.key,
  });

  final VendorEmiPlanFilter initialFilter;

  @override
  ConsumerState<VendorEmiPlansScreen> createState() =>
      _VendorEmiPlansScreenState();
}

class _VendorEmiPlansScreenState extends ConsumerState<VendorEmiPlansScreen> {
  late VendorEmiPlanFilter _filter = widget.initialFilter;

  static String _emptyMessage(VendorEmiPlanFilter f) => switch (f) {
    VendorEmiPlanFilter.active => 'No EMI plans are running right now.',
    VendorEmiPlanFilter.overdue => 'No buyer is behind on a payment.',
    VendorEmiPlanFilter.dueSoon => 'Nothing falls due in the next 3 days.',
    VendorEmiPlanFilter.completed => 'No EMI plan has been paid off yet.',
    VendorEmiPlanFilter.all => 'No EMI plans yet.',
  };

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(vendorEmiPlansProvider);
    final today = ref.watch(vendorEmiTodayProvider);
    final unavailable = vendorEmiPlansUnavailable(plans.error);
    final loaded = plans.asData?.value;
    String chipLabel(VendorEmiPlanFilter f) {
      if (loaded == null) return f.label;
      final count = loaded.where((p) => f.matches(p, today)).length;
      return '${f.label} ($count)';
    }

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('EMI plans'),
      ),
      body: SafeArea(
        child: unavailable
            ? ListView(children: const [VendorEmiPlansSettingUp()])
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.s16,
                      DesignTokens.s8,
                      DesignTokens.s16,
                      0,
                    ),
                    child: Wrap(
                      spacing: DesignTokens.s8,
                      runSpacing: DesignTokens.s8,
                      children: [
                        for (final f in VendorEmiPlanFilter.values)
                          ChoiceChip(
                            key: Key('vendor-emi-plans-filter-${f.name}'),
                            label: Text(chipLabel(f)),
                            selected: _filter == f,
                            selectedColor: DesignTokens.chipsSelectedFill,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(vendorEmiPlansProvider);
                        await ref.read(vendorEmiPlansProvider.future);
                      },
                      child: plans.when(
                        loading: () => const SmPageLoader(),
                        error: (error, _) => ListView(
                          children: [
                            SmErrorView(
                              message: error is EmiLoadException
                                  ? creditFailureMessage(error.failure)
                                  : 'We could not load your EMI plans.',
                              onRetry: () =>
                                  ref.invalidate(vendorEmiPlansProvider),
                            ),
                          ],
                        ),
                        data: (all) {
                          final shown = [
                            for (final p in all)
                              if (_filter.matches(p, today)) p,
                          ];
                          if (shown.isEmpty) {
                            return ListView(
                              children: [
                                SmEmptyState(
                                  message: _emptyMessage(_filter),
                                  icon: Icons.event_repeat_rounded,
                                ),
                              ],
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.all(DesignTokens.s16),
                            itemCount: shown.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: DesignTokens.s12),
                            itemBuilder: (_, i) => VendorEmiPlanTile(
                              plan: shown[i],
                              today: today,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// One plan in the list.
class VendorEmiPlanTile extends StatelessWidget {
  const VendorEmiPlanTile({required this.plan, required this.today, super.key});

  final VendorEmiPlan plan;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final muted = DesignTokens.tiny.copyWith(color: DesignTokens.textMuted);
    final dueSoon = p.isDueSoon(today);
    return InkWell(
      key: Key('vendor-emi-plan-tile-${p.id}'),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => context.push(RouteNames.vendorEmiPlanDetailPath(p.id)),
      child: PlanCard(
        borderColor: p.isOverdue
            ? DesignTokens.colorError.withValues(alpha: 0.6)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.buyerDisplayName,
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                if (p.isOverdue)
                  const VendorEmiOverdueBadge()
                else
                  PlanStatusChip(status: p.status),
              ],
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              p.productName.isEmpty ? 'EMI plan' : p.productName,
              style: DesignTokens.smallRegular,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              p.orderNumber == null
                  ? 'Order not placed yet'
                  : 'Order ${p.orderNumber}',
              style: muted,
            ),
            const SizedBox(height: DesignTokens.s8),
            PlanRow(label: 'Financed', value: planMoney(p.financed)),
            PlanRow(label: 'Collected', value: planMoney(p.collected)),
            PlanRow(
              label: 'Remaining',
              value: planMoney(p.remaining),
              emphasised: true,
            ),
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s4),
              child: Text(
                'Next due: ${vendorNextDueText(p)}',
                key: Key('vendor-emi-plan-next-${p.id}'),
                style: DesignTokens.tiny.copyWith(
                  color: p.isOverdue
                      ? DesignTokens.colorError
                      : dueSoon
                      ? DesignTokens.colorWarning
                      : DesignTokens.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
