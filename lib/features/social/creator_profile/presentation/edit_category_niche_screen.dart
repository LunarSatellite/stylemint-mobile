import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class EditCategoryNicheScreen extends ConsumerStatefulWidget {
  const EditCategoryNicheScreen({super.key});

  @override
  ConsumerState<EditCategoryNicheScreen> createState() =>
      _EditCategoryNicheScreenState();
}

class _EditCategoryNicheScreenState
    extends ConsumerState<EditCategoryNicheScreen> {
  String _query = '';
  String _accountId = '';

  // Loaded from backend on init — used to compute diffs on submit.
  Set<String> _originalIds = {};
  String? _originalPrimaryId;

  // Current user selection in this session.
  Set<String> _selectedIds = {};
  String? _primaryId;

  bool _initialized = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _accountId = ref.read(sessionControllerProvider).maybeWhen(
          authenticated: (id) => id,
          orElse: () => '',
        );
  }

  void _initFromLoaded(Map<String, bool> specs) {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _originalIds = Set<String>.from(specs.keys);
          _selectedIds = Set<String>.from(specs.keys);
          _originalPrimaryId =
              specs.entries.where((e) => e.value).map((e) => e.key).firstOrNull;
          _primaryId = _originalPrimaryId;
        });
      }
    });
  }

  List<CategoryOption> _filtered(List<CategoryOption> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.trim().toLowerCase();
    return all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _submit(List<CategoryOption> allCategories) async {
    setState(() => _submitting = true);

    final toAdd = _selectedIds.difference(_originalIds);
    final toRemove = _originalIds.difference(_selectedIds);
    final primaryChanged = _primaryId != null &&
        _primaryId != _originalPrimaryId &&
        _selectedIds.contains(_primaryId!);

    final repo = ref.read(creatorProfileRepositoryProvider);

    try {
      await Future.wait([
        for (final id in toAdd)
          repo.addSpecialization(_accountId, id).then((r) {
            r.fold((e) => throw e, (_) {});
          }),
        for (final id in toRemove)
          repo.removeSpecialization(_accountId, id).then((r) {
            r.fold((e) => throw e, (_) {});
          }),
      ]);

      // Set primary after adds — the newly added category must exist first.
      if (primaryChanged) {
        final r = await repo.setPrimarySpecialization(_accountId, _primaryId!);
        r.fold((e) => throw e, (_) {});
      }

      ref.invalidate(creatorSpecializationIdsProvider(_accountId));
      ref.invalidate(creatorNicheNamesProvider(_accountId));
      ref.invalidate(creatorSpecializationsWithPrimaryProvider(_accountId));
      if (mounted) context.pop();
    } on NetworkExceptions catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NetworkExceptions.getMessage(e))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final specializationsAsync =
        ref.watch(creatorSpecializationsWithPrimaryProvider(_accountId));

    specializationsAsync.whenData(_initFromLoaded);

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
          'Edit Category Niche',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        error: (e, _) => const Center(
          child: Text(
            'Failed to load categories.',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        data: (allCategories) {
          final visible = _filtered(allCategories);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s16,
                  DesignTokens.s16,
                  DesignTokens.s8,
                ),
                child: _SearchBar(
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (_selectedIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: DesignTokens.textMuted),
                      const SizedBox(width: DesignTokens.s4),
                      Expanded(
                        child: Text(
                          'Long press a selected niche to mark it as primary',
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: specializationsAsync.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: DesignTokens.primaryGreen),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s16),
                        child: Wrap(
                          spacing: DesignTokens.s8,
                          runSpacing: DesignTokens.s8,
                          children: visible
                              .map(
                                (cat) => _CategoryChip(
                                  label: cat.name,
                                  isSelected: _selectedIds.contains(cat.id),
                                  isPrimary: _primaryId == cat.id,
                                  onTap: () => setState(() {
                                    if (_selectedIds.contains(cat.id)) {
                                      _selectedIds.remove(cat.id);
                                      if (_primaryId == cat.id) {
                                        _primaryId = null;
                                      }
                                    } else {
                                      _selectedIds.add(cat.id);
                                    }
                                  }),
                                  onLongPress: _selectedIds.contains(cat.id)
                                      ? () => setState(
                                          () => _primaryId = cat.id)
                                      : null,
                                ),
                              )
                              .toList(),
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
                    onPressed: _submitting
                        ? null
                        : () => unawaited(_submit(allCategories)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryGreen,
                      foregroundColor: DesignTokens.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DesignTokens.textWhite,
                            ),
                          )
                        : const Row(
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
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          color: DesignTokens.textWhite,
        ),
        decoration: const InputDecoration(
          hintText: 'Search Category',
          hintStyle: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.textMuted,
          ),
          suffixIcon: Icon(Icons.search_rounded,
              size: 20, color: DesignTokens.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isPrimary = false,
    this.onLongPress,
  });

  final String label;
  final bool isSelected;
  final bool isPrimary;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DesignTokens.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
            width: isPrimary ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPrimary) ...[
              const Icon(Icons.star_rounded,
                  size: 13, color: DesignTokens.secondaryYellow),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: DesignTokens.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
