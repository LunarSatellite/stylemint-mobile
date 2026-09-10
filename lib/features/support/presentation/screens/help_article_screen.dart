import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/help_center_content.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/help_center_data.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class HelpArticleScreen extends ConsumerWidget {
  const HelpArticleScreen({required this.article, super.key});
  final HelpArticleSummary article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(
      helpArticleProvider((
        categoryCode: article.categoryCode,
        slug: article.slug,
      )),
    );
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
      ),
      body: content.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        error: (_, _) => _ArticleError(
          onRetry: () => ref.invalidate(
            helpArticleProvider((
              categoryCode: article.categoryCode,
              slug: article.slug,
            )),
          ),
        ),
        data: (loaded) => ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            Text(loaded.title, style: DesignTokens.titleLarge),
            const SizedBox(height: DesignTokens.s12),
            Text(
              'Last updated ${DateFormat.yMMMd().format(loaded.updatedUtc.toLocal())}',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s24),
            _MarkdownBody(markdown: loaded.bodyMarkdown),
            const SizedBox(height: DesignTokens.s32),
            Text(
              'Still need help?',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Container(
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              child: Column(
                children: [
                  for (final option in kContactOptions)
                    ListTile(
                      onTap: () => context.push(RouteNames.supportContact),
                      leading: Icon(option.icon, color: DesignTokens.textWhite),
                      title: Text(
                        option.title,
                        style: DesignTokens.mediumSemibold,
                      ),
                      subtitle: Text(option.subtitle),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight Markdown presentation without a second renderer dependency.
/// It keeps staff-authored headings and list items readable while preserving
/// the original backend text verbatim for all other paragraph content.
class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({required this.markdown});
  final String markdown;

  @override
  Widget build(BuildContext context) {
    final lines = markdown.split(RegExp(r'\r?\n'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          if (line.trim().isEmpty)
            const SizedBox(height: DesignTokens.s8)
          else if (line.startsWith('#'))
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s12),
              child: Text(
                line.replaceFirst(RegExp(r'^#+\s*'), ''),
                style: DesignTokens.mediumSemibold,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: RichText(
                text: _inlineSpans(
                  // Only a "- " or "* " marker (with a trailing space) is a
                  // bullet — a bare leading "**" is inline bold emphasis and
                  // must be left for _inlineSpans to parse.
                  line.replaceFirst(RegExp(r'^[-*]\s+'), '• '),
                  DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                    height: 1.6,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  /// Splits a line on `**bold**` markers into plain/bold [TextSpan]s.
  TextSpan _inlineSpans(String line, TextStyle baseStyle) {
    final boldPattern = RegExp(r'\*\*(.+?)\*\*');
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in boldPattern.allMatches(line)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: line.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      cursor = match.end;
    }
    if (cursor < line.length) {
      spans.add(TextSpan(text: line.substring(cursor)));
    }
    return TextSpan(style: baseStyle, children: spans);
  }
}

class _ArticleError extends StatelessWidget {
  const _ArticleError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Could not load this article.'),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
