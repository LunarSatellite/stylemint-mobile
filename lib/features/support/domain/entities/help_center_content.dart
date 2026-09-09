/// Read-only Help Center models returned by `/v1/help/*`.
///
/// Help content is authored by support staff; the mobile app must not provide
/// local placeholder articles, metrics, or FAQ answers as a fallback.
class HelpCenterCategory {
  const HelpCenterCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.publishedArticleCount,
  });

  final int id;
  final String code;
  final String name;
  final int publishedArticleCount;
}

class HelpArticleSummary {
  const HelpArticleSummary({
    required this.categoryCode,
    required this.slug,
    required this.title,
    required this.publishedUtc,
    required this.updatedUtc,
  });

  final String categoryCode;
  final String slug;
  final String title;
  final DateTime publishedUtc;
  final DateTime updatedUtc;
}

class HelpArticleContent extends HelpArticleSummary {
  const HelpArticleContent({
    required super.categoryCode,
    required super.slug,
    required super.title,
    required super.publishedUtc,
    required super.updatedUtc,
    required this.bodyMarkdown,
  });

  final String bodyMarkdown;
}
