import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Wizard step 1 of 3: Personal Information.
///
/// Collects the creator's name, content categories and a free "why join"
/// pitch. Email and phone are not asked again: the account already holds
/// them, verified at sign-up. The name is prefilled from the account's
/// display name.
class CreatorApplyStep1PersonalScreen extends ConsumerStatefulWidget {
  const CreatorApplyStep1PersonalScreen({super.key});

  @override
  ConsumerState<CreatorApplyStep1PersonalScreen> createState() =>
      CreatorApplyStep1PersonalScreenState();
}

class CreatorApplyStep1PersonalScreenState
    extends ConsumerState<CreatorApplyStep1PersonalScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _whyJoinController;

  final Map<String, String> _selectedCategories = {};

  static const int _maxWhyJoin = 500;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(creatorFormProvider);
    _fullNameController = TextEditingController(text: initial.fullName);
    _whyJoinController = TextEditingController(text: initial.whyJoin);
    _selectedCategories.clear();
    final ids = initial.categoryIds;
    final names = initial.categories;
    for (var i = 0; i < ids.length && i < names.length; i++) {
      _selectedCategories[ids.elementAt(i)] = names.elementAt(i);
    }
    // Reapply prefill: resolve category ids to display names when the form
    // only carries ids (loadFromApplication path).
    ref.listenManual(creatorContentCategoriesProvider, (_, next) {
      next.whenData((cats) => _resolveCategoryNames(cats));
    });
    final cached = ref.read(creatorContentCategoriesProvider);
    cached.whenData((cats) {
      _resolveCategoryNames(cats);
      if (mounted) setState(() {});
    });
    ref.listenManual(
      profileNotifierProvider,
      (_, next) => _prefillName(
        next.maybeWhen(loadSuccess: (s) => s.displayName, orElse: () => ''),
      ),
      fireImmediately: true,
    );
    _fullNameController.addListener(_onChanged);
    _whyJoinController.addListener(_onChanged);
  }

  /// Fills the name from the account only while the field is still empty, so
  /// it never overwrites what the creator typed.
  void _prefillName(String displayName) {
    final name = displayName.trim();
    if (name.isEmpty || _fullNameController.text.trim().isNotEmpty) return;
    _fullNameController.text = name;
  }

  void _resolveCategoryNames(List<CreatorContentCategory> cats) {
    final byId = {for (final c in cats) c.id: c.name};
    var changed = false;
    for (final id in _selectedCategories.keys.toList()) {
      final resolved = byId[id];
      if (resolved != null && _selectedCategories[id] != resolved) {
        _selectedCategories[id] = resolved;
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
      ref.read(stepCanProceedProvider.notifier).state = canProceed;
    }
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    ref.read(stepCanProceedProvider.notifier).state = canProceed;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _whyJoinController.dispose();
    super.dispose();
  }

  bool get canProceed {
    return _fullNameController.text.trim().isNotEmpty &&
        _selectedCategories.isNotEmpty;
  }

  Future<bool> save() async {
    final cats = _selectedCategories;
    ref.read(creatorFormProvider.notifier).saveStep1(
          fullName: _fullNameController.text.trim(),
          categories: cats.values.toSet(),
          categoryIds: cats.keys.toSet(),
          whyJoin: _whyJoinController.text.trim(),
        );
    return true;
  }

  void _toggleCategory(String id, String name) {
    setState(() {
      if (_selectedCategories.containsKey(id)) {
        _selectedCategories.remove(id);
      } else {
        _selectedCategories[id] = name;
      }
    });
    ref.read(stepCanProceedProvider.notifier).state = canProceed;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(creatorContentCategoriesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        0,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      children: [
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s6),
              const Text(
                'We use the email and phone already on your account.',
                style: DesignTokens.smallDescription,
              ),
              const SizedBox(height: DesignTokens.s16),
              TextField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.inputFieldData,
                ),
                cursorColor: DesignTokens.primaryGreen,
                decoration: DesignTokens.inputDecoration(
                  labelText: 'Full Name',
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              const Text(
                'Content Categories',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s16),
              categoriesAsync.when(
                data: (categories) => _CategoryChips(
                  categories: categories,
                  selectedIds: _selectedCategories.keys.toSet(),
                  onToggle: _toggleCategory,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.s8),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => Text(
                  'Could not load categories. Pull to retry.',
                  style: DesignTokens.smallDescription,
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              TextField(
                controller: _whyJoinController,
                maxLines: 4,
                maxLength: _maxWhyJoin,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.inputFieldData,
                ),
                cursorColor: DesignTokens.primaryGreen,
                decoration: DesignTokens.inputDecoration(
                  hintText: 'Why do you want to join StyleMint',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Category chips
// ---------------------------------------------------------------------------
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<CreatorContentCategory> categories;
  final Set<String> selectedIds;
  final void Function(String id, String name) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignTokens.s8,
      runSpacing: DesignTokens.s8,
      children: [
        for (final cat in categories)
          _Chip(
            label: cat.name,
            selected: selectedIds.contains(cat.id),
            onTap: () => onToggle(cat.id, cat.name),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s8,
        ),
        decoration: selected
            ? DesignTokens.chipDecorationSelected()
            : DesignTokens.chipDecorationDefault(),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.chipsDefaultText,
          ),
        ),
      ),
    );
  }
}
