import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The subtle mark on a hit found only by meaning (AI features contract v1.0
/// §1, `matchType = 2`): no word of the query matched, so the customer is
/// told why it is on the list at all.
///
/// Drawn only when the caller has checked that AI shaped the response; an
/// older server's hits carry [SearchMatchType.unknown] and never get it.
class MatchedByMeaningChip extends StatelessWidget {
  const MatchedByMeaningChip({super.key});

  static const String label = 'Matched by meaning';
  static const Key chipKey = Key('search-matched-by-meaning');

  @override
  Widget build(BuildContext context) => const MallSignalChip(
    key: chipKey,
    signal: MallSignal(
      label: label,
      icon: Icons.auto_awesome_outlined,
      semanticLabel: 'Matched by meaning, not by the exact words',
    ),
  );
}

/// What the search read the query as: one chip per constraint, preference or
/// exclusion it acted on, each removable when its words can be taken out of
/// the query; and a muted chip for words it recognised and did not use.
///
/// The reading is deterministic and runs with or without a model, so these
/// chips claim nothing about AI. The sparkle and "Understood as" line stay
/// gated on `aiApplied` elsewhere.
class SearchUnderstandingChips extends StatelessWidget {
  const SearchUnderstandingChips({
    required this.understanding,
    required this.query,
    required this.onRemove,
    super.key,
  });

  final SearchUnderstanding understanding;
  final String query;

  /// Called with the query to run instead, once a chip is taken off.
  final ValueChanged<String> onRemove;

  static Key chipKey(int index) => Key('search-understanding-chip-$index');
  static Key removeKey(int index) => Key('search-understanding-remove-$index');

  /// "2 left out — they do not record what you asked about." Null for none.
  static String? setAsideLine(SearchUnderstanding understanding) {
    final total = understanding.setAsideTotal;
    if (total <= 0) return null;
    final noun = total == 1 ? 'result' : 'results';
    final unverifiable = understanding.setAsideUnverifiable;
    final conflicting = understanding.setAsideConflicting;
    final why = switch ((unverifiable > 0, conflicting > 0)) {
      (true, true) => 'they do not record it, or record something else',
      (true, false) => 'they do not record it',
      _ => 'what they record does not match',
    };
    return '$total $noun left out: $why';
  }

  @override
  Widget build(BuildContext context) {
    final chips = understanding.visibleChips;
    final setAside = setAsideLine(understanding);
    if (chips.isEmpty && setAside == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chips.isNotEmpty)
            Wrap(
              spacing: DesignTokens.s6,
              runSpacing: DesignTokens.s6,
              children: [
                for (var i = 0; i < chips.length; i++)
                  _UnderstandingChip(
                    key: chipKey(i),
                    chip: chips[i],
                    removeKey: removeKey(i),
                    onRemove: switch (queryWithoutChip(query, chips[i])) {
                      final next? when chips[i].kind.acts =>
                        () => onRemove(next),
                      _ => null,
                    },
                  ),
              ],
            ),
          if (setAside != null)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s6),
              child: Text(
                setAside,
                style: DesignTokens.smallDescription.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnderstandingChip extends StatelessWidget {
  const _UnderstandingChip({
    required this.chip,
    required this.removeKey,
    required this.onRemove,
    super.key,
  });

  final SearchUnderstandingChip chip;
  final Key removeKey;
  final VoidCallback? onRemove;

  IconData get _icon => switch (chip.kind) {
    SearchChipKind.constraint => Icons.filter_alt_outlined,
    SearchChipKind.preference => Icons.swap_vert_rounded,
    SearchChipKind.exclusion => Icons.block_rounded,
    _ => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final text = chip.displayText!;
    final muted = chip.kind == SearchChipKind.notApplied;
    final foreground = muted ? DesignTokens.textMuted : DesignTokens.textWhite;
    final remove = onRemove;
    return Semantics(
      container: true,
      label: text,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: EdgeInsetsDirectional.only(
          start: DesignTokens.s8,
          end: remove == null ? DesignTokens.s8 : 0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 14, color: foreground),
            const SizedBox(width: DesignTokens.s4),
            Flexible(
              child: ExcludeSemantics(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.smallRegular.copyWith(color: foreground),
                ),
              ),
            ),
            if (remove != null)
              IconButton(
                key: removeKey,
                onPressed: remove,
                tooltip: 'Remove $text',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: DesignTokens.minTouchTarget,
                  minHeight: 32,
                ),
                icon: Icon(Icons.close_rounded, size: 14, color: foreground),
              ),
          ],
        ),
      ),
    );
  }
}
