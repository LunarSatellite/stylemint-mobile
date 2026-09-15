import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_choice_chip.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Opens the listing filters. Resolves to the query with the chosen filters,
/// or null when dismissed.
Future<ProductListingQuery?> showProductFilterSheet(
  BuildContext context,
  ProductListingQuery query,
) {
  return showModalBottomSheet<ProductListingQuery>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: DesignTokens.surfaceRaised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusLarge),
      ),
    ),
    builder: (_) => ProductFilterSheet(initial: query),
  );
}

/// Price range, in stock, on sale and minimum rating.
class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({required this.initial, super.key});

  final ProductListingQuery initial;

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late final TextEditingController _min = TextEditingController(
    text: _format(widget.initial.minPrice),
  );
  late final TextEditingController _max = TextEditingController(
    text: _format(widget.initial.maxPrice),
  );
  late bool _inStock = widget.initial.inStock;
  late bool _onSale = widget.initial.onSale;
  late double? _minRating = widget.initial.minRating;
  String? _priceError;

  static const List<(double?, String, String)> _ratings = [
    (null, 'Any', 'Any rating'),
    (3, '3★ & up', '3 stars and up'),
    (4, '4★ & up', '4 stars and up'),
    (4.5, '4.5★ & up', '4.5 stars and up'),
  ];

  static String _format(double? value) {
    if (value == null) return '';
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  static double? _parse(String text) {
    final value = double.tryParse(text.replaceAll(',', '').trim());
    return value == null || value < 0 ? null : value;
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _min.clear();
    _max.clear();
    _inStock = false;
    _onSale = false;
    _minRating = null;
    _priceError = null;
  });

  void _apply() {
    final min = _parse(_min.text);
    final max = _parse(_max.text);
    if (min != null && max != null && min > max) {
      setState(
        () => _priceError = 'The minimum price must be below the maximum.',
      );
      return;
    }
    Navigator.of(context).pop(
      widget.initial.withFilters(
        inStock: _inStock,
        onSale: _onSale,
        minPrice: min,
        maxPrice: max,
        minRating: _minRating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _priceError;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: const Text(
                      'Filters',
                      style: DesignTokens.displaySection,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.textLight,
                    minimumSize: const Size(
                      DesignTokens.minTouchTarget,
                      DesignTokens.minTouchTarget,
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s20),
            const MallEyebrow('Price (Rs)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PriceField(
                    controller: _min,
                    hint: 'Min',
                    onChanged: () => setState(() => _priceError = null),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: _PriceField(
                    controller: _max,
                    hint: 'Max',
                    onChanged: () => setState(() => _priceError = null),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                error,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s16),
            _ToggleRow(
              label: 'In stock only',
              value: _inStock,
              onChanged: (value) => setState(() => _inStock = value),
            ),
            _ToggleRow(
              label: 'On sale',
              value: _onSale,
              onChanged: (value) => setState(() => _onSale = value),
            ),
            const SizedBox(height: DesignTokens.s16),
            const MallEyebrow('Rating'),
            const SizedBox(height: DesignTokens.s6),
            Wrap(
              spacing: DesignTokens.s8,
              children: [
                for (final (value, label, spoken) in _ratings)
                  MallChoiceChip(
                    label: label,
                    semanticLabel: spoken,
                    selected: _minRating == value,
                    onTap: () => setState(() => _minRating = value),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.s24),
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: MallPrimaryCta(label: 'Show results', onPressed: _apply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
      onChanged: (_) => onChanged(),
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 15,
        color: DesignTokens.textWhite,
      ),
      decoration: DesignTokens.inputDecoration(hintText: hint),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
