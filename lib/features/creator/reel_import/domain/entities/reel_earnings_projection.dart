import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/tag_product_commission.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// What a basket of tagged products earns per sale — and, just as important,
/// how much of the basket that figure actually covers.
///
/// ## What this replaced
///
/// The Tag Products screen summed `product.price.amount * 0.10` over the
/// tagged products, called it "Est. Potential Earnings", broke it down per
/// product as `12 * ~Rs 300 = ~Rs 3,600 (est.)`, and handed the same
/// invention to the Review and Published screens as
/// `ReviewReelArgs.potentialEarningsPerSale`, an `int` that multiplied it by
/// fifty. Ten percent was not a rate anybody had agreed to. It was the same
/// fabrication that had already been removed from the product chips on that
/// very screen, which meant a creator could read a real partnership rate on a
/// card and a made-up projection built from ten percent in the header above
/// it.
///
/// The money now comes from [TagProductCommission.commissionPerSale], as the
/// server computed it. The client adds those figures up and multiplies by a
/// stated number of hypothetical sales; it never derives a rate.
///
/// ## Why a type and not a nullable `Money`
///
/// A bare `Money?` answers "what is the total" and cannot answer "the total
/// of what". The interesting basket is the mixed one — two products with a
/// partnership, three without an answer — and a sum over only the products
/// that answered, presented as *the* total, is a false statement about
/// someone's income. So the projection carries its own coverage:
/// [statedProducts] against [unknownProducts]. Every screen that draws the
/// figure is then obliged to say what it covers, or to draw nothing.
///
/// ## The three answers a tagged product can give
///
/// * **`Applies` with a `CommissionPerSale`** — a stated figure. It is added.
///   A rate of `0` with a `Rs 0.00` per-sale figure is a *recorded zero*: it
///   is added, contributes nought, and counts as covered. Zero earnings that
///   somebody agreed to are knowledge, not ignorance.
/// * **`NoPartnership`** — a stated *none*. The server answered: no
///   partnership covers this product, so nothing is earned on it. It
///   contributes nothing and counts as **covered**, because the answer is
///   known. It supplies no `Money`, and none is invented for it.
/// * **`ProductUnavailable`, an unrecognised status, an `Applies` row with no
///   per-sale money, a lookup still in flight, a lookup that failed** — no
///   answer. It counts as [unknownProducts]. Nothing is assumed about it and
///   it never contributes a zero.
class ReelEarningsProjection {
  const ReelEarningsProjection({
    required this.perSale,
    required this.statedProducts,
    required this.unknownProducts,
  });

  /// Folds one answer per tagged product, in any order. A `null` entry is a
  /// product whose answer has not arrived, failed, or was never returned.
  factory ReelEarningsProjection.fold(Iterable<TagProductCommission?> answers) {
    final stated = <Money>[];
    var statedNone = 0;
    var unknown = 0;

    for (final answer in answers) {
      if (answer == null) {
        unknown++;
        continue;
      }
      switch (answer.status) {
        case TagProductCommissionStatus.productUnavailable:
          unknown++;
        case TagProductCommissionStatus.noPartnership:
          statedNone++;
        case TagProductCommissionStatus.applies:
          final perSale = answer.commissionPerSale;
          if (perSale == null) {
            // `Applies` that states a rate but no money: the percent can be
            // shown on the card, the rupees cannot be guessed from it here.
            unknown++;
          } else {
            stated.add(perSale);
          }
      }
    }

    final currencies = stated.map((m) => m.currency).toSet();
    if (currencies.length > 1) {
      // Two currencies cannot be added into one figure, and converting them
      // would invent a rate of a different kind. Nothing is claimed.
      return ReelEarningsProjection(
        perSale: null,
        statedProducts: statedNone,
        unknownProducts: unknown + stated.length,
      );
    }

    return ReelEarningsProjection(
      perSale: stated.isEmpty
          ? null
          : Money(
              amount: stated.fold<double>(0, (sum, m) => sum + m.amount),
              currency: currencies.single,
            ),
      statedProducts: statedNone + stated.length,
      unknownProducts: unknown,
    );
  }

  /// Nothing tagged, so nothing projected.
  static const empty = ReelEarningsProjection(
    perSale: null,
    statedProducts: 0,
    unknownProducts: 0,
  );

  /// The commission earned if one of every covered product sells once.
  ///
  /// `null` when not one tagged product supplied a money figure — never a
  /// `Rs 0` standing in for that. A basket whose every product is
  /// `NoPartnership` is fully covered ([coversEverything]) and still has no
  /// [perSale]: there is a true answer to give and it is not a numeral.
  final Money? perSale;

  /// Tagged products whose commission outcome the server stated — whether
  /// that outcome was a figure, a recorded zero, or "no partnership".
  final int statedProducts;

  /// Tagged products with no stated outcome. They contribute nothing and are
  /// never counted as zero.
  final int unknownProducts;

  int get totalProducts => statedProducts + unknownProducts;

  /// There is a money figure to draw.
  bool get hasFigure => perSale != null;

  /// Something is known and something is not: any figure drawn must say what
  /// it covers.
  bool get isPartial => statedProducts > 0 && unknownProducts > 0;

  /// Every tagged product answered.
  bool get coversEverything => statedProducts > 0 && unknownProducts == 0;

  /// Not one product answered — there is nothing honest to draw at all.
  bool get isSilent => statedProducts == 0;

  /// [perSale] over a stated number of hypothetical sales, or `null`.
  ///
  /// The multiplier is a scenario the screen names out loud ("with 50
  /// sales"), not a claim; the per-sale money it multiplies is the server's.
  Money? projectedOver(int sales) {
    final base = perSale;
    if (base == null) return null;
    return Money(amount: base.amount * sales, currency: base.currency);
  }
}
