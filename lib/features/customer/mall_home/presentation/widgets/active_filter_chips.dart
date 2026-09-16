import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The filters currently applied, each removable. Shown under the sort chips
/// on the listing and the brand storefront's Shop All, so a filter carried in
/// from a deep link is visible and can be dropped without opening the sheet.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    required this.query,
    required this.onChanged,
    super.key,
  });

  final ProductListingQuery query;
  final ValueChanged<ProductListingQuery> onChanged;

  /// Label / removed-query pairs, in the order they render.
  static List<(String, ProductListingQuery)> chipsFor(
    ProductListingQuery query,
  ) => [
    if (query.minPrice != null || query.maxPrice != null)
      (_priceLabel(query), query.without(price: true)),
    if (query.inStock) ('In stock', query.without(inStock: true)),
    if (query.onSale) ('On sale', query.without(onSale: true)),
    if (query.minRating case final rating?)
      ('${_number(rating)}★ & up', query.without(rating: true)),
    if (query.size case final size?) ('Size: $size', query.without(size: true)),
    if (query.color case final color?)
      ('Colour: $color', query.without(color: true)),
    for (final (index, id) in query.optionValueIds.indexed)
      ('Option ${index + 1}', query.without(optionValueId: id)),
  ];

  static String _priceLabel(ProductListingQuery query) {
    final min = query.minPrice;
    final max = query.maxPrice;
    if (min != null && max != null) return 'Rs ${_number(min)}–${_number(max)}';
    if (min != null) return 'From Rs ${_number(min)}';
    return 'Up to Rs ${_number(max!)}';
  }

  static String _number(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();

  @override
  Widget build(BuildContext context) {
    final chips = chipsFor(query);
    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
      child: Row(
        children: [
          for (final (index, (label, next)) in chips.indexed) ...[
            if (index > 0) const SizedBox(width: DesignTokens.s8),
            _RemovableChip(label: label, onRemove: () => onChanged(next)),
          ],
        ],
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove filter $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRemove,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: DesignTokens.minTouchTarget,
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 10, 0),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            border: Border.all(color: DesignTokens.borderDefault),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(width: DesignTokens.s6),
              const Icon(
                Icons.close_rounded,
                size: 16,
                color: DesignTokens.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
