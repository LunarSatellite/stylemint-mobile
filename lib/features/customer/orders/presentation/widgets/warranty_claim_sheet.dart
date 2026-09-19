import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_claim.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

Future<void> showWarrantyClaimSheet(
  BuildContext context,
  WidgetRef ref, {
  required String orderNumber,
  required CareItem item,
}) async {
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _WarrantyClaimForm(
      orderNumber: orderNumber,
      item: item,
    ),
  );
  if (submitted == true) {
    ref.invalidate(orderCarePlanProvider(orderNumber));
    ref.invalidate(warrantyClaimsProvider);
  }
}

Future<void> showWarrantyStatusSheet(
  BuildContext context,
  WidgetRef ref,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: DesignTokens.bgAppBody,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => const _WarrantyStatusList(),
);

class _WarrantyClaimForm extends ConsumerStatefulWidget {
  const _WarrantyClaimForm({required this.orderNumber, required this.item});

  final String orderNumber;
  final CareItem item;

  @override
  ConsumerState<_WarrantyClaimForm> createState() => _WarrantyClaimFormState();
}

class _WarrantyClaimFormState extends ConsumerState<_WarrantyClaimForm> {
  final _description = TextEditingController();
  WarrantyIssueKind _issue = WarrantyIssueKind.manufacturingDefect;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _description.text.trim();
    if (description.length < 10) {
      setState(
        () =>
            _error = 'Tell the seller what happened in at least 10 characters.',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(ordersRepositoryProvider)
        .submitWarrantyClaim(
          orderNumber: widget.orderNumber,
          subOrderLineId: widget.item.subOrderLineId,
          issueKind: _issue,
          description: description,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _error = NetworkExceptions.getMessage(failure);
      }),
      (claim) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warranty claim ${claim.claimNumber} submitted'),
          ),
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s20,
        DesignTokens.s16,
        DesignTokens.s20,
        MediaQuery.viewInsetsOf(context).bottom + DesignTokens.s20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            const Text('Warranty support', style: DesignTokens.titleMedium),
            const SizedBox(height: DesignTokens.s4),
            Text(widget.item.title, style: DesignTokens.mediumSemibold),
            if (widget.item.warrantyEndsUtc case final ends?)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.s4),
                child: Text(
                  'Covered until ${MaterialLocalizations.of(context).formatMediumDate(ends.toLocal())}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            if (widget.item.warrantyTerms case final terms?) ...[
              const SizedBox(height: DesignTokens.s12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DesignTokens.s12),
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                ),
                child: Text(
                  terms,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s16),
            DropdownButtonFormField<WarrantyIssueKind>(
              initialValue: _issue,
              dropdownColor: DesignTokens.bgAppBody,
              decoration: const InputDecoration(labelText: 'What went wrong?'),
              items: WarrantyIssueKind.values
                  .map(
                    (issue) => DropdownMenuItem(
                      value: issue,
                      child: Text(issue.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _issue = value ?? _issue),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextField(
              controller: _description,
              enabled: !_submitting,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                hintText: 'When did it start, and what happens?',
                alignLabelWithHint: true,
              ),
            ),
            if (_error case final error?)
              Text(
                error,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: DesignTokens.primaryButtonStyle(),
                child: Text(_submitting ? 'Submitting…' : 'Submit claim'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WarrantyStatusList extends ConsumerWidget {
  const _WarrantyStatusList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims = ref.watch(warrantyClaimsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Warranty claims', style: DesignTokens.titleMedium),
            const SizedBox(height: DesignTokens.s12),
            claims.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Could not load warranty claims.'),
              data: (items) => items.isEmpty
                  ? const Text('No warranty claims yet.')
                  : Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (_, index) {
                          final claim = items[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.shield_outlined,
                              color: DesignTokens.primaryGreen,
                            ),
                            title: Text(claim.claimNumber),
                            subtitle: Text(claim.description),
                            trailing: Text(_stateLabel(claim.state)),
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

String _stateLabel(WarrantyClaimState state) => switch (state) {
  WarrantyClaimState.submitted => 'Submitted',
  WarrantyClaimState.approved => 'Approved',
  WarrantyClaimState.rejected => 'Rejected',
  WarrantyClaimState.repairInProgress => 'Repairing',
  WarrantyClaimState.replacementInProgress => 'Replacing',
  WarrantyClaimState.resolved => 'Resolved',
  WarrantyClaimState.cancelled => 'Cancelled',
  WarrantyClaimState.unknown => 'Updated',
};
