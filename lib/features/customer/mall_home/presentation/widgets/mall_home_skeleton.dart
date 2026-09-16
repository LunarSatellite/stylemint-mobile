import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// First-load placeholder in the shape of the page it becomes: the full-bleed
/// cinematic stage, a dense signal rail, the drop plate, then the editorial
/// spread. Loading the Mall should feel like the Mall arriving, not like a
/// different screen that gets replaced.
class MallHomeSkeleton extends StatelessWidget {
  const MallHomeSkeleton({required this.topInset, super.key});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    const railWidth = MallProductCard.compactWidth;
    final railHeight = MallProductCard.heightFor(
      context,
      width: railWidth,
      size: MallCardSize.compact,
      withSignal: true,
    );
    return Semantics(
      container: true,
      label: MallStrings.of(context).loading,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // The hero runs edge to edge and under the top inset, exactly as
          // the real one does.
          SmSkeleton.box(
            height: MallCinematicHero.heightFor(context),
            radius: 0,
          ),
          const SizedBox(height: DesignTokens.s40),
          const _HeaderSkeleton(),
          SmSkeletonRail(
            itemWidth: railWidth,
            height: railHeight,
            itemBuilder: (_, _) => const SmSkeletonProductCard(
              width: railWidth,
              size: MallCardSize.compact,
            ),
          ),
          const SizedBox(height: DesignTokens.s40),
          const _PlateSkeleton(),
          const SizedBox(height: DesignTokens.s24),
          SmSkeletonRail(
            itemWidth: railWidth,
            height: railHeight,
            itemBuilder: (_, _) => const SmSkeletonProductCard(
              width: railWidth,
              size: MallCardSize.compact,
            ),
          ),
          const SizedBox(height: DesignTokens.s40),
          const _HeaderSkeleton(),
          const _SpreadSkeleton(),
        ],
      ),
    );
  }
}

/// The index rule, eyebrow and display title of a section header.
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmSkeleton.line(width: 120, height: 10),
          SizedBox(height: DesignTokens.s12),
          SmSkeleton.line(width: 72, height: 10),
          SizedBox(height: DesignTokens.s8),
          SmSkeleton.line(width: 200, height: 24),
        ],
      ),
    );
  }
}

/// The colour-blocked drop plate.
class _PlateSkeleton extends StatelessWidget {
  const _PlateSkeleton();

  @override
  Widget build(BuildContext context) =>
      const SmSkeleton.box(height: 210, radius: 0);
}

/// The editorial spread: a tall lead beside two stacked tiles.
class _SpreadSkeleton extends StatelessWidget {
  const _SpreadSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = DesignTokens.s12;
          final available = constraints.maxWidth;
          final leadWidth = (available - gap) * MallEditorialSpread.leadShare;
          final sideWidth = available - gap - leadWidth;
          final leadHeight = leadWidth * 5 / 4;
          final sideHeight = (leadHeight - gap) / 2;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmSkeleton.box(width: leadWidth, height: leadHeight),
              const SizedBox(width: gap),
              Column(
                children: [
                  SmSkeleton.box(width: sideWidth, height: sideHeight),
                  const SizedBox(height: gap),
                  SmSkeleton.box(width: sideWidth, height: sideHeight),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
