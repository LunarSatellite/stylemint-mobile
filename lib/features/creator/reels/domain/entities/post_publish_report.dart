class PostPublishInsight {
  const PostPublishInsight({
    required this.category,
    required this.body,
  });

  final String category;
  final String body;
}

class PostPublishReport {
  const PostPublishReport({
    required this.reelId,
    required this.generatedAtUtc,
    required this.performanceScore,
    required this.headline,
    required this.insights,
    this.isAvailable = true,
  });

  final String reelId;
  final DateTime generatedAtUtc;
  final double performanceScore;
  final String headline;
  final List<PostPublishInsight> insights;
  final bool isAvailable;
}
