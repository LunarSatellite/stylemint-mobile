/// What StyleMint has actually recorded about one brand's partnership
/// conduct — backend `BrandPartnershipRecordDto`, served by
/// `GET /v1/creator/brands/{vendorProfileId}/partnership-record`.
///
/// ## Why this exists
///
/// It replaces `BrandTrustDto` (`GET /v1/creator/brands/{vendorId}/trust`),
/// which carried a 0–100 "trust score" and a five-band tier. Both were built
/// on the server from five hardcoded constants, and the recalculation that
/// used them had no caller — so the stored row every brand served was
/// `score: 0`, `tier: New`, every component `0`. This app rendered that as a
/// **0.0 star rating** and **"Success Rate with Creators: 0%"** for every
/// brand on the platform. Nothing threw, because `required` binds the
/// constructor and not the JSON, and the old `fromJson` defaulted every
/// field with `?? 0`.
///
/// Four of the five components had no data source anywhere: brand→creator
/// payment is never recorded, nothing rates a brief, no creator ever rates a
/// brand, and there is no "completed" partnership outcome. They are gone.
/// What is left is counted from partnership rows.
///
/// ## The shape of an honest figure
///
/// There is no composite, no score and no tier here, and no
/// `totalCampaignValue` or `verifiedByCount`. There are counts, and two
/// measured rates. A rate carries its own arithmetic — numerator,
/// denominator, window — and a [MeasuredRateDto.statement] written by the
/// server to be shown verbatim.
///
/// **A rate is null below [BrandPartnershipRecordDto.minimumObservations]
/// observations.** Null means "too little recorded to divide by", never
/// zero. A null rate must never be rendered as a percentage; that was the
/// original defect. [MeasuredRateDto.tryFromJson] refuses to build a rate
/// that has no denominator, so the "0%" path does not exist in this model.
///
/// Percent is deliberately **not** parsed. The wire carries one, but a bare
/// percentage is exactly the misread this endpoint was built to stop, and
/// the fraction plus the statement say everything the percentage would.
/// Nothing can render a figure this model does not hold.
library;

/// One brand's recorded partnership conduct.
class BrandPartnershipRecordDto {
  const BrandPartnershipRecordDto({
    required this.vendorProfileId,
    required this.windowDays,
    required this.minimumObservations,
    required this.counts,
    required this.messagingRecordAvailable,
    this.windowStartUtc,
    this.windowEndUtc,
    this.observedUtc,
    this.creatorRequestsAnswered,
    this.creatorChatsReplied,
  });

  /// Fields the contract may grow are ignored rather than fatal, and every
  /// field is read defensively: a malformed payload degrades to "nothing
  /// recorded", never to a figure this app would then state about a brand.
  factory BrandPartnershipRecordDto.fromJson(Map<String, dynamic> json) {
    final counts = BrandPartnershipCountsDto.fromJson(
      json['counts'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    final messagingAvailable =
        json['messagingRecordAvailable'] as bool? ?? false;
    return BrandPartnershipRecordDto(
      vendorProfileId: (json['vendorProfileId'] as String?) ?? '',
      windowDays: _nonNegativeInt(json['windowDays']),
      minimumObservations: _nonNegativeInt(json['minimumObservations']),
      counts: counts,
      messagingRecordAvailable: messagingAvailable,
      windowStartUtc: _utc(json['windowStartUtc']),
      windowEndUtc: _utc(json['windowEndUtc']),
      observedUtc: _utc(json['observedUtc']),
      creatorRequestsAnswered:
          MeasuredRateDto.tryFromJson(json['creatorRequestsAnswered']),
      // A rate the server could not measure stays null even if a payload
      // carries one, so an unreadable messaging record can never surface as
      // a reply figure.
      creatorChatsReplied: messagingAvailable
          ? MeasuredRateDto.tryFromJson(json['creatorChatsReplied'])
          : null,
    );
  }

  /// Vendor **profile** id — how partnerships are keyed, and what this
  /// endpoint is addressed by. The retired trust route documented an account
  /// id and created a row for whichever id it was handed, so the drift never
  /// surfaced. The brand detail response (`GET /v1/brands/{accountId}`)
  /// carries the profile id as its `id`.
  final String vendorProfileId;

  /// Length of the reporting window every windowed figure covers.
  final int windowDays;

  /// Smallest denominator a rate may be published with. Below this the
  /// server sends a null rate and the counts alone.
  final int minimumObservations;

  final BrandPartnershipCountsDto counts;

  /// False when the messaging record could not be read at all. The chat
  /// reply rate is then **unknown**, which is a different thing from a
  /// brand that replied to nobody, and has to read differently.
  final bool messagingRecordAvailable;

  final DateTime? windowStartUtc;
  final DateTime? windowEndUtc;

  /// When these figures were read from the recorded rows.
  final DateTime? observedUtc;

  /// How often the brand answered partnership requests creators sent it.
  /// Null when too few requests were received to form a rate.
  final MeasuredRateDto? creatorRequestsAnswered;

  /// How often the brand replied in a partnership chat a creator wrote in.
  /// Null when too few chats were opened, or when the messaging record could
  /// not be read — [messagingRecordAvailable] tells the two apart.
  final MeasuredRateDto? creatorChatsReplied;

  /// True when StyleMint holds no partnership rows for this brand at all.
  ///
  /// This is the calm empty state, not a finding: a brand new to the
  /// platform and a brand whose partnerships happen elsewhere both land
  /// here. It is checked across every count so a future count added to the
  /// contract cannot leave a brand looking blank while it has history.
  bool get hasNoRecord => counts.isEmpty;
}

/// Plain counts of recorded rows.
///
/// A zero here is a real zero — StyleMint recorded no such row — unlike a
/// rate, which is null when there is too little to divide by.
class BrandPartnershipCountsDto {
  const BrandPartnershipCountsDto({
    this.partnershipsAllTime = 0,
    this.activeNow = 0,
    this.startedInWindow = 0,
    this.endedInWindow = 0,
    this.endedByBrandInWindow = 0,
    this.endedByCreatorInWindow = 0,
    this.creatorRequestsReceivedInWindow = 0,
    this.creatorRequestsAnsweredInWindow = 0,
    this.creatorChatsOpenedInWindow = 0,
    this.creatorChatsRepliedInWindow = 0,
  });

  factory BrandPartnershipCountsDto.fromJson(Map<String, dynamic> json) =>
      BrandPartnershipCountsDto(
        partnershipsAllTime: _nonNegativeInt(json['partnershipsAllTime']),
        activeNow: _nonNegativeInt(json['activeNow']),
        startedInWindow: _nonNegativeInt(json['startedInWindow']),
        endedInWindow: _nonNegativeInt(json['endedInWindow']),
        endedByBrandInWindow: _nonNegativeInt(json['endedByBrandInWindow']),
        endedByCreatorInWindow:
            _nonNegativeInt(json['endedByCreatorInWindow']),
        creatorRequestsReceivedInWindow:
            _nonNegativeInt(json['creatorRequestsReceivedInWindow']),
        creatorRequestsAnsweredInWindow:
            _nonNegativeInt(json['creatorRequestsAnsweredInWindow']),
        creatorChatsOpenedInWindow:
            _nonNegativeInt(json['creatorChatsOpenedInWindow']),
        creatorChatsRepliedInWindow:
            _nonNegativeInt(json['creatorChatsRepliedInWindow']),
      );

  /// Every partnership row this brand has, in any state, since it joined.
  final int partnershipsAllTime;

  /// Partnerships currently active.
  final int activeNow;

  final int startedInWindow;
  final int endedInWindow;

  /// Of [endedInWindow], the ones the brand ended. Endings an administrator
  /// made are in the total and attributed to neither side, so the two
  /// attributed counts need not sum to it.
  final int endedByBrandInWindow;
  final int endedByCreatorInWindow;

  final int creatorRequestsReceivedInWindow;
  final int creatorRequestsAnsweredInWindow;
  final int creatorChatsOpenedInWindow;
  final int creatorChatsRepliedInWindow;

  bool get isEmpty =>
      partnershipsAllTime == 0 &&
      activeNow == 0 &&
      startedInWindow == 0 &&
      endedInWindow == 0 &&
      endedByBrandInWindow == 0 &&
      endedByCreatorInWindow == 0 &&
      creatorRequestsReceivedInWindow == 0 &&
      creatorRequestsAnsweredInWindow == 0 &&
      creatorChatsOpenedInWindow == 0 &&
      creatorChatsRepliedInWindow == 0;
}

/// A rate that carries its own arithmetic.
///
/// [statement] is the sentence the server wrote for this figure and the one
/// a client shows. It is not a template to rephrase: "82%" without "of 17,
/// in the 180 days to …" invites exactly the misread this contract exists
/// to prevent, and a reworded sentence is how a number becomes a verdict.
class MeasuredRateDto {
  const MeasuredRateDto({
    required this.observed,
    required this.of,
    required this.windowDays,
    this.windowStartUtc,
    this.windowEndUtc,
    this.statement,
  });

  /// Numerator — how many of [of] were observed.
  final int observed;

  /// Denominator. Always at least 1; a rate with nothing to divide by is not
  /// built at all.
  final int of;

  final int windowDays;
  final DateTime? windowStartUtc;
  final DateTime? windowEndUtc;

  /// The server's sentence, rendered verbatim. Null only if the contract
  /// ever omits it, in which case the fraction still stands on its own.
  final String? statement;

  /// Always safe to show beside a percentage-free figure: the numerator and
  /// the denominator together, never one without the other.
  String get fraction => '$observed of $of';

  /// Builds a rate, or returns null when there is nothing honest to build.
  ///
  /// Null is returned when [raw] is not an object, when the denominator is
  /// absent or zero (the server sends a null rate below its minimum, and a
  /// malformed zero must not become a division), or when the numerator falls
  /// outside `0..of`. A caller that gets null renders the counts or a dash —
  /// there is no path here that yields a percentage.
  static MeasuredRateDto? tryFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final of = _nonNegativeInt(raw['of']);
    if (of < 1) return null;
    final observed = _nonNegativeInt(raw['observed']);
    if (observed > of) return null;
    final statement = raw['statement'] as String?;
    return MeasuredRateDto(
      observed: observed,
      of: of,
      windowDays: _nonNegativeInt(raw['windowDays']),
      windowStartUtc: _utc(raw['windowStartUtc']),
      windowEndUtc: _utc(raw['windowEndUtc']),
      statement: (statement == null || statement.trim().isEmpty)
          ? null
          : statement,
    );
  }
}

/// Counts are counts: a string, a double or a missing key all read as "no
/// row recorded" rather than throwing or inventing a figure. Negatives are
/// clamped away because no count on this contract can be below zero.
int _nonNegativeInt(Object? raw) {
  final value = switch (raw) {
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? 0,
    _ => 0,
  };
  return value < 0 ? 0 : value;
}

DateTime? _utc(Object? raw) {
  if (raw is! String) return null;
  return DateTime.tryParse(raw)?.toUtc();
}
