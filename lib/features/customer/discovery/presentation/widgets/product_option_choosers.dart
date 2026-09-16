import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_option_chooser.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One chooser row per product option, in `sortOrder`: Size and similar as
/// pills, Colour as swatches. Values that no variant sells, or whose variant
/// is out of stock, render greyed and unselectable with a short reason.
class ProductOptionChoosers extends StatelessWidget {
  const ProductOptionChoosers({required this.chooser, super.key});

  final ProductOptionChooser chooser;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProductOptionSelection>(
      valueListenable: chooser,
      builder: (context, selection, _) {
        if (selection.isEmpty) return const SizedBox.shrink();
        final reason = selection.unavailableReason;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final option in selection.options) ...[
              _OptionRow(
                option: option,
                selection: selection,
                onSelected: chooser.select,
              ),
              const SizedBox(height: DesignTokens.s16),
            ],
            if (reason != null)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: Text(
                  reason,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selection,
    required this.onSelected,
  });

  final ProductOption option;
  final ProductOptionSelection selection;
  final void Function(String optionId, String valueId) onSelected;

  @override
  Widget build(BuildContext context) {
    final pickedId = selection.picked[option.id];
    final picked = option.values
        .where((value) => value.id == pickedId)
        .map((value) => value.value)
        .join();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            picked.isEmpty
                ? 'Select ${option.name}'
                : '${option.name}: $picked',
            style: DesignTokens.smallRegular.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.textLight,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Wrap(
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s8,
          children: [
            for (final value in option.values)
              _ValueCell(
                option: option,
                value: value,
                selected: value.id == pickedId,
                availability: selection.availabilityOf(option.id, value.id),
                onTap: () => onSelected(option.id, value.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.option,
    required this.value,
    required this.selected,
    required this.availability,
    required this.onTap,
  });

  final ProductOption option;
  final ProductOptionValue value;
  final bool selected;
  final OptionValueAvailability availability;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = availability.isSelectable;
    final reason = availability.reason;
    // The swatch is never the only cue: the value name is spoken and, for
    // colours, printed under the chip.
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: reason == null
          ? '${option.name} ${value.value}'
          : '${option.name} ${value.value}, $reason',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: option.isSwatch
              ? _Swatch(value: value, selected: selected)
              : _Pill(label: value.value, selected: selected),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: DesignTokens.minTouchTarget,
        minWidth: DesignTokens.minTouchTarget,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s8,
      ),
      decoration: selected
          ? DesignTokens.chipDecorationSelected()
          : DesignTokens.chipDecorationDefault(),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DesignTokens.mediumSemibold.copyWith(
          color: selected
              ? DesignTokens.primaryGreen
              : DesignTokens.chipsDefaultText,
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.value, required this.selected});

  final ProductOptionValue value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colour = value.swatchColor;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: DesignTokens.minTouchTarget,
            height: DesignTokens.minTouchTarget,
            decoration: BoxDecoration(
              color: colour ?? DesignTokens.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? DesignTokens.primaryGreen
                    : DesignTokens.borderDefault,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: colour == null
                ? const Icon(
                    Icons.palette_outlined,
                    size: 18,
                    color: DesignTokens.textMuted,
                  )
                : null,
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            value.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: DesignTokens.smallRegular.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? DesignTokens.textWhite
                  : DesignTokens.chipsDefaultText,
            ),
          ),
        ],
      ),
    );
  }
}
