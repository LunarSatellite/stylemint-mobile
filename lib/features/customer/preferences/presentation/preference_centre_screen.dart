import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/ask_once_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/why_strings.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/domain/preference_centre.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Profile / Settings → "Your preferences".
///
/// Registry-driven: every declarable dimension the server lists, grouped by
/// its group, with single- or multi-select chips, a per-context switch
/// (for me / gift / kids …) and a clear button per dimension.
class PreferenceCentreScreen extends ConsumerStatefulWidget {
  const PreferenceCentreScreen({super.key});

  @override
  ConsumerState<PreferenceCentreScreen> createState() =>
      _PreferenceCentreScreenState();
}

class _PreferenceCentreScreenState
    extends ConsumerState<PreferenceCentreScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(
        () => ref.read(preferenceCentreNotifierProvider.notifier).load(),
      ),
    );
  }

  static String contextLabel(String context) => switch (context) {
    'self' => 'For me',
    'gift' => 'Gifts',
    'kids' => 'Kids',
    'parents' => 'Parents',
    'partner' => 'Partner',
    _ => preferenceValueLabel(context),
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preferenceCentreNotifierProvider);
    final notifier = ref.read(preferenceCentreNotifierProvider.notifier);
    ref.listen(preferenceCentreNotifierProvider.select((s) => s.saveError), (
      _,
      next,
    ) {
      if (next != null) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(next)));
      }
    });
    final centre = state.centre;
    return Scaffold(
      appBar: AppBar(title: const Text('Your preferences')),
      body: () {
        if (state.loading && centre == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (centre == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.error ?? 'Your preferences could not be loaded.'),
                TextButton(
                  onPressed: () => unawaited(notifier.load()),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        final groups = centre.byGroup;
        return ListView(
          key: const ValueKey('preference-centre'),
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            Text(
              WhyStrings.of(context, 'prefs.privacy')!,
              key: const ValueKey('prefs-privacy'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.s16),
            if (centre.contexts.length > 1)
              Wrap(
                spacing: DesignTokens.s8,
                children: [
                  for (final c in centre.contexts)
                    ChoiceChip(
                      key: ValueKey('prefs-context-$c'),
                      label: Text(contextLabel(c)),
                      selected: state.context == c,
                      onSelected: (_) => notifier.selectContext(c),
                    ),
                ],
              ),
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: DesignTokens.s24),
                child: Text('There is nothing to set yet.'),
              ),
            for (final entry in groups.entries) ...[
              const SizedBox(height: DesignTokens.s24),
              Text(
                preferenceValueLabel(entry.key),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final d in entry.value)
                _DimensionTile(
                  dimension: d,
                  selected: d.selectedIn(state.context),
                  saving: state.saving.contains(d.key),
                  onToggle: (v) => unawaited(notifier.toggle(d, v)),
                  onClear: () => unawaited(notifier.clear(d)),
                ),
            ],
          ],
        );
      }(),
    );
  }
}

class _DimensionTile extends StatelessWidget {
  const _DimensionTile({
    required this.dimension,
    required this.selected,
    required this.saving,
    required this.onToggle,
    required this.onClear,
  });

  final DeclarableDimension dimension;
  final Set<String> selected;
  final bool saving;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey('prefs-dim-${dimension.key}'),
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(dimension.label, style: theme.textTheme.titleSmall),
              ),
              if (selected.isNotEmpty)
                TextButton(
                  key: ValueKey('prefs-clear-${dimension.key}'),
                  onPressed: saving ? null : onClear,
                  child: const Text('Clear'),
                ),
            ],
          ),
          if (dimension.description case final text?)
            Text(text, style: theme.textTheme.bodySmall),
          if (dimension.isDeclaredOnly)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s4),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16),
                  const SizedBox(width: DesignTokens.s4),
                  Expanded(
                    child: Text(
                      WhyStrings.of(context, 'prefs.sensitive_note')!,
                      key: ValueKey('prefs-sensitive-${dimension.key}'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final v in dimension.values)
                dimension.isMulti
                    ? FilterChip(
                        key: ValueKey('prefs-${dimension.key}-$v'),
                        label: Text(preferenceValueLabel(v)),
                        selected: selected.contains(v),
                        onSelected: saving ? null : (_) => onToggle(v),
                      )
                    : ChoiceChip(
                        key: ValueKey('prefs-${dimension.key}-$v'),
                        label: Text(preferenceValueLabel(v)),
                        selected: selected.contains(v),
                        onSelected: saving ? null : (_) => onToggle(v),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}
