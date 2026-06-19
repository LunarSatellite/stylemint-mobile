import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/interests_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PickInterestsScreen extends ConsumerStatefulWidget {
  const PickInterestsScreen({super.key});

  @override
  ConsumerState<PickInterestsScreen> createState() =>
      _PickInterestsScreenState();
}

class _PickInterestsScreenState extends ConsumerState<PickInterestsScreen> {
  static const int _minPicks = 3;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (!mounted) return;
    final accountId = ref.read(sessionControllerProvider).maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    if (accountId == null) return;
    final needsLoad = ref.read(interestsProvider).maybeWhen(
      initial: () => true,
      loadFailure: (_) => true,
      orElse: () => false,
    );
    if (needsLoad) {
      ref.read(interestsProvider.notifier).load(accountId: accountId);
    }
  }

  void _toggleInterest(String categoryId, bool isSelected) {
    final accountId = ref.read(sessionControllerProvider).maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    if (accountId == null) return;
    ref.read(interestsProvider.notifier).toggleInterest(
      accountId: accountId,
      categoryId: categoryId,
      isSelected: isSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safety net for the edge case where session arrives after initState.
    ref.listen(sessionControllerProvider, (_, next) {
      next.maybeWhen(authenticated: (_) => _load(), orElse: () {});
    });

    final state = ref.watch(interestsProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (available, selectedIds) {
            final filtered = _query.isEmpty
                ? available
                : available
                    .where((i) =>
                        i.name.toLowerCase().contains(_query.toLowerCase()))
                    .toList();

            final progress =
                (selectedIds.length / _minPicks).clamp(0.0, 1.0).toDouble();
            final canProceed = selectedIds.length >= _minPicks;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pick Your Interests',
                          style: DesignTokens.titleMedium),
                      const SizedBox(height: DesignTokens.s8),
                      Text(
                        "Select at least $_minPicks interests — we'll use it to personalize your feed",
                        style: DesignTokens.bodyText,
                      ),
                      const SizedBox(height: DesignTokens.s24),
                      Text(
                        '${selectedIds.length}/$_minPicks Picked',
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.textLight),
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: DesignTokens.bgAppBodyLight,
                          valueColor: const AlwaysStoppedAnimation(
                              DesignTokens.primaryGreen),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s16),
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: DesignTokens.inputFieldData,
                        ),
                        cursorColor: DesignTokens.primaryGreen,
                        decoration: DesignTokens.inputDecoration(
                          hintText: 'Search Interest',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF71717B), size: 16),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s24),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s16),
                    crossAxisCount: 4,
                    crossAxisSpacing: DesignTokens.s12,
                    mainAxisSpacing: DesignTokens.s12,
                    childAspectRatio: 83.5 / 84,
                    children: filtered.map((interest) {
                      final selected =
                          selectedIds.contains(interest.categoryId);
                      return _RadioCard(
                        label: interest.name,
                        code: interest.code,
                        selected: selected,
                        onTap: () =>
                            _toggleInterest(interest.categoryId, selected),
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: DesignTokens.bgAppFoundation,
                    border: Border(
                      top: BorderSide(
                          color: DesignTokens.borderDefault, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(DesignTokens.s16,
                      DesignTokens.s24, DesignTokens.s16, DesignTokens.s24),
                  child: Opacity(
                    opacity: canProceed ? 1 : 0.5,
                    child: Material(
                      color: DesignTokens.primaryGreen,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.buttonRadius),
                      child: InkWell(
                        onTap: canProceed
                            ? () => context.go(RouteNames.followCreators)
                            : null,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.s32,
                              vertical: DesignTokens.s16),
                          child: Center(
                            child: Text(
                              'Proceed',
                              style: DesignTokens.oneLinerSemibold.copyWith(
                                  color: DesignTokens.buttonPrimaryText),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loadFailure: (_) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: DesignTokens.colorError, size: 48),
                const SizedBox(height: DesignTokens.s16),
                Text('Failed to load interests', style: DesignTokens.bodyText),
                const SizedBox(height: DesignTokens.s16),
                GestureDetector(
                  onTap: _load,
                  child: Text('Retry',
                      style: TextStyle(color: DesignTokens.primaryGreen)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
      child: CircularProgressIndicator(color: DesignTokens.primaryGreen));
}

// ---------------------------------------------------------------------------
// Asset helpers — look up by code first (stable), then by nameEn (display).
// ---------------------------------------------------------------------------

String? _svgForCode(String? code) {
  if (code == null) return null;
  const map = <String, String>{
    'fashion': 'assets/images/interests/Fashion.svg',
    'beauty': 'assets/images/interests/Beauty.svg',
    'footwear': 'assets/images/interests/Footwear.svg',
    'accessories': 'assets/images/interests/Accessories.svg',
    'fitness': 'assets/images/interests/Fitness.svg',
    'sports_fitness': 'assets/images/interests/Fitness.svg',
    'gaming': 'assets/images/interests/Gaming.svg',
    'tech': 'assets/images/interests/Tech.svg',
    'technology': 'assets/images/interests/Tech.svg',
    'food': 'assets/images/interests/Food.svg',
    'food_dining': 'assets/images/interests/Food.svg',
    'outdoor': 'assets/images/interests/Outdoor.svg',
    'outdoor_adventure': 'assets/images/interests/Outdoor.svg',
    'pets': 'assets/images/interests/Pets.svg',
    'books': 'assets/images/interests/Books.svg',
    'travel': 'assets/images/interests/Travel.svg',
    'wellness': 'assets/images/interests/Wellness.svg',
    'football': 'assets/images/interests/Football.svg',
    'sports': 'assets/images/interests/Football.svg',
    'home': 'assets/images/interests/Home.svg',
    'home_living': 'assets/images/interests/Home.svg',
  };
  return map[code.toLowerCase()];
}

String? _svgForName(String name) {
  const map = <String, String>{
    'fashion': 'assets/images/interests/Fashion.svg',
    'beauty': 'assets/images/interests/Beauty.svg',
    'footwear': 'assets/images/interests/Footwear.svg',
    'accessories': 'assets/images/interests/Accessories.svg',
    'fitness': 'assets/images/interests/Fitness.svg',
    'sports & fitness': 'assets/images/interests/Fitness.svg',
    'gaming': 'assets/images/interests/Gaming.svg',
    'tech': 'assets/images/interests/Tech.svg',
    'technology': 'assets/images/interests/Tech.svg',
    'food': 'assets/images/interests/Food.svg',
    'food & dining': 'assets/images/interests/Food.svg',
    'outdoor': 'assets/images/interests/Outdoor.svg',
    'outdoor & adventure': 'assets/images/interests/Outdoor.svg',
    'pets': 'assets/images/interests/Pets.svg',
    'books': 'assets/images/interests/Books.svg',
    'travel': 'assets/images/interests/Travel.svg',
    'wellness': 'assets/images/interests/Wellness.svg',
    'football': 'assets/images/interests/Football.svg',
    'sports': 'assets/images/interests/Football.svg',
    'home': 'assets/images/interests/Home.svg',
    'home & living': 'assets/images/interests/Home.svg',
    'home_living': 'assets/images/interests/Home.svg',
  };
  return map[name.toLowerCase()];
}

IconData _iconForCode(String? code) {
  switch (code?.toLowerCase()) {
    case 'fashion':
      return Icons.checkroom;
    case 'beauty':
      return Icons.brush;
    case 'footwear':
      return Icons.snowshoeing;
    case 'accessories':
      return Icons.watch;
    case 'fitness':
    case 'sports_fitness':
      return Icons.fitness_center;
    case 'gaming':
      return Icons.sports_esports;
    case 'tech':
    case 'technology':
      return Icons.devices;
    case 'food':
    case 'food_dining':
      return Icons.restaurant;
    case 'outdoor':
    case 'outdoor_adventure':
      return Icons.terrain;
    case 'pets':
      return Icons.pets;
    case 'books':
      return Icons.menu_book;
    case 'travel':
      return Icons.flight;
    case 'wellness':
      return Icons.spa;
    case 'football':
    case 'sports':
      return Icons.sports_soccer;
    case 'home':
    case 'home_living':
      return Icons.chair;
    case 'music':
      return Icons.music_note;
    case 'art':
      return Icons.palette;
    case 'movies':
      return Icons.movie;
    case 'photography':
      return Icons.camera_alt;
    case 'lifestyle':
      return Icons.self_improvement;
    default:
      return Icons.category;
  }
}

IconData _iconForName(String name) {
  switch (name.toLowerCase()) {
    case 'fashion':
      return Icons.checkroom;
    case 'beauty':
      return Icons.brush;
    case 'footwear':
      return Icons.snowshoeing;
    case 'accessories':
      return Icons.watch;
    case 'fitness':
    case 'sports & fitness':
      return Icons.fitness_center;
    case 'gaming':
      return Icons.sports_esports;
    case 'tech':
    case 'technology':
      return Icons.devices;
    case 'food':
    case 'food & dining':
      return Icons.restaurant;
    case 'outdoor':
    case 'outdoor & adventure':
      return Icons.terrain;
    case 'pets':
      return Icons.pets;
    case 'books':
      return Icons.menu_book;
    case 'travel':
      return Icons.flight;
    case 'wellness':
      return Icons.spa;
    case 'football':
    case 'sports':
      return Icons.sports_soccer;
    case 'home':
    case 'home & living':
    case 'home_living':
      return Icons.chair;
    case 'music':
      return Icons.music_note;
    case 'art':
      return Icons.palette;
    case 'movies':
      return Icons.movie;
    case 'photography':
      return Icons.camera_alt;
    case 'lifestyle':
      return Icons.self_improvement;
    default:
      return Icons.category;
  }
}

// ---------------------------------------------------------------------------
// Glassmorphic interest chip — Figma "Radio Card"
// ---------------------------------------------------------------------------

class _RadioCard extends StatelessWidget {
  final String label;
  final String? code;
  final bool selected;
  final VoidCallback onTap;

  const _RadioCard({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve SVG: try code first, fall back to nameEn.
    final svgAsset = _svgForCode(code) ?? _svgForName(label);
    // Resolve icon: try code first, fall back to nameEn.
    final icon = code != null ? _iconForCode(code) : _iconForName(label);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Card — SizedBox.expand ensures every cell fills the grid slot ─
        SizedBox.expand(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.7, sigmaY: 5.7),
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.s12),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.primaryGreen.withOpacity(0.12)
                        : DesignTokens.radioCardFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.radioCardBorder,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (svgAsset != null)
                        SvgPicture.asset(
                          svgAsset,
                          width: 32,
                          height: 32,
                          // No colorFilter — logo keeps its original colours
                          // regardless of selection state.
                        )
                      else
                        Icon(
                          icon,
                          size: 32,
                          color: DesignTokens.radioCardTitle,
                        ),
                      const SizedBox(height: DesignTokens.s4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.radioCardTitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Selection badge — white circle with black check, top-right ───
        if (selected)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }
}
