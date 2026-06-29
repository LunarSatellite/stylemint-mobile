import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class EditProfileTagsScreen extends StatefulWidget {
  const EditProfileTagsScreen({required this.initialTags, super.key});

  final List<String> initialTags;

  @override
  State<EditProfileTagsScreen> createState() => _EditProfileTagsScreenState();
}

class _EditProfileTagsScreenState extends State<EditProfileTagsScreen> {
  late List<String> _tags;
  final _tagInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.initialTags);
  }

  @override
  void dispose() {
    _tagInputCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagInputCtrl.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagInputCtrl.clear();
    });
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile Tags',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Tags',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: DesignTokens.s8,
                      runSpacing: DesignTokens.s8,
                      children: _tags
                          .map((t) => _TagChip(
                                label: t,
                                onRemove: () => _removeTag(t),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: DesignTokens.s20),
                  TextField(
                    controller: _tagInputCtrl,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      color: DesignTokens.textWhite,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTag(),
                    decoration: DesignTokens.inputDecoration(
                      hintText: 'Add Tags',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _addTag,
                      icon: const Icon(Icons.add_rounded,
                          size: 18, color: DesignTokens.textWhite),
                      label: const Text(
                        'Add Tag',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.bgAppBody,
                        foregroundColor: DesignTokens.textWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: const BorderSide(
                              color: DesignTokens.borderDefault),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              bottomPadding,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.pop(List<String>.from(_tags)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: DesignTokens.s8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: DesignTokens.textMuted),
          ),
        ],
      ),
    );
  }
}
