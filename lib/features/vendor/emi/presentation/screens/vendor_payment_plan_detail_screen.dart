import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// Reasons a vendor may give for declining, as the server accepts them:
/// lower_snake_case codes, shown back to the buyer as words.
const vendorDeclineReasons = <String, String>{
  'insufficient_history': 'Not enough history with this buyer',
  'out_of_stock': 'Item no longer available',
  'pricing_error': 'The price is wrong',
  'not_offered_now': 'Not offering plans right now',
};

/// One payment plan on the vendor's product, and — when it is the vendor's
/// to decide — approve or decline.
///
/// A vendor decides only EMI referrals on stock they lend themselves. Plans
/// StyleMint guarantees are not the vendor's risk, so they are shown but not
/// offered for a decision; the server refuses them in any case.
class VendorPaymentPlanDetailScreen extends ConsumerStatefulWidget {
  const VendorPaymentPlanDetailScreen({required this.agreementId, super.key});

  final String agreementId;

  @override
  ConsumerState<VendorPaymentPlanDetailScreen> createState() =>
      _VendorPaymentPlanDetailScreenState();
}

class _VendorPaymentPlanDetailScreenState
    extends ConsumerState<VendorPaymentPlanDetailScreen> {
  bool _deciding = false;
  String? _error;

  /// One key per decision the vendor means to make.
  final String _key = const Uuid().v4();

  Future<void> _decide(CreditAgreement a, {required bool approve}) async {
    var reasons = const <String>[];
    if (!approve) {
      final picked = await _pickReasons(context);
      if (picked == null || !mounted) return;
      reasons = picked;
    }
    setState(() {
      _deciding = true;
      _error = null;
    });
    final result = await ref
        .read(creditRepositoryProvider)
        .vendorReview(
          agreementId: a.id,
          approve: approve,
          reasons: reasons,
          idempotencyKey: _key,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _deciding = false;
        _error = creditFailureMessage(failure);
      }),
      (_) {
        setState(() => _deciding = false);
        ref
          ..invalidate(vendorPaymentPlanProvider(a.id))
          ..invalidate(vendorPaymentPlansProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Plan approved' : 'Plan declined'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(vendorPaymentPlanProvider(widget.agreementId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Payment plan'),
      ),
      body: SafeArea(
        child: plan.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => SmErrorView(
            message: error is EmiLoadException
                ? creditFailureMessage(error.failure)
                : 'We could not load this plan.',
            onRetry: () =>
                ref.invalidate(vendorPaymentPlanProvider(widget.agreementId)),
          ),
          data: _body,
        ),
      ),
    );
  }

  Widget _body(CreditAgreement a) {
    final name = ref.watch(planProductNameProvider(a.productId)).asData?.value;
    final decidable =
        a.status == AgreementStatus.pendingApproval &&
        a.guarantor == PlanGuarantor.vendor;
    final buyer = a.buyerAccountId;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name ?? '${a.kind.label} plan',
                style: DesignTokens.h3,
              ),
            ),
            PlanStatusChip(status: a.status, overdue: a.hasOverdue),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Buyer ${_shortId(buyer)}',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s16),
        if (a.reasons.isNotEmpty)
          PlanCard(
            borderColor: DesignTokens.colorWarning.withValues(alpha: 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.status == AgreementStatus.pendingApproval
                      ? 'Why this needs your decision'
                      : 'Reasons',
                  style: DesignTokens.mediumSemibold,
                ),
                const SizedBox(height: DesignTokens.s4),
                for (final r in a.reasons)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.s4),
                    child: Text(
                      reasonForVendor(r),
                      style: DesignTokens.smallRegular,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: DesignTokens.s16),
        PlanCard(
          child: Column(
            children: [
              PlanRow(label: 'Price', value: planMoney(a.price)),
              PlanRow(
                label: 'Paid to start',
                value: planMoney(a.downPayment),
              ),
              PlanRow(
                label: 'Paid over ${a.tenureMonths} months',
                value: planMoney(a.financed),
              ),
              if (a.status == AgreementStatus.active)
                PlanRow(
                  label: 'Still to collect',
                  value: planMoney(a.outstanding),
                  emphasised: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          a.guarantor == PlanGuarantor.vendor
              ? 'You carry what goes unpaid on this plan.'
              : a.guarantor.statement,
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        if (a.instalments.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s16),
          const Text('Schedule', style: DesignTokens.mediumSemibold),
          for (final i in a.instalments) PlanInstalmentTile(instalment: i),
        ],
        if (decidable) ...[
          const SizedBox(height: DesignTokens.s24),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Text(
                _error!,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('vendor-plan-decline'),
                  onPressed: _deciding
                      ? null
                      : () => unawaited(_decide(a, approve: false)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignTokens.colorError,
                    side: const BorderSide(color: DesignTokens.colorError),
                    minimumSize: const Size.fromHeight(
                      DesignTokens.buttonHeight,
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: FilledButton(
                  key: const Key('vendor-plan-approve'),
                  onPressed: _deciding
                      ? null
                      : () => unawaited(_decide(a, approve: true)),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.buttonPrimaryFill,
                    foregroundColor: DesignTokens.buttonPrimaryText,
                    minimumSize: const Size.fromHeight(
                      DesignTokens.buttonHeight,
                    ),
                  ),
                  child: Text(_deciding ? 'Saving…' : 'Approve'),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Approving lets the buyer pay the down payment and start the '
            'plan. The item ships once they have paid it.',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// The end of an account id: enough to tell buyers apart, no more.
String _shortId(String id) =>
    id.length > 8 ? '…${id.substring(id.length - 8)}' : id;

/// Asks why, before declining. Returns null when the vendor backs out.
Future<List<String>?> _pickReasons(BuildContext context) =>
    showModalBottomSheet<List<String>>(
      context: context,
      useSafeArea: true,
      backgroundColor: DesignTokens.bgAppBodyLight,
      builder: (_) => const _ReasonSheet(),
    );

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet();

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(DesignTokens.s20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Why are you declining?', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'The buyer is told the reason.',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        for (final entry in vendorDeclineReasons.entries)
          CheckboxListTile(
            key: Key('vendor-decline-${entry.key}'),
            contentPadding: EdgeInsets.zero,
            value: _picked.contains(entry.key),
            onChanged: (on) => setState(
              () => on == true
                  ? _picked.add(entry.key)
                  : _picked.remove(entry.key),
            ),
            title: Text(entry.value, style: DesignTokens.smallRegular),
          ),
        const SizedBox(height: DesignTokens.s12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('vendor-decline-confirm'),
            onPressed: _picked.isEmpty
                ? null
                : () => Navigator.of(context).pop(_picked.toList()),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.colorError,
              minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
            ),
            child: const Text('Decline plan'),
          ),
        ),
      ],
    ),
  );
}
