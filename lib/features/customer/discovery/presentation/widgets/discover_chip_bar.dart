import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feed.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_choice_chip.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Discover chips in one horizontally scrolling row. Its height follows
/// the text scale.
class DiscoverChipBar extends StatelessWidget {
  const DiscoverChipBar({
    required this.chips,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<DiscoverChip> chips;
  final DiscoverChip selected;
  final ValueChanged<DiscoverChip> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Discover feeds',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: DesignTokens.s16,
        ),
        child: Row(
          children: [
            for (final (index, chip) in chips.indexed) ...[
              if (index > 0) const SizedBox(width: DesignTokens.s8),
              MallChoiceChip(
                key: ValueKey('discover-chip-${chip.key}'),
                label: chip.label,
                selected: chip == selected,
                onTap: () => onSelected(chip),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
