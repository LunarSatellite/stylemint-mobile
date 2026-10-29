import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/size_advice_strings.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/product_page_providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Runs small — many shoppers chose one size up" beside the size picker,
/// with the basis underneath. Draws nothing while loading, on error, when the
/// server has no advice, or once dismissed. Purely advisory: it never gates
/// add-to-cart.
class SizeAdviceLine extends ConsumerStatefulWidget {
  const SizeAdviceLine({
    required this.productId,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final String productId;
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<SizeAdviceLine> createState() => _SizeAdviceLineState();
}

class _SizeAdviceLineState extends ConsumerState<SizeAdviceLine> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final advice = ref
        .watch(productSizeAdviceProvider(widget.productId))
        .asData
        ?.value;
    if (advice == null) return const SizedBox.shrink();
    final headline = SizeAdviceStrings.of(context, advice.adviceKey);
    if (headline == null) return const SizedBox.shrink();
    final basisKey = advice.basisKey;
    final basis = basisKey == null
        ? null
        : SizeAdviceStrings.of(context, basisKey);

    return Padding(
      padding: widget.padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.straighten,
              size: 18,
              color: DesignTokens.primaryGreen,
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: DesignTokens.textLight,
                  ),
                ),
                if (basis != null)
                  Text(
                    basis,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      height: 1.4,
                      color: DesignTokens.textLight,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('size-advice-dismiss'),
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            tooltip: SizeAdviceStrings.of(context, 'size_advice.dismiss'),
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}
