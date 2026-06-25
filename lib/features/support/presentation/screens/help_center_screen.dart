import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/help_center_data.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _query = '';
  int? _expandedFaq;

  List<HelpTopic> get _filteredTopics {
    if (_query.isEmpty) return kHelpTopics;
    final q = _query.toLowerCase();
    return kHelpTopics
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.subtitle.toLowerCase().contains(q) ||
            t.articles.any((a) => a.title.toLowerCase().contains(q)))
        .toList();
  }

  List<FaqItem> get _filteredFaqs {
    if (_query.isEmpty) return kFaqs;
    final q = _query.toLowerCase();
    return kFaqs
        .where((f) =>
            f.question.toLowerCase().contains(q) ||
            f.answer.toLowerCase().contains(q))
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
        title: const Text('Help Center', style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: [
          // Subtitle
          Text(
            'How can we help you?',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s16),

          // Search
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: TextField(
              onChanged: (v) => setState(() {
                _query = v;
                _expandedFaq = null;
              }),
              style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite),
              decoration: InputDecoration(
                hintText: 'Search for help on any topic',
                hintStyle: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textMuted),
                suffixIcon: const Icon(Icons.search, color: DesignTokens.textMuted, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s12,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),

          // ── Popular Topics ─────────────────────────────────────────────
          Text(
            'Popular Topics',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s8),
          _SectionCard(
            children: [
              for (var i = 0; i < _filteredTopics.length; i++) ...[
                _TopicTile(
                  topic: _filteredTopics[i],
                  onTap: () => context.push(
                    RouteNames.supportTopic,
                    extra: _filteredTopics[i],
                  ),
                ),
              ],
              if (_filteredTopics.isEmpty) _emptyResult('No topics match your search.'),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),

          // ── FAQs ───────────────────────────────────────────────────────
          Text(
            "FAQ's",
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s8),
          _SectionCard(
            children: [
              for (var i = 0; i < _filteredFaqs.length; i++) ...[
                _FaqTile(
                  item: _filteredFaqs[i],
                  isExpanded: _expandedFaq == i,
                  onTap: () => setState(() {
                    _expandedFaq = _expandedFaq == i ? null : i;
                  }),
                ),
              ],
              if (_filteredFaqs.isEmpty) _emptyResult('No FAQs match your search.'),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),

          // ── Still need help? ───────────────────────────────────────────
          Text(
            'Still need help?',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s8),
          _SectionCard(
            children: [
              for (final opt in kContactOptions) _ContactTile(option: opt),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        color: DesignTokens.borderDefault,
        indent: DesignTokens.s16,
        endIndent: DesignTokens.s16,
      );

  Widget _emptyResult(String msg) => Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Text(msg,
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted)),
      );
}

// ── Section card wrapper ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(children: children),
    );
  }
}

// ── Topic tile ────────────────────────────────────────────────────────────────

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.onTap});
  final HelpTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              child: Icon(topic.icon, color: DesignTokens.textWhite.withValues(alpha: 0.8), size: 20),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title,
                      style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.textWhite)),
                  const SizedBox(height: 2),
                  Text(topic.subtitle,
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

// ── FAQ tile ──────────────────────────────────────────────────────────────────

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });
  final FaqItem item;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: DesignTokens.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              0,
              DesignTokens.s16,
              DesignTokens.s16,
            ),
            child: Text(
              item.answer,
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
            ),
          ),
      ],
    );
  }
}

// ── Contact tile ──────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.option});
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
              child: Icon(option.icon, color: DesignTokens.textWhite.withValues(alpha: 0.8), size: 20),
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
