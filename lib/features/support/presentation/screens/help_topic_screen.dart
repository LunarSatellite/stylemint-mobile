import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/help_center_content.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class HelpTopicScreen extends ConsumerStatefulWidget {
  const HelpTopicScreen({required this.category, super.key});
  final HelpCenterCategory category;

  @override
  ConsumerState<HelpTopicScreen> createState() => _HelpTopicScreenState();
}

class _HelpTopicScreenState extends ConsumerState<HelpTopicScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final articles = ref.watch(helpArticlesProvider(widget.category.code));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.category.name,
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              style: DesignTokens.mediumRegular,
              decoration: InputDecoration(
                hintText: 'Search articles',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: DesignTokens.bgAppBody,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: articles.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
              error: (_, _) => _ErrorState(
                onRetry: () => ref.invalidate(
                  helpArticlesProvider(widget.category.code),
                ),
              ),
              data: (items) {
                final query = _query.trim().toLowerCase();
                final visible = query.isEmpty
                    ? items
                    : items
                          .where(
                            (article) =>
                                article.title.toLowerCase().contains(query),
                          )
                          .toList(growable: false);
                if (visible.isEmpty) {
                  return const Center(
                    child: Text('No published articles found.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DesignTokens.s12),
                  itemBuilder: (_, index) => _ArticleCard(
                    article: visible[index],
                    onTap: () => context.push(
                      RouteNames.supportArticle,
                      extra: visible[index],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});
  final HelpArticleSummary article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    child: Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(article.title, style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Updated ${DateFormat.yMMMd().format(article.updatedUtc.toLocal())}',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Could not load articles.'),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
