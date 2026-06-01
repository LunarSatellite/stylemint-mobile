import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VariantSelector extends StatelessWidget {
  const VariantSelector({
    required this.variant,
    required this.selectedValue,
    required this.onSelected,
    super.key,
  });

  final ProductVariant variant;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          variant.name,
          style: DesignTokens.mediumSemibold,
        ),
        const SizedBox(height: DesignTokens.s8),
        Wrap(
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s8,
          children: variant.values.map((value) {
            final isSelected = value == selectedValue;
            return GestureDetector(
              onTap: () => onSelected(value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s8,
                ),
                decoration: isSelected
                    ? DesignTokens.chipDecorationSelected()
                    : DesignTokens.chipDecorationDefault(),
                child: Text(
                  value,
                  style: DesignTokens.mediumRegular.copyWith(
                    color:
                        isSelected
                            ? DesignTokens.textWhite
                            : DesignTokens.chipsDefaultText,
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}
