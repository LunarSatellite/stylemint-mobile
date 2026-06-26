import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
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
    super.dispose();
  }

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
              _TagsRow(
                tags: _tags,
                onTap: () async {
                  final result = await context.push<List<String>>(
                    RouteNames.creatorProfileTags,
                    extra: List<String>.from(_tags),
                  );
                  if (result != null) setState(() => _tags = result);
                },
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

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags, required this.onTap});
  final List<String> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = tags.isEmpty
        ? 'No tags added'
        : tags.take(3).join(', ') + (tags.length > 3 ? '…' : '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tags.isEmpty ? 'Add tags' : '${tags.length} tag${tags.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: DesignTokens.textLight,
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: DesignTokens.textMuted),
          ],
        ),
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
