import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Payment plans on the vendor's products: the requests waiting for their
/// decision first, then the rest. A vendor sees buyer account ids and the
/// reasons a request was referred — never the buyer's documents or score.
class VendorPaymentPlansScreen extends ConsumerStatefulWidget {
  const VendorPaymentPlansScreen({super.key});

  @override
  ConsumerState<VendorPaymentPlansScreen> createState() =>
      _VendorPaymentPlansScreenState();
}

class _VendorPaymentPlansScreenState
    extends ConsumerState<VendorPaymentPlansScreen> {
  AgreementStatus? _filter = AgreementStatus.pendingApproval;

  static const _filters = <(String, AgreementStatus?)>[
    ('Needs your decision', AgreementStatus.pendingApproval),
    ('Active', AgreementStatus.active),
    ('All', null),
  ];

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(vendorPaymentPlansProvider(_filter));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Payment plans'),
      ),
      body: SafeArea(
        child: Column(
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
                children: [
                  for (final (label, status) in _filters)
                    ChoiceChip(
                      key: Key('vendor-plans-filter-${status?.name ?? 'all'}'),
                      label: Text(label),
                      selected: _filter == status,
                      selectedColor: DesignTokens.chipsSelectedFill,
                      onSelected: (_) => setState(() => _filter = status),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(vendorPaymentPlansProvider);
                  await ref.read(vendorPaymentPlansProvider(_filter).future);
                },
                child: plans.when(
                  loading: () => const SmPageLoader(),
                  error: (error, _) => ListView(
                    children: [
                      SmErrorView(
                        message: error is EmiLoadException
                            ? creditFailureMessage(error.failure)
                            : 'We could not load your payment plans.',
                        onRetry: () =>
                            ref.invalidate(vendorPaymentPlansProvider),
                      ),
                    ],
                  ),
                  data: (agreements) => agreements.isEmpty
                      ? ListView(
                          children: [
                            SmEmptyState(
                              message:
                                  _filter == AgreementStatus.pendingApproval
                                  ? 'Nothing is waiting for your decision.'
                                  : 'No payment plans here yet.',
                              icon: Icons.event_repeat_rounded,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(DesignTokens.s16),
                          itemCount: agreements.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: DesignTokens.s12),
                          itemBuilder: (_, i) =>
                              _VendorPlanTile(agreement: agreements[i]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorPlanTile extends ConsumerWidget {
  const _VendorPlanTile({required this.agreement});

  final CreditAgreement agreement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = agreement;
    final name = ref.watch(planProductNameProvider(a.productId)).asData?.value;
    final applied = a.appliedAt;
    return InkWell(
      key: Key('vendor-plan-tile-${a.id}'),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => context.push(RouteNames.vendorPaymentPlanDetailPath(a.id)),
      child: PlanCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? '${a.kind.label} plan',
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '${a.kind.label} · ${planMoney(a.price)} over '
                    '${a.tenureMonths} months'
                    '${applied == null ? '' : ' · ${planInstant(applied)}'}',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            PlanStatusChip(status: a.status, overdue: a.hasOverdue),
          ],
        ),
      ),
    );
  }
}
