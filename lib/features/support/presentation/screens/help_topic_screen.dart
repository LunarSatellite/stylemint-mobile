import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/help_center_data.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class HelpTopicScreen extends StatefulWidget {
  const HelpTopicScreen({required this.topic, super.key});
  final HelpTopic topic;

  @override
  State<HelpTopicScreen> createState() => _HelpTopicScreenState();
}

class _HelpTopicScreenState extends State<HelpTopicScreen> {
  String _query = '';

  List<HelpArticle> get _filtered {
    if (_query.isEmpty) return widget.topic.articles;
    final q = _query.toLowerCase();
    return widget.topic.articles
        .where(
          (a) =>
              a.title.toLowerCase().contains(q) ||
              a.preview.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),
        title: Text(widget.topic.title, style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: [
          Text(
            'View articles related to ${widget.topic.title}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // Search
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
              decoration: InputDecoration(
                hintText: 'Search for keywords..',
                hintStyle: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
                suffixIcon: const Icon(
                  Icons.search,
                  color: DesignTokens.textMuted,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s12,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          if (_filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.s32),
                child: Text(
                  'No articles found.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
            )
          else
            for (final article in _filtered) ...[
              _ArticleCard(
                article: article,
                onTap: () =>
                    context.push(RouteNames.supportArticle, extra: article),
              ),
              const SizedBox(height: DesignTokens.s12),
            ],
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});
  final HelpArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  article.date,
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              article.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                const Icon(
                  Icons.remove_red_eye_outlined,
                  size: 14,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatViews(article.views)} Views',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(width: DesignTokens.s16),
                const Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${article.readMinutes} min read',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatViews(int v) {
    if (v >= 1000)
      return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')},${(v % 1000).toString().padLeft(3, '0')}';
    return v.toString();
  }
}
