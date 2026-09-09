import 'package:stylemint_mobile_frontend/features/support/domain/entities/help_center_content.dart';

class HelpCenterCategoryDto {
  const HelpCenterCategoryDto({
    required this.id,
    required this.code,
    required this.name,
    required this.publishedArticleCount,
  });

  final int id;
  final String code;
  final String name;
  final int publishedArticleCount;

  factory HelpCenterCategoryDto.fromJson(Map<String, dynamic> json) =>
      HelpCenterCategoryDto(
        id: (json['id'] as num?)?.toInt() ?? 0,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        publishedArticleCount:
            (json['publishedArticleCount'] as num?)?.toInt() ?? 0,
      );

  HelpCenterCategory toDomain() => HelpCenterCategory(
    id: id,
    code: code,
    name: name,
    publishedArticleCount: publishedArticleCount,
  );
}

class HelpArticleSummaryDto {
  const HelpArticleSummaryDto({
    required this.slug,
    required this.title,
    required this.publishedUtc,
    required this.updatedUtc,
  });

  final String slug;
  final String title;
  final DateTime publishedUtc;
  final DateTime updatedUtc;

  factory HelpArticleSummaryDto.fromJson(Map<String, dynamic> json) =>
      HelpArticleSummaryDto(
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        publishedUtc:
            DateTime.tryParse(json['publishedUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        updatedUtc:
            DateTime.tryParse(json['updatedUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  HelpArticleSummary toDomain(String categoryCode) => HelpArticleSummary(
    categoryCode: categoryCode,
    slug: slug,
    title: title,
    publishedUtc: publishedUtc,
    updatedUtc: updatedUtc,
  );
}

class HelpArticleContentDto extends HelpArticleSummaryDto {
  const HelpArticleContentDto({
    required super.slug,
    required super.title,
    required super.publishedUtc,
    required super.updatedUtc,
    required this.bodyMarkdown,
  });

  final String bodyMarkdown;

  factory HelpArticleContentDto.fromJson(Map<String, dynamic> json) =>
      HelpArticleContentDto(
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        publishedUtc:
            DateTime.tryParse(json['publishedUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        updatedUtc:
            DateTime.tryParse(json['updatedUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        bodyMarkdown: json['bodyMarkdown'] as String? ?? '',
      );

  HelpArticleContent toDomain(String categoryCode) => HelpArticleContent(
    categoryCode: categoryCode,
    slug: slug,
    title: title,
    publishedUtc: publishedUtc,
    updatedUtc: updatedUtc,
    bodyMarkdown: bodyMarkdown,
  );
}
