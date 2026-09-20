import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_figures.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The recorded figures for one partnership, on the brand card.
///
/// ## The distinction this widget exists to hold
///
/// `GET /v1/creator/partnerships/{id}/affiliate-earnings` answers one of two
/// genuinely different things, and they must never look the same:
///
/// * **`Unknown`** — no affiliate link carries this partnership, so nobody
///   can say what it earned. Every total comes back null. The card draws
///   [_NotTrackedBlock]: a muted outlined chip reading **"Not tracked for
///   this brand yet"**, the sentence about where earnings really are kept,
///   and a link to Earnings. **No numeral appears anywhere in it.**
/// * **`Attributed`** — the links were attributed and the totals are real.
///   The card draws [_RecordedBlock]: a green **"Recorded for this brand"**
///   chip and the figures, **including a zero**. `TotalEarnings: 0` here is
///   a recorded zero and is printed as "Rs 0.00 earned", because the creator
///   asked what they made from this brand and the true answer is nothing.
///
/// A zero drawn under a green "Recorded" chip and an absence drawn under a
/// muted "Not tracked" chip are the two halves of the contract. Collapsing
/// them back into one presentation would re-create the defect the removal
/// commit fixed, in the opposite direction.
///
/// ## Multiple currencies
///
/// `Currencies` is a list. More than one entry means the totals were summed
/// across currencies, and **no single amount can stand for them** — the sum
/// of 1,000 NPR and 40 USD is not a number. In that case the amount line is
/// replaced by the currencies themselves and a pointer to Earnings; the
/// currency-free counts (sales, clicks) are still real and are still drawn.
///
/// ## Products tagged
///
/// A separate, simpler contract with no unknown state:
/// `Reels.TaggedProduct.PartnershipIdSnapshot` has been written at tag time
/// since tagging began, so **zero is a recorded zero** and "0 products
/// tagged" is printed as such.
///
/// ## What is still absent
///
/// **Active campaigns.** There is no source for it — `Catalog.Campaign` is an
/// editorial hero, `BrandStudio.CampaignWorkspace` is vendor-scoped with no
/// creator link. It gets no row, no chip and no zero.
class PartnershipFiguresSection extends ConsumerWidget {
  const PartnershipFiguresSection({required this.partnershipId, super.key});

  final String partnershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(
      partnershipAffiliateEarningsProvider(partnershipId),
    );
    final tags = ref.watch(partnershipTagCountsProvider(partnershipId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        earnings.when(
          data: (e) => e.isAttributed
              ? _RecordedBlock(earnings: e)
              : _NoFiguresBlock(
                  reason: _NoFigureReason.unknown,
                  unattributedLinkCountForPair: e.unattributedLinkCountForPair,
                ),
          // A request still in flight and a request that failed are both
          // "no attributed figure here", and both draw the same block under
          // a heading that says which one it is. Neither invents a total and
          // neither falls back to a zero — the sentence they carry is about
          // the earnings ledger, which genuinely has no partnership
          // dimension, so it stays true in every one of these three states.
          loading: () => const _NoFiguresBlock(
            reason: _NoFigureReason.pending,
          ),
          error: (_, _) => const _NoFiguresBlock(
            reason: _NoFigureReason.unavailable,
          ),
        ),
        // Recorded for every partnership, so it is drawn whenever it loads —
        // including when it loads as zero. It is never drawn when it did not
        // load, because "absent" and "none" are different again.
        tags.maybeWhen(
          data: (t) => Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s8),
            child: _TagCountsLine(counts: t),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Not tracked ──────────────────────────────────────────────────────────────

/// Why there is no attributed figure to draw. Each one is a different true
/// statement and gets its own heading; none of them is a number.
enum _NoFigureReason {
  /// The server answered `Unknown`: no affiliate link carries this
  /// partnership, so no total exists to state.
  unknown('Not tracked for this brand yet', Icons.help_outline_rounded),

  /// The answer has not come back yet. Says so rather than guessing which
  /// of the other two it will turn out to be.
  pending('Checking what this brand recorded…', Icons.hourglass_empty_rounded),

  /// The read failed. A request that did not come back is exactly as
  /// unattributable as an `Unknown` answer — and just as far from a zero.
  unavailable(
    'Could not load what this brand recorded',
    Icons.cloud_off_rounded,
  );

  const _NoFigureReason(this.heading, this.icon);

  final String heading;
  final IconData icon;
}

/// The no-figure presentation: a scope, a sentence and a way out. **No
/// numeral appears in it**, in any of its three reasons.
///
/// This is the line between **"you earned nothing here"** and **"we did not
/// look"**. A creator who genuinely earned nothing from a brand sees a zero
/// under the green "Recorded for this brand" chip, or on Earnings, against a
/// ledger that was actually queried. This block cannot say either way, so it
/// says neither — no zero, no dash, no empty chip holding the slot a number
/// belongs in.
///
/// The sentence it carries is the interim copy written when nothing at all
/// was recorded per partnership, and it is kept here because it is still
/// true here: Payouts' `EarningsLedgerEntry` is the system of record for
/// creator money and has no partnership and no vendor dimension. The new
/// affiliate figures are a different source — link attribution — which is
/// why the `Attributed` card drops this sentence rather than printing a
/// per-partnership total directly beneath "not per partnership".
class _NoFiguresBlock extends StatelessWidget {
  const _NoFiguresBlock({
    required this.reason,
    this.unattributedLinkCountForPair = 0,
  });

  final _NoFigureReason reason;

  /// Affiliate links between this creator and this vendor that carry no
  /// partnership at all. A **completeness signal**, not an attribution
  /// claim: it says why the server cannot answer, and the copy below is
  /// careful to disclaim rather than imply that those links are this
  /// partnership's. Drawn only when there are some — with none, there is
  /// nothing to explain.
  final int unattributedLinkCountForPair;

  static const _message =
      'StyleMint records your earnings across all your brands together, not '
      'per partnership. See Earnings for what you have actually made.';

  String get _unattributedNote {
    final n = unattributedLinkCountForPair;
    final links = n == 1 ? 'affiliate link' : 'affiliate links';
    final carry = n == 1 ? 'carries' : 'carry';
    return '$n $links between you and this brand $carry no partnership at '
        'all, which is why nothing can be attributed here. They are not '
        'earnings on this partnership.';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${reason.heading}. Earnings are not recorded per partnership. '
          '$_message'
          '${unattributedLinkCountForPair > 0 ? ' $_unattributedNote' : ''}',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(RouteNames.earnings),
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusChip(
                label: reason.heading,
                icon: reason.icon,
                foreground: DesignTokens.textMuted,
                background: DesignTokens.bgAppBodyLight,
                border: DesignTokens.glassStroke,
              ),
              const SizedBox(height: DesignTokens.s8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    height: 1.4,
                    color: DesignTokens.textMuted,
                  ),
                  children: [
                    TextSpan(text: _message),
                    TextSpan(
                      text: '  Open Earnings',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.primaryGreen,
                        decoration: TextDecoration.underline,
                        decorationColor: DesignTokens.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              if (unattributedLinkCountForPair > 0) ...[
                const SizedBox(height: DesignTokens.s4),
                Text(
                  _unattributedNote,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 11,
                    height: 1.4,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recorded ─────────────────────────────────────────────────────────────────

/// The `Attributed` presentation: real figures, zero included.
class _RecordedBlock extends StatelessWidget {
  const _RecordedBlock({required this.earnings});

  final PartnershipAffiliateEarnings earnings;

  /// The headline. Under a single currency this is the amount — and "Rs 0.00
  /// earned" is a legitimate, recorded answer, not a placeholder.
  ///
  /// With no currency at all there were no conversions, so there is no
  /// currency to print an amount in; the zero is carried by the counts line
  /// instead of being dressed in a currency nobody recorded.
  String _headline() {
    if (earnings.spansMultipleCurrencies) {
      return 'Earned in ${earnings.currencies.length} currencies: '
          '${earnings.currencies.join(', ')}';
    }
    final currency = earnings.singleCurrency;
    final amount = earnings.totalEarnings;
    if (currency != null && amount != null) {
      return '${formatMoney(Money(amount: amount, currency: currency))} '
          'earned';
    }
    if (amount == null) return 'Recorded, with no total on this answer';
    return amount == 0 ? 'Nothing earned yet' : '$amount earned';
  }

  /// Conversions and clicks. Currency-free, so they are drawn even when the
  /// totals span currencies, and a zero here is recorded like any other.
  String? _countsLine() {
    final sales = earnings.totalConversions;
    final clicks = earnings.totalClicks;
    if (sales == null && clicks == null) return null;
    final parts = <String>[
      if (sales != null) '$sales ${sales == 1 ? 'sale' : 'sales'}',
      if (clicks != null) '$clicks link ${clicks == 1 ? 'click' : 'clicks'}',
    ];
    return sales != null && clicks != null
        ? '${parts.first} from ${parts.last}'
        : parts.first;
  }

  /// Order value attributed to the links — not the creator's cut, and said so.
  /// Only when one currency makes it a real amount.
  String? _revenueLine() {
    final currency = earnings.singleCurrency;
    final revenue = earnings.totalRevenue;
    if (currency == null || revenue == null) return null;
    return '${formatMoney(Money(amount: revenue, currency: currency))} '
        'of orders attributed';
  }

  @override
  Widget build(BuildContext context) {
    final counts = _countsLine();
    final revenue = _revenueLine();
    final headline = _headline();
    return Semantics(
      label: <String>[
        'Recorded for this brand',
        headline,
        counts ?? '',
        revenue ?? '',
      ].where((s) => s.isNotEmpty).join('. '),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StatusChip(
              label: 'Recorded for this brand',
              icon: Icons.check_circle_outline_rounded,
              foreground: DesignTokens.primaryGreen,
              background: DesignTokens.primaryGreenLight,
              border: DesignTokens.primaryGreenLight,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              headline,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: DesignTokens.textWhite,
              ),
            ),
            if (earnings.spansMultipleCurrencies) ...[
              const SizedBox(height: DesignTokens.s4),
              const _MultiCurrencyNote(),
            ],
            if (counts != null) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(counts, style: _detailStyle),
            ],
            if (revenue != null) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(revenue, style: _detailStyle),
            ],
          ],
        ),
      ),
    );
  }
}

const TextStyle _detailStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 12,
  height: 1.4,
  color: DesignTokens.textLight,
);

/// Says why no single amount is printed, and where the per-currency figures
/// are. Adding currencies together would be a fabricated number with a
/// currency symbol on it.
class _MultiCurrencyNote extends StatelessWidget {
  const _MultiCurrencyNote();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'These totals span more than one currency, so they are not added '
          'into one amount. Open Earnings for the breakdown.',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(RouteNames.earnings),
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              height: 1.4,
              color: DesignTokens.textMuted,
            ),
            children: [
              TextSpan(
                text:
                    'These totals span more than one currency, so StyleMint '
                    'does not add them into one amount here.',
              ),
              TextSpan(
                text: '  Open Earnings',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.primaryGreen,
                  decoration: TextDecoration.underline,
                  decorationColor: DesignTokens.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Products tagged ──────────────────────────────────────────────────────────

/// "3 products tagged", and "0 products tagged" when that is what was
/// recorded — the snapshot exists for every partnership, so this zero is a
/// fact rather than a stand-in.
///
/// It counts **distinct products**, not tag rows: one product tagged in two
/// reels is one product, which is what "products tagged" means to a creator.
class _TagCountsLine extends StatelessWidget {
  const _TagCountsLine({required this.counts});

  final PartnershipTagCounts counts;

  String _label() {
    final products = counts.productCount;
    return '$products ${products == 1 ? 'product' : 'products'} tagged';
  }

  @override
  Widget build(BuildContext context) {
    final label = _label();
    return Semantics(
      label: '$label under this partnership',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.sell_outlined,
              size: 14,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(width: 6),
          // Expanded, not a bare Text: at 320dp with a 1.3 text scale
          // "0 products tagged in 0 reels" is wider than the room left beside
          // the icon, and an unbounded Text there overflows the row.
          Expanded(child: Text(label, style: _detailStyle)),
        ],
      ),
    );
  }
}

// ── Shared chip ──────────────────────────────────────────────────────────────

/// The one element that tells a reader which of the two answers they are
/// looking at, before they read a word of the copy.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      // Wrap, not Row: at 320dp with a 1.3 text scale "Not tracked for this
      // brand yet" is wider than the card and a Row overflows it.
      child: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 12, color: foreground),
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
