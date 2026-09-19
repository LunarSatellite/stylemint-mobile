import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/caption_standard_sheet.dart';
import 'package:stylemint_mobile_frontend/shared/domain/reel_caption/reel_caption.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_caption_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Structured caption editor for the StyleMint Reel Caption Standard, used
/// on the Review Reel screen (before "Share Reel") and in the creator reel
/// details "Edit caption" sheet.
///
/// Creators only write the hook, pick up to 3 topic tags and set the AI
/// switch; product lines, the CTA and the hashtag order come from
/// [ReelCaption.compose]. Every change is reported through [onChanged] so the
/// host can enable its submit button via [ReelCaptionDraft.canSubmit] and
/// send [ReelCaptionDraft.caption].
class CaptionEditor extends StatefulWidget {
  const CaptionEditor({
    required this.initialDraft,
    required this.onChanged,
    super.key,
  });

  static const String title = 'Caption';
  static const String hookHint = 'Write a hook (20–70 characters)';
  static const String tagHint = 'Add a topic tag';
  static const String addTagLabel = 'Add tag';
  static const String aiSwitchLabel = 'AI-generated content';
  static const String infoTooltip = 'Caption standard';

  static const Key hookFieldKey = ValueKey('caption_editor_hook');
  static const Key tagFieldKey = ValueKey('caption_editor_tag_input');
  static const Key addTagButtonKey = ValueKey('caption_editor_add_tag');
  static const Key aiSwitchKey = ValueKey('caption_editor_ai_switch');
  static const Key infoButtonKey = ValueKey('caption_editor_info');
  static const Key previewKey = ValueKey('caption_editor_preview');

  final ReelCaptionDraft initialDraft;
  final ValueChanged<ReelCaptionDraft> onChanged;

  @override
  State<CaptionEditor> createState() => _CaptionEditorState();
}

class _CaptionEditorState extends State<CaptionEditor> {
  late final TextEditingController _hookController = TextEditingController(
    text: widget.initialDraft.hook,
  );
  final TextEditingController _tagController = TextEditingController();
  late ReelCaptionDraft _draft = widget.initialDraft;

  @override
  void dispose() {
    _hookController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _emit(ReelCaptionDraft next) {
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  void _addTag() {
    final tag = ReelCaption.normalizeTopicTag(_tagController.text);
    _tagController.clear();
    if (tag == null) return;
    // #AIgenerated is a disclosure, not a topic — route it to the switch.
    if (tag.toLowerCase() == ReelCaption.aiTag.toLowerCase()) {
      _emit(_draft.copyWith(aiGenerated: true));
      return;
    }
    _emit(
      _draft.copyWith(
        topicTags: ReelCaption.normalizeTopicTags([..._draft.topicTags, tag]),
      ),
    );
  }

  void _removeTag(String tag) {
    _emit(
      _draft.copyWith(
        topicTags: [
          for (final t in _draft.topicTags)
            if (t != tag) t,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caption = _draft.caption;
    final length = ReelCaption.length(caption);
    final issues = _draft.issues;
    final canAddTag = _draft.topicTags.length < ReelCaption.maxTopicTags;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Flexible: the title, the info button and the counter together
              // overflow this row at 320dp with a 1.3 text scale.
              const Flexible(
                child: Text(
                  CaptionEditor.title,
                  style: DesignTokens.mediumSemibold,
                ),
              ),
              const SizedBox(width: DesignTokens.s4),
              IconButton(
                key: CaptionEditor.infoButtonKey,
                tooltip: CaptionEditor.infoTooltip,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: DesignTokens.textMuted,
                ),
                onPressed: () => showCaptionStandardSheet(context),
              ),
              const Spacer(),
              Text(
                '$length/${ReelCaption.maxLength}',
                style: DesignTokens.smallRegular.copyWith(
                  color: length > ReelCaption.maxLength
                      ? DesignTokens.colorError
                      : DesignTokens.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          const _Label('Hook'),
          TextField(
            key: CaptionEditor.hookFieldKey,
            controller: _hookController,
            maxLength: ReelCaption.hookMaxLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textWhite,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: CaptionEditor.hookHint,
            ).copyWith(counterStyle: DesignTokens.smallRegular),
            onChanged: (value) => _emit(_draft.copyWith(hook: value)),
          ),
          const SizedBox(height: DesignTokens.s4),
          const _Label('Topic tags (up to 3)'),
          if (_draft.topicTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: [
                  for (final tag in _draft.topicTags)
                    _TagChip(tag: tag, onRemove: () => _removeTag(tag)),
                ],
              ),
            ),
          if (canAddTag)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: CaptionEditor.tagFieldKey,
                    controller: _tagController,
                    textInputAction: TextInputAction.done,
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                    decoration: DesignTokens.inputDecoration(
                      hintText: CaptionEditor.tagHint,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: DesignTokens.s12),
                        child: Text('#', style: ReelCaptionText.hashtagStyle),
                      ),
                    ).copyWith(
                      prefixIconConstraints: const BoxConstraints(minWidth: 24),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                TextButton(
                  key: CaptionEditor.addTagButtonKey,
                  onPressed: _addTag,
                  style: DesignTokens.textButtonStyle(),
                  child: const Text(CaptionEditor.addTagLabel),
                ),
              ],
            ),
          const SizedBox(height: DesignTokens.s8),
          // Own Material so the tile's ink isn't hidden by the card's
          // decorated background.
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              key: CaptionEditor.aiSwitchKey,
              contentPadding: EdgeInsets.zero,
              value: _draft.aiGenerated,
              activeTrackColor: DesignTokens.primaryGreen,
              title: const Text(
                CaptionEditor.aiSwitchLabel,
                style: DesignTokens.mediumSemibold,
              ),
              subtitle: const Text(
                'Adds #AIgenerated. Required for AI-generated or synthetic reels.',
                style: DesignTokens.smallRegular,
              ),
              onChanged: (value) => _emit(_draft.copyWith(aiGenerated: value)),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          const _Label('Preview'),
          Container(
            key: CaptionEditor.previewKey,
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.baseBlack,
              borderRadius: BorderRadius.circular(DesignTokens.s12),
              border: Border.all(color: DesignTokens.borderDefault),
            ),
            child: ReelCaptionText(caption: caption, expandable: false),
          ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            for (final issue in issues) _IssueRow(issue: issue),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s6),
      child: Text(
        text,
        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag, required this.onRemove});

  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: DesignTokens.s12,
        right: DesignTokens.s4,
        top: DesignTokens.s4,
        bottom: DesignTokens.s4,
      ),
      decoration: DesignTokens.chipDecorationSelected(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
          IconButton(
            key: ValueKey('caption_editor_remove_tag_$tag'),
            tooltip: 'Remove #$tag',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(
              Icons.close,
              size: 14,
              color: DesignTokens.textLight,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});

  final CaptionIssue issue;

  @override
  Widget build(BuildContext context) {
    final color = issue.blocking
        ? DesignTokens.colorError
        : DesignTokens.warning500;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            issue.blocking ? Icons.error_outline : Icons.info_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: DesignTokens.s6),
          Expanded(
            child: Text(
              issue.message,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
