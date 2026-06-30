/// A KPI tile carrying the current window value, prior window value, and the
/// window-over-window delta percentage.
/// [deltaPercent] is null when the prior window value was zero.
class KpiTile<T> {
  const KpiTile({
    required this.current,
    this.previous,
    this.deltaPercent,
  });

  final T current;
  final T? previous;
  final double? deltaPercent;
}
