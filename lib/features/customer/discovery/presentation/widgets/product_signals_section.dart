import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The measured signals under a product's price: how many units really sold
/// in the last 30 days, whether stock is genuinely low, and how many
/// shoppers are on the page right now.
///
/// This block replaces the old `_UrgencyBanner`, which drew
/// "Only 7 left · 5 people added to cart recently" from two server-side
/// `Random` calls. The rules it lives by:
///
/// * **A null is not a zero.** Every figure here is optional, and an absent
///   one draws nothing — no "0 sold", no empty bar, no greyed placeholder.
///   "Nobody bought this" is a claim, and the backend is not making it.
/// * **The stock signal is coarse on purpose.** `isLowStock` is a boolean
///   because an exact remaining count is a vendor's inventory position and,
///   on a product page, a pressure tactic. There is no N to print, and none
///   is reconstructed here — the copy is the kit's own number-free
///   `onlyAFewLeft`, the same line the Mall cards use for the same boolean,
///   so a shopper cannot see the two surfaces disagree.
/// * **No velocity theatre.** Nothing here says "selling fast" or counts
///   cart-adds; the platform records neither.
///
/// The calm facts lead and the low-stock line comes last, so the block reads
/// as information rather than as a countdown.
class ProductSignalsSection extends ConsumerWidget {
  const ProductSignalsSection({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProductSignals(
      urgency: ref.watch(productUrgencyProvider(productId)).asData?.value,
      socialProof: ref
          .watch(productSocialProofProvider(productId))
          .asData
          ?.value,
    );
  }
}

/// The signals themselves, with no providers behind them, so the honesty
/// rules above can be tested directly.
class ProductSignals extends StatelessWidget {
  const ProductSignals({super.key, this.urgency, this.socialProof});

  final ProductUrgency? urgency;
  final ProductSocialProof? socialProof;

  /// Every signal that has a measurement behind it, in reading order.
  ///
  /// Returns an empty list when nothing was measured, which is the normal
  /// case: a shrink-wrapped nothing, not a heading over an empty space.
  List<MallSignal> signalsFor(MallStrings strings) {
    final proof = socialProof;
    final stock = urgency;
    final sold = proof?.unitsSoldLast30Days;
    // Viewers comes from either payload; both read the same Redis counter,
    // and both are null on every call in production today because nothing
    // writes that key. A value is the exception, not the baseline.
    final viewers = stock?.viewersRightNow ?? proof?.viewersRightNow;

    return [
      if (sold != null)
        MallSignal(
          label: '$sold sold in the last 30 days',
          icon: Icons.shopping_bag_outlined,
          semanticLabel:
              '$sold ${sold == 1 ? 'unit' : 'units'} sold in the last 30 days',
        ),
      if (viewers != null)
        MallSignal(
          label:
              '$viewers ${viewers == 1 ? 'shopper' : 'shoppers'} '
              'viewing now',
          icon: Icons.visibility_outlined,
        ),
      // True only; a false means "plenty in stock" and needs no line, and a
      // null means stock is unknown, which is not a thing to announce.
      if (stock?.isLowStock ?? false)
        MallSignal(
          label: strings.onlyAFewLeft,
          tone: MallSignalTone.urgent,
          icon: Icons.inventory_2_outlined,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final signals = signalsFor(MallStrings.of(context));
    if (signals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < signals.length; i++) ...[
            if (i > 0) const SizedBox(height: DesignTokens.s4),
            MallSignalLine(signal: signals[i]),
          ],
        ],
      ),
    );
  }
}
