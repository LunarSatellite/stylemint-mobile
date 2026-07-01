class ReelStatistics {
  const ReelStatistics({
    required this.conversionRate,
    required this.clickThroughRate,
    required this.completionRate,
    required this.uniqueViewersEstimate,
  });

  final double conversionRate;
  final double clickThroughRate;
  final double completionRate;
  final int uniqueViewersEstimate;
}
