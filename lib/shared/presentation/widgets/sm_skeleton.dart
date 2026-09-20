import 'package:flutter/material.dart';

import '../../../theme/design_tokens.dart';
import 'sm_shimmer.dart';

/// Skeletons that stand in for content while it loads.
///
/// A skeleton is shaped like the thing that follows it, so the page does not
/// jump when data arrives. Prefer these over a spinner on any surface that
/// resolves into a list or a grid of cards.
///
/// These draw placeholder blocks only — never numbers, never sample copy.
/// Nothing a skeleton shows can be mistaken for data.
abstract class SmSkeleton {
  /// A row: round avatar, title line, subtitle line. Matches a list tile.
  static Widget row({bool enabled = true, double avatarRadius = 22}) =>
      _SkeletonRow(enabled: enabled, avatarRadius: avatarRadius);

  /// A card: media block on top, title and meta lines under it.
  static Widget card({bool enabled = true, double mediaHeight = 120}) =>
      _SkeletonCard(enabled: enabled, mediaHeight: mediaHeight);

  /// A stat tile: small icon chip, a value line, a label line. Matches the
  /// dashboard stat cards.
  static Widget statTile({bool enabled = true}) =>
      _SkeletonStatTile(enabled: enabled);

  /// A block of [count] rows with dividers between them.
  static Widget rows({int count = 5, bool enabled = true}) => Column(
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(height: DesignTokens.s16),
        _SkeletonRow(enabled: enabled),
      ],
    ],
  );

  /// A row of [count] stat tiles, sized like the dashboard's.
  static Widget statRow({int count = 3, bool enabled = true}) => Row(
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(width: DesignTokens.s8),
        Expanded(child: _SkeletonStatTile(enabled: enabled)),
      ],
    ],
  );
}

/// A full-page skeleton for a screen that resolves into a list.
///
/// Drop this in where a [CircularProgressIndicator] used to sit.
class SmListSkeleton extends StatelessWidget {
  const SmListSkeleton({super.key, this.itemCount = 6, this.padding});

  final int itemCount;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final enabled = !MediaQuery.disableAnimationsOf(context);
    return ListView.separated(
      padding:
          padding ??
          const EdgeInsets.all(DesignTokens.appHorizontalPadding),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s16),
      itemBuilder: (_, _) => SmSkeleton.row(enabled: enabled),
    );
  }
}

/// A full-page skeleton for a screen that resolves into a grid of cards.
class SmCardGridSkeleton extends StatelessWidget {
  const SmCardGridSkeleton({
    super.key,
    this.itemCount = 4,
    this.crossAxisCount = 2,
    this.padding,
  });

  final int itemCount;
  final int crossAxisCount;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final enabled = !MediaQuery.disableAnimationsOf(context);
    return GridView.builder(
      padding:
          padding ??
          const EdgeInsets.all(DesignTokens.appHorizontalPadding),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: DesignTokens.s12,
        mainAxisSpacing: DesignTokens.s12,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => SmSkeleton.card(enabled: enabled),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.enabled, this.avatarRadius = 22});

  final bool enabled;
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SmShimmer.circle(radius: avatarRadius, enabled: enabled),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SmShimmer.rectangle(
                height: DesignTokens.s16,
                radius: DesignTokens.s4,
                enabled: enabled,
              ),
              const SizedBox(height: DesignTokens.s8),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: SmShimmer.rectangle(
                  height: DesignTokens.s12,
                  radius: DesignTokens.s4,
                  enabled: enabled,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.enabled, this.mediaHeight = 120});

  final bool enabled;
  final double mediaHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SmShimmer.rectangle(
          height: mediaHeight,
          radius: DesignTokens.radiusMedium,
          enabled: enabled,
        ),
        const SizedBox(height: DesignTokens.s12),
        SmShimmer.rectangle(
          height: DesignTokens.s16,
          radius: DesignTokens.s4,
          enabled: enabled,
        ),
        const SizedBox(height: DesignTokens.s8),
        FractionallySizedBox(
          widthFactor: 0.5,
          child: SmShimmer.rectangle(
            height: DesignTokens.s12,
            radius: DesignTokens.s4,
            enabled: enabled,
          ),
        ),
      ],
    );
  }
}

class _SkeletonStatTile extends StatelessWidget {
  const _SkeletonStatTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SmShimmer.rectangle(
            width: DesignTokens.s40,
            height: DesignTokens.s40,
            radius: DesignTokens.radiusSmall,
            enabled: enabled,
          ),
          const SizedBox(height: DesignTokens.s12),
          SmShimmer.rectangle(
            width: DesignTokens.s48,
            height: DesignTokens.s20,
            radius: DesignTokens.s4,
            enabled: enabled,
          ),
          const SizedBox(height: DesignTokens.s8),
          SmShimmer.rectangle(
            width: DesignTokens.s36,
            height: DesignTokens.s12,
            radius: DesignTokens.s4,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
