import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A selectable interest category.
class _Interest {
  final String label;
  final IconData icon;
  const _Interest(this.label, this.icon);
}

/// Pick Your Interests — pixel-matched to Figma frame `9615:45821`.
///
/// Title + subtitle → "X/3 Picked" progress bar → search field → 4-column grid
/// of glassmorphic "Radio Card" chips → sticky "Proceed" button (enabled once
/// at least 3 are selected).
class PickInterestsScreen extends ConsumerStatefulWidget {
  const PickInterestsScreen({super.key});

  @override
  ConsumerState<PickInterestsScreen> createState() => _PickInterestsScreenState();
}

class _PickInterestsScreenState extends ConsumerState<PickInterestsScreen> {
  // TODO: source categories from the API; placeholder set for now.
  static const List<_Interest> _interests = [
    _Interest('Fitness', Icons.fitness_center),
    _Interest('Skincare', Icons.face_retouching_natural),
    _Interest('Haircare', Icons.content_cut),
    _Interest('Fashion', Icons.checkroom),
    _Interest('Gaming', Icons.sports_esports),
    _Interest('Outdoors', Icons.park),
    _Interest('Travel', Icons.flight),
    _Interest('Food', Icons.restaurant),
    _Interest('Wellness', Icons.spa),
    _Interest('Sports', Icons.sports_basketball),
    _Interest('Music', Icons.music_note),
    _Interest('Photography', Icons.camera_alt),
    _Interest('Art', Icons.palette),
    _Interest('Beauty', Icons.brush),
    _Interest('Lifestyle', Icons.self_improvement),
  ];

  static const int _minPicks = 3;

  final Set<String> _selected = {};
  String _query = '';

  List<_Interest> get _filtered => _query.isEmpty
      ? _interests
      : _interests
          .where((i) => i.label.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  bool get _canProceed => _selected.length >= _minPicks;

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (_selected.length / _minPicks).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DesignTokens.s16,
                  DesignTokens.s16, DesignTokens.s16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text('Pick Your Interests', style: DesignTokens.titleMedium),
                  const SizedBox(height: DesignTokens.s8),
                  Text(
                    "Select at least 3 interests — we'll use it to personalize your feed",
                    style: DesignTokens.bodyText,
                  ),
                  const SizedBox(height: DesignTokens.s24),

                  // Progress
                  Text('${_selected.length}/$_minPicks Picked',
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

                  // Search
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      color: DesignTokens.inputFieldData,
                    ),
                    cursorColor: DesignTokens.primaryGreen,
                    decoration: DesignTokens.inputDecoration(
                      hintText: 'Search interest',
                      prefixIcon: const Icon(Icons.search,
                          color: DesignTokens.inputFieldPlaceholder, size: 20),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s24),
                ],
              ),
            ),

            // Interest grid
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16),
                crossAxisCount: 4,
                crossAxisSpacing: DesignTokens.s12,
                mainAxisSpacing: DesignTokens.s12,
                childAspectRatio: 83.5 / 84,
                children: _filtered.map((interest) {
                  final selected = _selected.contains(interest.label);
                  return _RadioCard(
                    interest: interest,
                    selected: selected,
                    onTap: () => _toggle(interest.label),
                  );
                }).toList(),
              ),
            ),

            // Sticky "Proceed" button
            Consumer(
              builder: (context, ref, _) {
                final saveState = ref.watch(saveInterestsProvider);

                ref.listen(saveInterestsProvider, (_, next) {
                  if (next.saved) context.go(RouteNames.followCreators);
                  if (next.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to save interests. Please try again.'),
                      ),
                    );
                  }
                });

                return _StickyButton(
                  label: 'Proceed',
                  enabled: _canProceed && !saveState.isLoading,
                  isLoading: saveState.isLoading,
                  onTap: () {
                    ref.read(saveInterestsProvider.notifier).save(
                      _selected.toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphic interest chip (Figma "Radio Card"): white@6% fill, white@22%
/// border (green when selected), 32px icon + 12px centered label.
class _RadioCard extends StatelessWidget {
  final _Interest interest;
  final bool selected;
  final VoidCallback onTap;

  const _RadioCard({
    required this.interest,
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
              interest.icon,
              size: 32,
              color: selected
                  ? DesignTokens.primaryGreen
                  : DesignTokens.radioCardTitle,
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              interest.label,
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

/// Reusable bottom action bar (Figma "Sticky Button"): top divider + full-width
/// primary pill with a trailing arrow.
class _StickyButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _StickyButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s24, DesignTokens.s16, DesignTokens.s24),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: DesignTokens.primaryGreen,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s32, vertical: DesignTokens.s16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    )
                  else ...[
                    Text(label,
                        style: DesignTokens.oneLinerSemibold
                            .copyWith(color: DesignTokens.buttonPrimaryText)),
                    const SizedBox(width: DesignTokens.s8),
                    const Icon(Icons.arrow_forward_rounded,
                        size: DesignTokens.iconSmall,
                        color: DesignTokens.buttonPrimaryText),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
