import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_product_card.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/sm_skeleton.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Responsive product grid (box widget): 2 columns on phones, 3 from 600dp,
/// 4 from 900dp of available width. Row heights come from
/// [MallProductCard.heightFor], so cards never overflow at any text scale.
///
/// Inside a CustomScrollView use [MallSliverProductGrid] instead.
class MallProductGrid extends StatelessWidget {
  const MallProductGrid({
    required this.products,
    super.key,
    this.onProductTap,
    this.onSaveTap,
    this.size = MallCardSize.regular,
    this.isLoading = false,
    this.skeletonCount = 6,
    this.emptyState,
    this.padding = _defaultPadding,
    this.crossAxisSpacing = DesignTokens.s12,
    this.mainAxisSpacing = DesignTokens.s24,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
  });

  final List<MallProductVm> products;
  final ValueChanged<MallProductVm>? onProductTap;

  /// Shows save hearts when non-null.
  final ValueChanged<MallProductVm>? onSaveTap;
  final MallCardSize size;
  final bool isLoading;
  final int skeletonCount;
  final Widget? emptyState;
  final EdgeInsetsGeometry padding;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  static const EdgeInsetsGeometry _defaultPadding =
      EdgeInsetsDirectional.fromSTEB(
        DesignTokens.s16,
        0,
        DesignTokens.s16,
        DesignTokens.s16,
      );

  /// Column count for [width] logical pixels of available width.
  static int columnsFor(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading && products.isEmpty) {
      return emptyState ?? const SizedBox.shrink();
    }
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final layout = _GridLayout.resolve(
          context,
          width: constraints.maxWidth,
          padding: padding,
          spacing: crossAxisSpacing,
          size: size,
        );
        return GridView.builder(
          controller: controller,
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          gridDelegate: layout.delegate(mainAxisSpacing),
          itemCount: isLoading ? skeletonCount : products.length,
          itemBuilder: (context, index) => _buildTile(
            layout: layout,
            size: size,
            product: isLoading ? null : products[index],
            onProductTap: onProductTap,
            onSaveTap: onSaveTap,
          ),
        );
      },
    );
    if (!isLoading) return grid;
    return Semantics(
      container: true,
      label: MallStrings.of(context).loading,
      child: grid,
    );
  }
}

/// Sliver twin of [MallProductGrid] for CustomScrollView pages.
class MallSliverProductGrid extends StatelessWidget {
  const MallSliverProductGrid({
    required this.products,
    super.key,
    this.onProductTap,
    this.onSaveTap,
    this.size = MallCardSize.regular,
    this.isLoading = false,
    this.skeletonCount = 6,
    this.emptyState,
    this.padding = MallProductGrid._defaultPadding,
    this.crossAxisSpacing = DesignTokens.s12,
    this.mainAxisSpacing = DesignTokens.s24,
  });

  final List<MallProductVm> products;
  final ValueChanged<MallProductVm>? onProductTap;
  final ValueChanged<MallProductVm>? onSaveTap;
  final MallCardSize size;
  final bool isLoading;
  final int skeletonCount;
  final Widget? emptyState;
  final EdgeInsetsGeometry padding;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && products.isEmpty) {
      return SliverToBoxAdapter(child: emptyState ?? const SizedBox.shrink());
    }
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final layout = _GridLayout.resolve(
          context,
          width: constraints.crossAxisExtent,
          padding: padding,
          spacing: crossAxisSpacing,
          size: size,
        );
        return SliverPadding(
          padding: padding,
          sliver: SliverGrid.builder(
            gridDelegate: layout.delegate(mainAxisSpacing),
            itemCount: isLoading ? skeletonCount : products.length,
            itemBuilder: (context, index) => _buildTile(
              layout: layout,
              size: size,
              product: isLoading ? null : products[index],
              onProductTap: onProductTap,
              onSaveTap: onSaveTap,
            ),
          ),
        );
      },
    );
  }
}

Widget _buildTile({
  required _GridLayout layout,
  required MallCardSize size,
  required MallProductVm? product,
  required ValueChanged<MallProductVm>? onProductTap,
  required ValueChanged<MallProductVm>? onSaveTap,
}) {
  if (product == null) {
    return SmSkeletonProductCard(width: layout.tileWidth, size: size);
  }
  return MallProductCard(
    product: product,
    size: size,
    onTap: onProductTap == null ? null : () => onProductTap(product),
    onSaveTap: onSaveTap == null ? null : () => onSaveTap(product),
  );
}

class _GridLayout {
  const _GridLayout({
    required this.columns,
    required this.tileWidth,
    required this.tileHeight,
    required this.spacing,
  });

  factory _GridLayout.resolve(
    BuildContext context, {
    required double width,
    required EdgeInsetsGeometry padding,
    required double spacing,
    required MallCardSize size,
  }) {
    final columns = MallProductGrid.columnsFor(width);
    final insets = padding.resolve(Directionality.of(context));
    final tileWidth = math.max<double>(
      0,
      (width - insets.horizontal - spacing * (columns - 1)) / columns,
    );
    return _GridLayout(
      columns: columns,
      tileWidth: tileWidth,
      tileHeight: MallProductCard.heightFor(
        context,
        width: tileWidth,
        size: size,
      ),
      spacing: spacing,
    );
  }

  final int columns;
  final double tileWidth;
  final double tileHeight;
  final double spacing;

  SliverGridDelegate delegate(double mainAxisSpacing) =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: mainAxisSpacing,
        mainAxisExtent: tileHeight,
      );
}
