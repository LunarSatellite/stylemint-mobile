import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/badge_award.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/notifiers/badges_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class EditProfileBadgesScreen extends ConsumerStatefulWidget {
  const EditProfileBadgesScreen({super.key});

  @override
  ConsumerState<EditProfileBadgesScreen> createState() =>
      _EditProfileBadgesScreenState();
}

class _EditProfileBadgesScreenState
    extends ConsumerState<EditProfileBadgesScreen> {
  static const _maxSlots = 4;

  late Set<String> _selectedIds;
  bool _initialized = false;

  void _initFromBadges(List<BadgeAward> badges) {
    if (_initialized) return;
    _selectedIds = badges
        .where((b) => b.isShowcased)
        .map((b) => b.id)
        .toSet();
    _initialized = true;
  }

  void _toggle(BadgeAward badge) {
    setState(() {
      if (_selectedIds.contains(badge.id)) {
        _selectedIds.remove(badge.id);
      } else if (_selectedIds.length < _maxSlots) {
        _selectedIds.add(badge.id);
      }
    });
  }

  Future<void> _submit(List<BadgeAward> allBadges) async {
    // Preserve showcase order: existing showcased badges keep their slot,
    // newly added ones append at the end.
    final ordered = [
      ...allBadges
          .where((b) => b.isShowcased && _selectedIds.contains(b.id))
          .toList()
        ..sort((a, b) =>
            (a.showcasedOrder ?? 99).compareTo(b.showcasedOrder ?? 99)),
      ...allBadges.where(
          (b) => !b.isShowcased && _selectedIds.contains(b.id)),
    ];

    await ref
        .read(updateShowcaseNotifierProvider.notifier)
        .submit(ordered.map((b) => b.id).toList());

    final state = ref.read(updateShowcaseNotifierProvider);
    state.maybeWhen(
      success: (_) {
        unawaited(ref.read(badgesNotifierProvider.notifier).load());
        if (mounted) context.pop();
      },
      failure: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save badges')),
          );
        }
      },
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgesState = ref.watch(badgesNotifierProvider);
    final updateState = ref.watch(updateShowcaseNotifierProvider);
    final isSubmitting =
        updateState.maybeWhen(submitting: () => true, orElse: () => false);
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
          'Edit Profile Badges',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: badgesState.when(
        initial: () => const SizedBox.shrink(),
        loadInProgress: () => const Center(child: CircularProgressIndicator()),
        loadFailure: (_) => const Center(
          child: Text(
            'Failed to load badges',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        loadSuccess: (badges) {
          _initFromBadges(badges);
          if (badges.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.s16),
                child: Text(
                  'You haven\'t earned any badges yet.\nComplete platform milestones to unlock badges.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    color: DesignTokens.textMuted,
                    height: 1.6,
                  ),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s16,
                  DesignTokens.s16,
                  DesignTokens.s20,
                ),
                child: Text(
                  'Select up to $_maxSlots badges to showcase on your profile',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: DesignTokens.textLight,
                    height: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16),
                  child: GridView.builder(
                    itemCount: badges.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: DesignTokens.s12,
                      crossAxisSpacing: DesignTokens.s12,
                    ),
                    itemBuilder: (context, i) {
                      final badge = badges[i];
                      final isSelected = _selectedIds.contains(badge.id);
                      final atMax = _selectedIds.length >= _maxSlots;
                      return _BadgeTile(
                        badge: badge,
                        isSelected: isSelected,
                        disabled: !isSelected && atMax,
                        onTap: () => _toggle(badge),
                      );
                    },
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
                    onPressed:
                        isSubmitting ? null : () => unawaited(_submit(badges)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryGreen,
                      foregroundColor: DesignTokens.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DesignTokens.buttonPrimaryText,
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

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  final BadgeAward badge;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(
            color: isSelected
                ? DesignTokens.primaryGreen
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.network(
                    badge.badgeIconUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.verified_outlined,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: DesignTokens.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
