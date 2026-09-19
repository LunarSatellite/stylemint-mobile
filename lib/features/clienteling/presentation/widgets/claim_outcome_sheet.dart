import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/notifiers/client_brief_notifier.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/widgets/clienteling_sheet.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Files a claim that this associate assisted one order.
///
/// The order is picked from the orders the brief returned, so no one types an
/// id. The claim is an assertion, not credit: only the customer's own
/// confirmation makes it credit, and the sheet says so.
Future<void> showClaimOutcomeSheet(
  BuildContext context, {
  required ClientBriefNotifier notifier,
  required List<ClientOrderSummary> orders,
}) => showClientelingSheet(
  context: context,
  builder: (_) => _ClaimForm(notifier: notifier, orders: orders),
);

class _ClaimForm extends StatefulWidget {
  const _ClaimForm({required this.notifier, required this.orders});

  final ClientBriefNotifier notifier;
  final List<ClientOrderSummary> orders;

  @override
  State<_ClaimForm> createState() => _ClaimFormState();
}

class _ClaimFormState extends State<_ClaimForm> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late ClientOrderSummary _order = widget.orders.first;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final note = _note.text.trim();
    unawaited(
      widget.notifier.claimOutcome(
        orderId: _order.orderId,
        note: note.isEmpty ? null : note,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Claim you assisted an order',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s8),
          const Text(
            'This is a claim, not credit. It becomes credit only if the '
            'customer confirms it.',
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s16),
          ...widget.orders.map(
            (o) => ListTile(
              onTap: () => setState(() => _order = o),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _order.orderId == o.orderId
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _order.orderId == o.orderId
                    ? DesignTokens.primaryGreen
                    : DesignTokens.iconLight,
              ),
              title: Text(
                o.orderNumber ?? 'Order',
                style: DesignTokens.mediumSemibold,
              ),
              subtitle: Text(
                [
                  if (o.vendorSubOrderStatus != null) o.vendorSubOrderStatus!,
                  if (o.placedUtc != null) formatRelative(o.placedUtc!),
                ].join(' · '),
                style: DesignTokens.smallDescription,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          TextFormField(
            controller: _note,
            maxLength: 280,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
            ),
            validator: (v) => (v ?? '').trim().length > 280
                ? 'Keep the note under 280 characters.'
                : null,
          ),
          const SizedBox(height: DesignTokens.s8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('File claim'),
            ),
          ),
        ],
      ),
    );
  }
}
