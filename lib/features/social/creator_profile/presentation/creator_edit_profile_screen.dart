import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class CreatorEditProfileScreen extends ConsumerStatefulWidget {
  const CreatorEditProfileScreen({
    this.initialDisplayName = '',
    this.initialHandle = '',
    super.key,
  });

  final String initialDisplayName;
  final String initialHandle;

  @override
  ConsumerState<CreatorEditProfileScreen> createState() =>
      _CreatorEditProfileScreenState();
}

class _CreatorEditProfileScreenState
    extends ConsumerState<CreatorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _tagInputCtrl;

  late List<String> _tags;
  late Set<String> _selectedNiches;

  static const _allNiches = <_NicheOption>[
    _NicheOption('Fashion', 'assets/images/interests/Fashion.svg'),
    _NicheOption('Accessories', 'assets/images/interests/Accessories.svg'),
    _NicheOption('Beauty', 'assets/images/interests/Beauty.svg'),
    _NicheOption('Books', 'assets/images/interests/Books.svg'),
    _NicheOption('Fitness', 'assets/images/interests/Fitness.svg'),
    _NicheOption('Food', 'assets/images/interests/Food.svg'),
    _NicheOption('Footwear', 'assets/images/interests/Footwear.svg'),
    _NicheOption('Gaming', 'assets/images/interests/Gaming.svg'),
    _NicheOption('Home', 'assets/images/interests/Home.svg'),
    _NicheOption('Outdoor', 'assets/images/interests/Outdoor.svg'),
    _NicheOption('Pets', 'assets/images/interests/Pets.svg'),
    _NicheOption('Tech', 'assets/images/interests/Tech.svg'),
    _NicheOption('Travel', 'assets/images/interests/Travel.svg'),
    _NicheOption('Wellness', 'assets/images/interests/Wellness.svg'),
  ];

  @override
  void initState() {
    super.initState();
    _tagInputCtrl = TextEditingController();
    // Controllers initialised with empty strings; seeded in didChangeDependencies
    // once ref is available (initState runs before first build).
    _nicknameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed from provider only on first call.
    if (_nicknameCtrl.text.isEmpty && _bioCtrl.text.isEmpty) {
      final data = ref.read(creatorProfileEditProvider);
      _nicknameCtrl.text = widget.initialDisplayName.isNotEmpty
          ? widget.initialDisplayName
          : data.displayName;
      _bioCtrl.text = data.bio;
      _tags = List<String>.from(data.tags);
      _selectedNiches = Set<String>.from(data.niches);
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
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

  void _toggleNiche(String niche) => setState(() {
        if (_selectedNiches.contains(niche)) {
          _selectedNiches.remove(niche);
        } else {
          _selectedNiches.add(niche);
        }
      });

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(creatorProfileEditProvider.notifier).update(
          displayName: _nicknameCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          tags: List<String>.from(_tags),
          niches: Set<String>.from(_selectedNiches),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
          'Edit Profile Details',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16, vertical: DesignTokens.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nickname ───────────────────────────────────────────────────
              _SectionLabel('Nickname'),
              const SizedBox(height: DesignTokens.s8),
              TextFormField(
                controller: _nicknameCtrl,
                style: _inputStyle,
                textInputAction: TextInputAction.next,
                decoration: DesignTokens.inputDecoration(
                  labelText: 'Display Name',
                  hintText: 'e.g. Danny Perierra',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: DesignTokens.s24),

              // ── Bio ────────────────────────────────────────────────────────
              _SectionLabel('Profile Bio'),
              const SizedBox(height: DesignTokens.s8),
              TextFormField(
                controller: _bioCtrl,
                style: _inputStyle,
                maxLines: 4,
                maxLength: 300,
                textInputAction: TextInputAction.newline,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$currentLength / $maxLength',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ),
                decoration: DesignTokens.inputDecoration(
                  labelText: 'About Me',
                  hintText: 'Tell your audience about yourself...',
                ),
              ),
              const SizedBox(height: DesignTokens.s24),

              // ── Profile Tags ───────────────────────────────────────────────
              _SectionLabel('Profile Tags'),
              const SizedBox(height: DesignTokens.s4),
              const Text(
                'Tags appear on your profile as achievement chips.',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: [
                  ..._tags.map((t) => _TagChip(
                        label: t,
                        onRemove: () => _removeTag(t),
                      )),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagInputCtrl,
                      style: _inputStyle,
                      textInputAction: TextInputAction.done,
                      decoration: DesignTokens.inputDecoration(
                        hintText: 'e.g. Marathon Runner',
                        labelText: 'Add a tag',
                      ),
                      onFieldSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  GestureDetector(
                    onTap: _addTag,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryGreen,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.inputRadius),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: DesignTokens.buttonPrimaryText, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s24),

              // ── Category Niche ─────────────────────────────────────────────
              _SectionLabel('Category Niche'),
              const SizedBox(height: DesignTokens.s4),
              const Text(
                'Select the niches that best describe your content.',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: _allNiches.map((n) {
                  final selected = _selectedNiches.contains(n.label);
                  return _NicheChip(
                    option: n,
                    selected: selected,
                    onTap: () => _toggleNiche(n.label),
                  );
                }).toList(),
              ),
              const SizedBox(height: DesignTokens.s32),

              // ── Save button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _save,
                  style: DesignTokens.primaryButtonStyle(),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s32),
            ],
          ),
        ),
      ),
    );
  }

  static const _inputStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    color: DesignTokens.textWhite,
  );
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _NicheOption {
  const _NicheOption(this.label, this.svgPath);
  final String label;
  final String svgPath;
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textWhite,
        ),
      );
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
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

class _NicheChip extends StatelessWidget {
  const _NicheChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final _NicheOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: selected
            ? DesignTokens.chipDecorationSelected()
            : DesignTokens.chipDecorationDefault(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              option.svgPath,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                selected
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textMuted,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              option.label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
