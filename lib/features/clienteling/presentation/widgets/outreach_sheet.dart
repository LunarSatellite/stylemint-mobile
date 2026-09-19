import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/clienteling_labels.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/notifiers/client_brief_notifier.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/widgets/clienteling_sheet.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Composes an outreach request.
///
/// [allowedChannels] are only the channels the brief said the platform would
/// carry a message on. A channel the backend blocked is never offered here —
/// the block is a consent decision, not a client-side preference.
Future<void> showOutreachSheet(
  BuildContext context, {
  required ClientBriefNotifier notifier,
  required List<ClientelingOutreachChannel> allowedChannels,
}) => showClientelingSheet(
  context: context,
  builder: (_) => _OutreachForm(notifier: notifier, channels: allowedChannels),
);

class _OutreachForm extends StatefulWidget {
  const _OutreachForm({required this.notifier, required this.channels});

  final ClientBriefNotifier notifier;
  final List<ClientelingOutreachChannel> channels;

  @override
  State<_OutreachForm> createState() => _OutreachFormState();
}

class _OutreachFormState extends State<_OutreachForm> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  late ClientelingOutreachChannel _channel = widget.channels.first;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(
      widget.notifier.sendOutreach(
        channel: _channel,
        subject: _subject.text.trim(),
        body: _body.text.trim(),
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
          const Text('Send a message', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s8),
          const Text(
            'The platform delivers this. Whether it goes out is its decision, '
            'and the attempt is recorded either way.',
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s16),
          if (widget.channels.length > 1)
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: widget.channels
                  .map(
                    (c) => ChoiceChip(
                      label: Text(outreachChannelLabel(c)),
                      selected: _channel == c,
                      onSelected: (_) => setState(() => _channel = c),
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              'Channel: ${outreachChannelLabel(_channel)}',
              style: DesignTokens.smallRegular,
            ),
          const SizedBox(height: DesignTokens.s16),
          TextFormField(
            controller: _subject,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Subject'),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.length < 3) {
                return 'Subject must be at least 3 characters.';
              }
              if (value.length > 120) {
                return 'Keep the subject under 120 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: DesignTokens.s8),
          TextFormField(
            controller: _body,
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Message'),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.length < 3) {
                return 'Message must be at least 3 characters.';
              }
              if (value.length > 1000) {
                return 'Keep the message under 1000 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: DesignTokens.s8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Request send'),
            ),
          ),
        ],
      ),
    );
  }
}
