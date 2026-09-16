import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_collection_card.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_rail.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Mall's editorial zone: collections laid out as a magazine page rather
/// than another row of equal cards.
///
/// One lead image holds most of the width and two smaller tiles stack beside
/// it; anything past the third runs on as a quiet rail underneath. Every tile
/// is given an exact box, so the block cannot overflow at any text scale —
/// the cards clip their own copy.
///
/// Below 360dp there is no room for the split, so the lead goes full width
/// and the pair sits under it.
class MallEditorialSpread extends StatelessWidget {
  const MallEditorialSpread({
    required this.collections,
    required this.semanticLabel,
    super.key,
    this.onOpen,
  });

  final List<MallCollectionVm> collections;

  /// Names the block for assistive technology, e.g. "Collections".
  final String semanticLabel;
  final void Function(MallCollectionVm collection)? onOpen;

  /// Page gutter each side of the spread.
  static const double gutter = DesignTokens.s16;
  static const double gap = DesignTokens.s12;

  /// Share of the width the lead image takes in the split layout.
  static const double leadShare = 0.62;

  /// Width below which the split has no room.
  static const double splitMinWidth = 360;

  /// Width of a tile on the run-on rail.
  static const double railItemWidth = 172;

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth - gutter * 2;
          if (available <= 0) return const SizedBox.shrink();
          final split =
              constraints.maxWidth >= splitMinWidth && collections.length >= 3;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: gutter,
                ),
                child: split
                    ? _Split(
                        collections: collections,
                        available: available,
                        onOpen: onOpen,
                      )
                    : _Stacked(
                        collections: collections,
                        available: available,
                        onOpen: onOpen,
                      ),
              ),
              if (collections.length > 3) ...[
                const SizedBox(height: gap),
                _RunOn(
                  collections: collections.sublist(3),
                  semanticLabel: semanticLabel,
                  onOpen: onOpen,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A tall lead with two tiles stacked beside it.
class _Split extends StatelessWidget {
  const _Split({
    required this.collections,
    required this.available,
    required this.onOpen,
  });

  final List<MallCollectionVm> collections;
  final double available;
  final void Function(MallCollectionVm collection)? onOpen;

  @override
  Widget build(BuildContext context) {
    const gap = MallEditorialSpread.gap;
    final leadWidth = (available - gap) * MallEditorialSpread.leadShare;
    final sideWidth = available - gap - leadWidth;
    // The lead sets the block's height at 4:5; the pair divides it.
    final leadHeight = leadWidth * 5 / 4;
    final sideHeight = (leadHeight - gap) / 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: leadWidth,
          height: leadHeight,
          child: _Tile(collection: collections[0], onOpen: onOpen),
        ),
        const SizedBox(width: gap),
        SizedBox(
          width: sideWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: sideHeight,
                child: _Tile(
                  collection: collections[1],
                  onOpen: onOpen,
                  compact: true,
                ),
              ),
              const SizedBox(height: gap),
              SizedBox(
                height: sideHeight,
                child: _Tile(
                  collection: collections[2],
                  onOpen: onOpen,
                  compact: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lead across the full width, with any pair beneath it.
class _Stacked extends StatelessWidget {
  const _Stacked({
    required this.collections,
    required this.available,
    required this.onOpen,
  });

  final List<MallCollectionVm> collections;
  final double available;
  final void Function(MallCollectionVm collection)? onOpen;

  @override
  Widget build(BuildContext context) {
    const gap = MallEditorialSpread.gap;
    final single = collections.length == 1;
    // A lone collection reads better wide than tall.
    final leadHeight = single ? available * 10 / 16 : available * 5 / 4;
    final pair = collections.skip(1).take(2).toList();
    final pairWidth = (available - gap) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: leadHeight,
          child: _Tile(collection: collections[0], onOpen: onOpen),
        ),
        if (pair.isNotEmpty) ...[
          const SizedBox(height: gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, collection) in pair.indexed) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  width: pairWidth,
                  height: pairWidth,
                  child: _Tile(
                    collection: collection,
                    onOpen: onOpen,
                    compact: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Everything past the spread, as a rail that runs off the edge.
class _RunOn extends StatelessWidget {
  const _RunOn({
    required this.collections,
    required this.semanticLabel,
    required this.onOpen,
  });

  final List<MallCollectionVm> collections;
  final String semanticLabel;
  final void Function(MallCollectionVm collection)? onOpen;

  @override
  Widget build(BuildContext context) {
    const width = MallEditorialSpread.railItemWidth;
    return MallRail<MallCollectionVm>(
      items: collections,
      itemWidth: width,
      height: MallCollectionCard.heightFor(width),
      semanticLabel: semanticLabel,
      itemBuilder: (_, collection, _) => MallCollectionCard(
        collection: collection,
        size: MallCardSize.compact,
        onTap: onOpen == null ? null : () => onOpen!(collection),
      ),
    );
  }
}

/// One tile of the spread, filling whatever box the layout gave it.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.collection,
    required this.onOpen,
    this.compact = false,
  });

  final MallCollectionVm collection;
  final void Function(MallCollectionVm collection)? onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    return MallCollectionCard(
      collection: collection,
      fill: true,
      size: compact ? MallCardSize.compact : MallCardSize.regular,
      onTap: open == null ? null : () => open(collection),
    );
  }
}
