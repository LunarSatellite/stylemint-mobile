class AnalyticsWindow {
  const AnalyticsWindow({
    required this.fromUtc,
    required this.toUtc,
    required this.durationDays,
  });

  final DateTime fromUtc;
  final DateTime toUtc;
  final int durationDays;
}
