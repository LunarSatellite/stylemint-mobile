import 'package:flutter/foundation.dart' show immutable;

/// What a feed item actually **is**, mirroring the backend `FeedSlotKind`.
///
/// This enum exists because the server used to stamp every cold-start item
/// `Personalized` — trending reels and catalogue tiles alike — and the client
/// had no way to tell. Two of these values assert a relationship to *this*
/// customer ([personalized], [exploration]); the other two assert nothing at
/// all and are the honest labels for content every customer receives
/// identically.
///
/// Generic content is not the problem. Labelling it as personal is.
enum FeedSlotKind {
  /// Ranked for this customer by the scorer, or drawn from their own declared
  /// interest categories. The only value that may carry "your" copy.
  personalized,

  /// A deliberate off-profile injection for this customer. Personal in origin,
  /// but it is explicitly *not* a preference match, so it never says so.
  exploration,

  /// Globally popular right now. Identical for every customer.
  popular,

  /// Most recently published. Identical for every customer, and nothing ranked
  /// it — items of this kind arrive with a null score by construction.
  newIn,

  /// A slot kind this build does not know: a value added to the server enum
  /// after this app shipped.
  ///
  /// It degrades to the most conservative label there is. A future server
  /// value must never become a personalisation claim by default, so this is
  /// [isPersonal] `false` and its copy claims nothing whatsoever — not
  /// popularity, not recency, not relevance.
  unknown;

  /// Reads the wire value. The Discovery mapper emits the enum's **name**
  /// (`SlotKind = d.SlotKind.ToString()`), but the integer ordinal is accepted
  /// too so that a future `JsonStringEnumConverter` change either way is not
  /// client-breaking.
  ///
  /// An absent, empty or unrecognised value is [unknown] — never
  /// [personalized]. Absence is not evidence of personalisation.
  static FeedSlotKind parse(Object? raw) {
    if (raw is num) {
      return switch (raw.toInt()) {
        1 => personalized,
        2 => exploration,
        3 => popular,
        4 => newIn,
        _ => unknown,
      };
    }
    if (raw is String) {
      final name = raw.trim().toLowerCase();
      if (name.isEmpty) return unknown;
      return switch (name) {
        'personalized' || 'personalised' => personalized,
        'exploration' => exploration,
        'popular' => popular,
        'newin' || 'new_in' => newIn,
        // A numeric string is still a number.
        _ => parse(int.tryParse(name)),
      };
    }
    return unknown;
  }

  /// True only where the server asserted this item has something to do with
  /// *this* customer. False for [unknown] — deliberately, and permanently.
  bool get isPersonal => this == personalized || this == exploration;

  /// The customer-facing label. Every one of these is a sentence the app can
  /// defend:
  ///
  /// * [personalized] names the real source — the customer's own declared
  ///   interests — rather than implying a model picked it.
  /// * [exploration] says it is a departure, because that is what it is.
  /// * [popular] and [newIn] say what is true of the content and nothing
  ///   about the reader. No "for you", no "based on your activity", no "we
  ///   thought you'd like this".
  /// * [unknown] claims nothing at all.
  String get label => switch (this) {
    FeedSlotKind.personalized => 'From your interests',
    FeedSlotKind.exploration => 'Something different',
    FeedSlotKind.popular => 'Popular right now',
    FeedSlotKind.newIn => 'New in',
    FeedSlotKind.unknown => 'From the Mall',
  };

  /// The spoken form, which spells out what the short label compresses.
  String get spokenLabel => switch (this) {
    FeedSlotKind.personalized => 'From the categories you follow',
    FeedSlotKind.exploration => 'Something different from your usual',
    FeedSlotKind.popular => 'Popular with shoppers right now',
    FeedSlotKind.newIn => 'Newly published on StyleMint',
    FeedSlotKind.unknown => 'From the Mall',
  };
}

/// Why one feed item is here, and whether anything ranked it.
///
/// [score] is nullable on the wire and nullable here, and the two states mean
/// genuinely different things: a number means a scorer ordered this item, and
/// `null` means **nothing ranked it**. Null is not zero, and it is not "worst".
/// Nothing in this class will turn it into either.
@immutable
class FeedProvenance {
  const FeedProvenance({required this.kind, this.score, this.rank});

  /// Reads one `FeedItemVm`. A missing `slotKind` degrades to
  /// [FeedSlotKind.unknown]; a missing or non-numeric `score` stays null.
  factory FeedProvenance.fromJson(Map<String, dynamic> json) {
    final score = json['score'];
    return FeedProvenance(
      kind: FeedSlotKind.parse(json['slotKind']),
      score: score is num ? score.toDouble() : null,
    );
  }

  final FeedSlotKind kind;

  /// The scorer's figure, or null when nothing ranked this item.
  ///
  /// It is deliberately **not** surfaced as a magnitude anywhere. The number
  /// means different things per source — a relevance figure for a personalised
  /// slot, a 7-day engagement figure for trending, a publish timestamp for the
  /// fanout projection — so the only honest use of it is *ordering within one
  /// page*, which is what [rank] carries.
  final double? score;

  /// This item's 1-based position among the **scored** items of its page, or
  /// null when [score] was null.
  ///
  /// Assigned by [rankAll]. An unranked item has no rank: it is not given the
  /// last position, and it is not given zero.
  final int? rank;

  /// Whether a rank may be drawn at all. When false, no rank is drawn —
  /// not a dash, not a zero, not an empty bar.
  bool get isRanked => rank != null;

  /// The short rank label, or null when there is no rank to show.
  String? get rankLabel => rank == null ? null : '#$rank';

  /// The spoken rank, or null when there is no rank to show.
  String? get spokenRank =>
      rank == null ? null : 'Ranked number $rank of the ranked items here';

  FeedProvenance withRank(int? rank) =>
      FeedProvenance(kind: kind, score: score, rank: rank);

  /// Assigns ranks across one page, highest score first.
  ///
  /// Items whose score is null keep a null rank and are not counted, so a page
  /// of entirely unranked items produces entirely unranked provenance. Ties
  /// keep their original order.
  static List<FeedProvenance> rankAll(List<FeedProvenance> items) {
    final scored =
        <int>[
          for (var i = 0; i < items.length; i++)
            if (items[i].score != null) i,
        ]..sort((a, b) {
          final byScore = items[b].score!.compareTo(items[a].score!);
          return byScore != 0 ? byScore : a.compareTo(b);
        });

    final ranks = <int, int>{
      for (var position = 0; position < scored.length; position++)
        scored[position]: position + 1,
    };
    return [
      for (var i = 0; i < items.length; i++) items[i].withRank(ranks[i]),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is FeedProvenance &&
      other.kind == kind &&
      other.score == score &&
      other.rank == rank;

  @override
  int get hashCode => Object.hash(kind, score, rank);

  @override
  String toString() =>
      'FeedProvenance(${kind.name}, score: $score, $rankLabel)';
}
