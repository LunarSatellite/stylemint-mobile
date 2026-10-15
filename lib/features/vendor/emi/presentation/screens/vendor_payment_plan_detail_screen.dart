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
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Reasons a vendor may give for declining, as the server accepts them:
/// lower_snake_case codes, shown back to the buyer as words.
const vendorDeclineReasons = <String, String>{
  'insufficient_history': 'Not enough history with this buyer',
  'out_of_stock': 'Item no longer available',
  'pricing_error': 'The price is wrong',
  'not_offered_now': 'Not offering plans right now',
  'documents_not_sufficient': 'The documents do not show enough income',
  'identity_not_confirmed': 'Could not confirm the buyer’s identity',
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
    String? note;
    if (!approve) {
      final picked = await _pickReasons(context);
      if (picked == null || !mounted) return;
      reasons = picked.reasons;
      note = picked.note;
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
          note: note,
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
          ..invalidate(vendorCreditApplicationProvider(a.id))
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
    final application = a.guarantor == PlanGuarantor.vendor
        ? ref.watch(vendorCreditApplicationProvider(a.id)).asData?.value
        : null;
    final buyer = application?.buyerDisplayName ?? _shortId(a.buyerAccountId);
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
          'Buyer: $buyer',
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
        if (application != null) ...[
          const SizedBox(height: DesignTokens.s16),
          _Documents(application: application),
        ],
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

/// The buyer's identity and financial documents. Each is fetched only when
/// the seller taps it, one at a time; the server records every opening.
class _Documents extends ConsumerStatefulWidget {
  const _Documents({required this.application});

  final VendorCreditApplication application;

  @override
  ConsumerState<_Documents> createState() => _DocumentsState();
}

class _DocumentsState extends ConsumerState<_Documents> {
  String? _opening;
  String? _error;

  Future<void> _open(CreditDocumentInfo doc) async {
    setState(() {
      _opening = doc.id;
      _error = null;
    });
    final link = await ref
        .read(creditRepositoryProvider)
        .vendorDocumentLink(
          agreementId: widget.application.agreement.id,
          documentId: doc.id,
        );
    if (!mounted) return;
    final url = link.fold((f) {
      setState(() => _error = creditFailureMessage(f));
      return null;
    }, (u) => u);
    setState(() => _opening = null);
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object {
      if (mounted) setState(() => _error = 'Could not open the document.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.application.documents;
    final submitted = widget.application.agreement.documentsSubmittedAt != null;
    var identity = 0;
    var financial = 0;
    return PlanCard(
      key: const Key('vendor-plan-documents'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buyer’s documents', style: DesignTokens.mediumSemibold),
          if (widget.application.riskBand != null)
            Text(
              'Risk band ${widget.application.riskBand}'
              '${widget.application.riskScore != null ? ' · score ${widget.application.riskScore}' : ''}',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          if (!submitted || docs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s4),
              child: Text(
                'The buyer has not sent their documents yet.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.colorWarning,
                ),
              ),
            ),
          for (final d in docs)
            TextButton.icon(
              key: Key('vendor-plan-document-${d.id}'),
              onPressed: _opening == null ? () => unawaited(_open(d)) : null,
              icon: Icon(
                d.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              ),
              label: Text(
                d.kind == CreditDocumentKind.identity
                    ? 'Open identity document ${++identity}'
                    : 'Open financial proof ${++financial}',
              ),
            ),
          if (_error != null)
            Text(
              _error!,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.colorError),
            ),
        ],
      ),
    );
  }
}

/// Asks why, before declining. Returns null when the vendor backs out.
Future<({List<String> reasons, String? note})?> _pickReasons(
  BuildContext context,
) => showModalBottomSheet<({List<String> reasons, String? note})>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
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
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      DesignTokens.s20,
      DesignTokens.s20,
      DesignTokens.s20,
      DesignTokens.s20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
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
        TextField(
          key: const Key('vendor-decline-note'),
          controller: _note,
          maxLength: 500,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Note for the buyer (optional)',
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('vendor-decline-confirm'),
            onPressed: _picked.isEmpty
                ? null
                : () => Navigator.of(context).pop((
                    reasons: _picked.toList(),
                    note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                  )),
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
