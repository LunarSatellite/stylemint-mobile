import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/feed_provenance.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Says why a feed item is here, in the Mall's signal vocabulary.
///
/// Two rules are structural rather than stylistic:
///
/// * **A null score draws nothing.** The rank chip exists only when the server
///   sent a score for this item. It is never a zero, never a dash, never an
///   empty bar and never the last position — an unranked item simply has no
///   rank, and a page of unranked items shows one chip each.
/// * **Colour is never the carrier.** Every kind owns a glyph and a word; the
///   tone only follows them. The chip reads the same in greyscale.
class FeedProvenanceBadge extends StatelessWidget {
  const FeedProvenanceBadge({required this.provenance, super.key});

  final FeedProvenance provenance;

  static const Key badgeKey = Key('feed-provenance-badge');
  static const Key rankKey = Key('feed-provenance-rank');

  /// The glyph for a kind. [FeedSlotKind.unknown] gets the storefront mark —
  /// the Mall itself, claiming nothing about the reader.
  static IconData iconFor(FeedSlotKind kind) => switch (kind) {
    FeedSlotKind.personalized => Icons.interests_outlined,
    FeedSlotKind.exploration => Icons.explore_outlined,
    FeedSlotKind.popular => Icons.local_fire_department_outlined,
    FeedSlotKind.newIn => Icons.auto_awesome_outlined,
    FeedSlotKind.unknown => Icons.storefront_outlined,
  };

  /// Only genuinely personal slots take the accent tone. Everything else is
  /// neutral, including [FeedSlotKind.unknown].
  static MallSignalTone toneFor(FeedSlotKind kind) =>
      kind.isPersonal ? MallSignalTone.accent : MallSignalTone.neutral;

  @override
  Widget build(BuildContext context) {
    final rankLabel = provenance.rankLabel;
    return Wrap(
      key: badgeKey,
      spacing: DesignTokens.s6,
      runSpacing: DesignTokens.s6,
      children: [
        MallSignalChip(
          signal: MallSignal(
            label: provenance.kind.label,
            tone: toneFor(provenance.kind),
            icon: iconFor(provenance.kind),
            semanticLabel: provenance.kind.spokenLabel,
          ),
        ),
        // Nothing ranked this item: no chip at all.
        if (rankLabel != null)
          MallSignalChip(
            key: rankKey,
            signal: MallSignal(
              label: rankLabel,
              icon: Icons.leaderboard_outlined,
              semanticLabel: provenance.spokenRank,
            ),
          ),
      ],
    );
  }
}
