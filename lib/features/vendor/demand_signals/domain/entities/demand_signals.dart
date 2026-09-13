/// Voyager "Intent Signal and Demand Sensing" — what shoppers searched for
/// across StyleMint over a recent window, and which searches found nothing.
/// Aggregate counts only. Backend `DemandSignalsDto`.
class DemandSignals {
  const DemandSignals({
    required this.windowDays,
    required this.topSearches,
    required this.unmetSearches,
    this.generatedUtc,
  });

  /// Length of the look-back window the counts cover, in days.
  final int windowDays;
  final DateTime? generatedUtc;

  /// Most searched queries, highest count first.
  final List<DemandQuery> topSearches;

  /// Searches that returned no products — demand nobody is serving yet.
  final List<DemandQuery> unmetSearches;

  bool get isEmpty => topSearches.isEmpty && unmetSearches.isEmpty;
}

class DemandQuery {
  const DemandQuery({required this.query, required this.count});

  final String query;
  final int count;
}
