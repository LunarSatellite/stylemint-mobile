import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_reel_play_slot.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_reel_tile.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_tile_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_type_tile.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';

/// The Mall's product tile: a reel where the product has one, the designed
/// type tile where it does not. Never a product photo — those live on the
/// product details page only (owner directive, 2026-09-16).
///
/// Both tiles have the same footprint, so a rail or grid sized with
/// [heightFor] fits either.
class MallProductTile extends StatelessWidget {
  const MallProductTile({
    required this.product,
    super.key,
    this.size = MallCardSize.regular,
    this.onTap,
    this.onReelTap,
    this.onSaveTap,
    this.showRating = true,
    this.signal,
    this.reserveSignal = false,
    this.playSlotController,
  });

  final MallProductVm product;
  final MallCardSize size;

  /// Opens the product.
  final VoidCallback? onTap;

  /// Plays the reel of a tile that has one — the play mark's target. The
  /// rest of the tile opens the product through [onTap]; a caller that gave
  /// no [onTap] keeps the whole tile opening the reel.
  final void Function(MallReelRef reel)? onReelTap;

  /// Shows the save heart when non-null.
  final VoidCallback? onSaveTap;
  final bool showRating;

  /// One live fact under the price.
  final MallSignal? signal;

  /// Keeps the signal slot so every tile in a rail is the same height.
  final bool reserveSignal;

  /// Defaults to [MallReelPlaySlotController.instance].
  final MallReelPlaySlotController? playSlotController;

  /// Suggested rail item widths.
  static const double compactWidth = 148;
  static const double regularWidth = 184;

  /// Exact rendered height of a tile [width] wide at the ambient text scale.
  static double heightFor(
    BuildContext context, {
    required double width,
    MallCardSize size = MallCardSize.regular,
    bool withSignal = false,
  }) => MallTileMetrics.heightFor(
    context,
    width: width,
    size: size,
    withSignal: withSignal,
  );

  @override
  Widget build(BuildContext context) {
    final reel = product.reel;
    if (reel == null) {
      return MallTypeTile(
        product: product,
        size: size,
        onTap: onTap,
        onSaveTap: onSaveTap,
        showRating: showRating,
        signal: signal,
        reserveSignal: reserveSignal,
      );
    }
    final openReel = onReelTap;
    return MallReelTile(
      product: product,
      reel: reel,
      size: size,
      onTap: onTap ?? (openReel == null ? null : () => openReel(reel)),
      onPlayTap: openReel == null ? null : () => openReel(reel),
      onSaveTap: onSaveTap,
      showRating: showRating,
      signal: signal,
      reserveSignal: reserveSignal,
      playSlotController: playSlotController,
    );
  }
}
