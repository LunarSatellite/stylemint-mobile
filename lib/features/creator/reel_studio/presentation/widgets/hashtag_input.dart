import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class HashtagInput extends StatefulWidget {
  const HashtagInput({
    super.key,
    required this.initialHashtags,
    required this.onChanged,
  });

  final List<String> initialHashtags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<HashtagInput> createState() => _HashtagInputState();
}

class _HashtagInputState extends State<HashtagInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late List<String> _hashtags;

  @override
  void initState() {
    super.initState();
    _hashtags = List<String>.from(widget.initialHashtags);
  }

  @override
  void didUpdateWidget(HashtagInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHashtags != widget.initialHashtags) {
      _hashtags = List<String>.from(widget.initialHashtags);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _parseText(String text) {
    if (text.contains(' ')) {
      final words = text.split(RegExp(r'[\s,]+'));
      for (final word in words) {
        final trimmed = word.trim().replaceAll('#', '');
        if (trimmed.isNotEmpty && !_hashtags.contains(trimmed)) {
          _hashtags.add(trimmed);
        }
      }
      _controller.clear();
      _onChanged();
    } else if (text.endsWith(' ') || text.endsWith(',')) {
      final trimmed = text.trim().replaceAll('#', '');
      if (trimmed.isNotEmpty && !_hashtags.contains(trimmed)) {
        _hashtags.add(trimmed);
      }
      _controller.clear();
      _onChanged();
    }
  }

  void _onChanged() {
    widget.onChanged(_hashtags);
    setState(() {});
  }

  void _removeHashtag(String tag) {
    _hashtags.remove(tag);
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: DesignTokens.bodyText,
          decoration: InputDecoration(
            hintText: 'Add hashtags (type and press space)',
            hintStyle: DesignTokens.bodyText.copyWith(
              color: DesignTokens.textMuted,
            ),
            prefix: const Text('# '),
            filled: true,
            fillColor: DesignTokens.bgAppBody,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: _parseText,
        ),
        if (_hashtags.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children:
                _hashtags
                    .map(
                      (tag) => InputChip(
                        label: Text('#$tag', style: DesignTokens.smallRegular),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeHashtag(tag),
                        backgroundColor: DesignTokens.chipsSelectedFill,
                        deleteIconColor: DesignTokens.primaryGreen,
                        labelStyle: const TextStyle(
                          color: DesignTokens.primaryGreen,
                        ),
                        side: const BorderSide(color: DesignTokens.chipsSelectedBorder),
                      ),
                    )
                    .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
