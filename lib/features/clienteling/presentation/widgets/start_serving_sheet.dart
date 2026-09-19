import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/notifiers/client_brief_notifier.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/widgets/clienteling_sheet.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Asks what the associate is helping with, because the API requires it:
/// `purpose` must be 3–200 characters.
Future<void> showStartServingSheet(
  BuildContext context,
  ClientBriefNotifier notifier,
) => showClientelingSheet(
  context: context,
  builder: (sheetContext) => _StartServingForm(notifier: notifier),
);

class _StartServingForm extends StatefulWidget {
  const _StartServingForm({required this.notifier});

  final ClientBriefNotifier notifier;

  @override
  State<_StartServingForm> createState() => _StartServingFormState();
}

class _StartServingFormState extends State<_StartServingForm> {
  final _formKey = GlobalKey<FormState>();
  final _purpose = TextEditingController();

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(widget.notifier.startServing(_purpose.text.trim()));
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
          const Text('Start serving', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s8),
          const Text(
            'Say what you are helping with. This is recorded and the customer '
            'can see it.',
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s16),
          TextFormField(
            controller: _purpose,
            maxLength: 200,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Purpose',
              hintText: 'Fitting help for a winter coat',
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.length < 3) return 'Say what you are helping with.';
              if (value.length > 200) return 'Keep it under 200 characters.';
              return null;
            },
          ),
          const SizedBox(height: DesignTokens.s8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }
}
