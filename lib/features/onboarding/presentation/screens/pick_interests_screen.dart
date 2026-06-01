import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/interests_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Pick Your Interests — pixel-matched to Figma frame `9615:45821`.
///
/// API-backed: loads available interests from `GET /v1/public/interests` and
/// current user interests from `GET /v1/accounts/{id}/interests`. Toggles
/// persist via POST/DELETE immediately.
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
    final accountId = ref.read(sessionControllerProvider).maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    if (accountId != null) {
      Future.microtask(() =>
          ref.read(interestsProvider.notifier).load(accountId: accountId),
      );
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
                    .where(
                        (i) => i.name.toLowerCase().contains(_query.toLowerCase()))
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
                              .copyWith(color: DesignTokens.textLight)),
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
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search,
                              color: DesignTokens.inputFieldPlaceholder,
                              size: 20),
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
                        icon: _iconForInterest(interest.name),
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
                  padding: const EdgeInsets.fromLTRB(
                      DesignTokens.s16,
                      DesignTokens.s24,
                      DesignTokens.s16,
                      DesignTokens.s24),
                  child: Opacity(
                    opacity: canProceed ? 1 : 0.5,
                    child: Material(
                      color: DesignTokens.primaryGreen,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.buttonRadius),
                      child: InkWell(
                        onTap:
                            canProceed
                                ? () => context.go(RouteNames.followCreators)
                                : null,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.s32,
                              vertical: DesignTokens.s16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Proceed',
                                  style: DesignTokens.oneLinerSemibold
                                      .copyWith(
                                          color:
                                              DesignTokens.buttonPrimaryText)),
                              const SizedBox(width: DesignTokens.s8),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: DesignTokens.iconSmall,
                                  color: DesignTokens.buttonPrimaryText),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loadFailure: (failure) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: DesignTokens.colorError, size: 48),
                const SizedBox(height: DesignTokens.s16),
                Text('Failed to load interests',
                    style: DesignTokens.bodyText),
                const SizedBox(height: DesignTokens.s16),
                GestureDetector(
                  onTap: () {
                    final accountId = ref
                        .read(sessionControllerProvider)
                        .maybeWhen(
                            authenticated: (id) => id, orElse: () => null);
                    if (accountId != null) {
                      ref.read(interestsProvider.notifier).load(
                          accountId: accountId);
                    }
                  },
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

IconData _iconForInterest(String name) {
  switch (name.toLowerCase()) {
    case 'fashion':
      return Icons.checkroom;
    case 'beauty':
      return Icons.brush;
    case 'fitness':
      return Icons.fitness_center;
    case 'tech':
    case 'technology':
      return Icons.devices;
    case 'food':
      return Icons.restaurant;
    case 'travel':
      return Icons.flight;
    case 'music':
      return Icons.music_note;
    case 'gaming':
      return Icons.sports_esports;
    case 'art':
      return Icons.palette;
    case 'home':
      return Icons.chair;
    case 'sports':
      return Icons.sports_basketball;
    case 'books':
      return Icons.menu_book;
    case 'movies':
      return Icons.movie;
    case 'photography':
      return Icons.camera_alt;
    case 'lifestyle':
      return Icons.spa;
    default:
      return Icons.category;
  }
}

/// Glassmorphic interest chip (Figma "Radio Card").
class _RadioCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RadioCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: selected
                  ? DesignTokens.primaryGreen
                  : DesignTokens.radioCardTitle,
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.smallRegular.copyWith(
                color: selected
                    ? DesignTokens.primaryGreen
                    : DesignTokens.radioCardTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
