import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/help_center_data.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class HelpArticleScreen extends StatefulWidget {
  const HelpArticleScreen({required this.article, super.key});
  final HelpArticle article;

  @override
  State<HelpArticleScreen> createState() => _HelpArticleScreenState();
}

class _HelpArticleScreenState extends State<HelpArticleScreen> {
  bool? _helpful; // null = no vote, true = liked, false = no

  List<HelpArticle> get _related {
    final sameTopicArticles = kHelpTopics
        .firstWhere((t) => t.id == widget.article.topicId,
            orElse: () => kHelpTopics.first)
        .articles
        .where((a) => a.id != widget.article.id)
        .take(2)
        .toList();
    return sameTopicArticles;
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: [
          // Title
          Text(article.title, style: DesignTokens.titleLarge),
          const SizedBox(height: DesignTokens.s12),

          // Meta row
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: DesignTokens.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Last Updated: ${article.date}',
                  style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          Row(
            children: [
              const Icon(Icons.remove_red_eye_outlined,
                  size: 14, color: DesignTokens.textMuted),
              const SizedBox(width: 4),
              Text(
                '${article.views.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} Views',
                style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
              ),
              const SizedBox(width: DesignTokens.s16),
              const Icon(Icons.access_time_outlined,
                  size: 14, color: DesignTokens.textMuted),
              const SizedBox(width: 4),
              Text(
                '${article.readMinutes} min read',
                style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s20),

          // Content blocks
          for (final block in article.blocks) _buildBlock(block),

          const SizedBox(height: DesignTokens.s24),

          // Was this article helpful?
          Text(
            'Was this article helpful?',
            style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.textWhite),
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              Expanded(
                child: _HelpfulButton(
                  icon: Icons.thumb_up_outlined,
                  label: 'Liked (234)',
                  isSelected: _helpful == true,
                  onTap: () => setState(() => _helpful = _helpful == true ? null : true),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: _HelpfulButton(
                  icon: Icons.thumb_down_outlined,
                  label: 'No (88)',
                  isSelected: _helpful == false,
                  onTap: () => setState(() => _helpful = _helpful == false ? null : false),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),

          // Related articles
          if (_related.isNotEmpty) ...[
            Text(
              'Related Articles',
              style: DesignTokens.sectionInnerTitle.copyWith(color: DesignTokens.textWhite),
            ),
            const SizedBox(height: DesignTokens.s12),
            for (final rel in _related) ...[
              _RelatedArticleCard(
                article: rel,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HelpArticleScreen(article: rel),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
            ],
            const SizedBox(height: DesignTokens.s24),
          ],

          // Still need help?
          Text(
            'Still need help?',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s8),
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Column(
              children: [
                for (var i = 0; i < kContactOptions.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      color: DesignTokens.borderDefault,
                      indent: DesignTokens.s16,
                      endIndent: DesignTokens.s16,
                    ),
                  _ContactRow(option: kContactOptions[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
        ],
      ),
    );
  }

  Widget _buildBlock(HelpBlock block) {
    switch (block.type) {
      case HelpBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s16),
          child: Text(
            block.text ?? '',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
              height: 1.6,
            ),
          ),
        );

      case HelpBlockType.sectionHeader:
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s12, top: DesignTokens.s4),
          child: Text(
            block.text ?? '',
            style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.textWhite),
          ),
        );

      case HelpBlockType.iconList:
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s16),
          child: Column(
            children: [
              for (var i = 0; i < (block.items?.length ?? 0); i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppBodyLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        child: Text(
                          block.items![i],
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );

      case HelpBlockType.checkList:
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s16),
          child: Column(
            children: [
              for (final item in block.items ?? <String>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: DesignTokens.primaryGreen),
                      const SizedBox(width: DesignTokens.s8),
                      Expanded(
                        child: Text(
                          item,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
    }
  }
}

// ── Helpful button ────────────────────────────────────────────────────────────

class _HelpfulButton extends StatelessWidget {
  const _HelpfulButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.primaryGreen.withValues(alpha: 0.15)
              : DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: isSelected
              ? Border.all(color: DesignTokens.primaryGreen, width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? DesignTokens.primaryGreen : DesignTokens.textLight,
            ),
            const SizedBox(width: DesignTokens.s8),
            Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: isSelected ? DesignTokens.primaryGreen : DesignTokens.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Related article card ──────────────────────────────────────────────────────

class _RelatedArticleCard extends StatelessWidget {
  const _RelatedArticleCard({required this.article, required this.onTap});
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
              style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.textWhite),
            ),
            const SizedBox(height: DesignTokens.s8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: DesignTokens.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    article.date,
                    style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              article.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
            ),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined,
                    size: 14, color: DesignTokens.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${article.views.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} Views',
                  style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
                ),
                const SizedBox(width: DesignTokens.s16),
                const Icon(Icons.access_time_outlined,
                    size: 14, color: DesignTokens.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${article.readMinutes} min read',
                  style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact row ───────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.option});
  final ContactOption option;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              child: Icon(option.icon, color: DesignTokens.textWhite, size: 20),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title,
                      style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.textWhite)),
                  const SizedBox(height: 2),
                  Text(option.subtitle,
                      style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: DesignTokens.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
