import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/domain/composed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/why_strings.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A dismissible one-question card from the mall home composer.
///
/// Drawing it records the question as asked (once per run); answering
/// saves the shopper's own declared value; dismissing hides it for the rest
/// of the session. An answered or dismissed question is never shown again
/// in this run.
class AskOnceCard extends ConsumerStatefulWidget {
  const AskOnceCard({required this.question, super.key});

  final ScreenQuestion question;

  @override
  ConsumerState<AskOnceCard> createState() => _AskOnceCardState();
}

class _AskOnceCardState extends ConsumerState<AskOnceCard> {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(askOnceControllerProvider.notifier);
    if (controller.shouldShow(widget.question)) {
      unawaited(controller.shown(widget.question));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(askOnceControllerProvider);
    final controller = ref.read(askOnceControllerProvider.notifier);
    final q = widget.question;
    if (!controller.shouldShow(q)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('ask-once-card'),
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(q.label, style: theme.textTheme.titleSmall),
                ),
                TextButton(
                  key: const ValueKey('ask-once-dismiss'),
                  onPressed: _sending ? null : () => controller.dismiss(q),
                  child: Text(WhyStrings.of(context, 'ask.dismiss')!),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                for (final value in q.values)
                  ActionChip(
                    key: ValueKey('ask-once-$value'),
                    label: Text(preferenceValueLabel(value)),
                    onPressed: _sending ? null : () => _answer(value),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              WhyStrings.of(context, 'prefs.privacy')!,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _answer(String value) async {
    setState(() => _sending = true);
    final ok = await ref
        .read(askOnceControllerProvider.notifier)
        .answer(widget.question, value);
    if (!mounted) return;
    setState(() => _sending = false);
    if (!ok) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Your answer could not be saved.')),
      );
    }
  }
}

/// A registry value (`kebab_or_snake`) as a readable chip label.
String preferenceValueLabel(String value) {
  final words = value.replaceAll(RegExp('[_-]+'), ' ').trim();
  if (words.isEmpty) return value;
  return words[0].toUpperCase() + words.substring(1);
}
