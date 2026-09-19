import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_tile_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_type_tile.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// **The Mall's product row.** The list-shaped sibling of `MallProductTile`,
/// for the browse surfaces that answer in a column rather than a grid:
/// search results, a ranked edit, a category list.
///
/// It obeys the same directive as the tile — never a product photo, because
/// the Mall is video-first and photos belong to the product details page
/// (owner directive, 2026-09-16). The leading block is the tile's own
/// `MallTypeGround`, seeded from the product id so a product looks the same
/// wherever it appears, with the reel's play mark drawn on it when the
/// product has a reel.
///
/// Unlike the tile it has no fixed height: a row is read in a list, so it
/// grows with the text scale instead of reserving slots. Everything past the
/// leading block is `Expanded`, every string is capped, so it cannot overflow
/// at 320 dp and text scale 1.3.
///
/// The row draws only what the view model carries. A product with no rating
/// gets no rating; a row with no [footer] shows none. Nothing here estimates.
class MallResultRow extends StatelessWidget {
  const MallResultRow({
    required this.product,
    super.key,
    this.onTap,
    this.rank,
    this.signal,
    this.footer,
    this.trailing,
    this.semanticExtras = const [],
    this.semanticPrefix,
  });

  final MallProductVm product;

  /// Opens the product. The whole row is one button.
  final VoidCallback? onTap;

  /// Position in a ranked list, drawn before the ground in tabular figures.
  /// Null in an unranked list, which is most of them.
  final int? rank;

  /// One live fact under the price, on the same terms as the tile's: built
  /// from a field the API populated, or not built.
  final MallSignal? signal;

  /// A caller-owned block under the price — a sponsored disclosure, a match
  /// reason. It keeps its own semantics nodes, so anything interactive in it
  /// stays reachable.
  final Widget? footer;

  /// A caller-owned control at the trailing edge. Give it a real action: the
  /// row draws no decorative affordance.
  final Widget? trailing;

  /// Extra phrases appended to the spoken label, such as why a result
  /// matched.
  final List<String> semanticExtras;

  /// A phrase spoken **before** the product. A paid-placement disclosure
  /// goes here: a buyer must hear that a result is an advertisement before
  /// they hear what it is selling.
  final String? semanticPrefix;

  /// The leading block, 4:5 like every other Mall medium.
  static const double mediaWidth = 64;
  static const double mediaHeight = 80;

  static const TextStyle _rankStyle = TextStyle(
    fontFamily: DesignTokens.displayFontFamily,
    fontSize: 15,
    height: 1.2,
    color: DesignTokens.textMuted,
    fontFeatures: mallTabularFigures,
  );

  static const TextStyle _nameStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  static const TextStyle _priceStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: DesignTokens.textWhite,
    fontFeatures: mallTabularFigures,
  );

  static const TextStyle _compareStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    height: 1.2,
    color: DesignTokens.textMuted,
    decoration: TextDecoration.lineThrough,
    fontFeatures: mallTabularFigures,
  );

  String? get _monogram {
    final source = product.brandName?.trim().isNotEmpty ?? false
        ? product.brandName!.trim()
        : product.name.trim();
    return source.isEmpty ? null : source[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final brand = product.brandName;
    final fact = signal;
    final compareAt = product.discountPercent == null
        ? null
        : product.compareAtPrice;
    final radius = BorderRadius.circular(DesignTokens.radiusMedium);
    final prefix = semanticPrefix;
    final label = [
      ?prefix,
      mallTileSemanticLabel(
        strings,
        product,
        rating: product.rating,
        signal: fact,
        extras: semanticExtras,
      ),
    ].join('. ');
    final badges = mallTileBadges(strings, product);

    return Semantics(
      container: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          // The row's own tap is one labelled button; the visible strings are
          // excluded so a reader does not hear them twice, while `footer` and
          // `trailing` keep their nodes.
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: DesignTokens.s8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rank != null) ...[
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 26,
                      child: Text('$rank', style: _rankStyle),
                    ),
                  ),
                ],
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: SizedBox(
                      width: mediaWidth,
                      height: mediaHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MallTypeGround(
                            seed: product.id,
                            monogram: _monogram,
                          ),
                          if (product.reel != null)
                            const Center(child: MallPlayMark(size: 26)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        button: onTap != null,
                        label: label,
                        excludeSemantics: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (brand != null) ...[
                              Text(
                                brand.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DesignTokens.eyebrow,
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _nameStyle,
                            ),
                            const SizedBox(height: DesignTokens.s6),
                            MallTilePriceRow(
                              price: product.price,
                              compareAtPrice: compareAt,
                              priceStyle: _priceStyle,
                              compareStyle: _compareStyle,
                            ),
                            if (badges.isNotEmpty) ...[
                              const SizedBox(height: DesignTokens.s6),
                              Wrap(
                                spacing: DesignTokens.s6,
                                runSpacing: DesignTokens.s4,
                                children: badges,
                              ),
                            ],
                            if (fact != null) ...[
                              const SizedBox(height: DesignTokens.s4),
                              MallSignalLine(signal: fact),
                            ],
                          ],
                        ),
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: DesignTokens.s6),
                        footer!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: DesignTokens.s8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
