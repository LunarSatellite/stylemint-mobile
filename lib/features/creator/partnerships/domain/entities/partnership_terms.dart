/// A headed group of terms bullets.
class PartnershipTermsSection {
  const PartnershipTermsSection({
    required this.heading,
    required this.bullets,
  });

  final String heading;
  final List<String> bullets;
}

/// One version of a partnership's terms.
class PartnershipTerms {
  const PartnershipTerms({
    required this.versionNumber,
    required this.whoCanJoin,
    required this.reelContentRules,
  });

  final int versionNumber;
  final PartnershipTermsSection whoCanJoin;
  final PartnershipTermsSection reelContentRules;
}

/// A money amount with the label formatting the UI displays.
class PartnershipMoney {
  const PartnershipMoney({required this.amount, required this.currency});

  final double amount;
  final String currency;

  String get label {
    final symbol = currency.toUpperCase() == 'NPR' ? 'Rs' : currency;
    return '$symbol ${amount.toStringAsFixed(0)}';
  }
}

/// Projected commission for a partnership, optionally for one variant.
class PotentialEarnings {
  const PotentialEarnings({
    required this.partnershipId,
    required this.productVariantId,
    required this.commissionRate,
    required this.unitPrice,
    required this.perSale,
    required this.perFiftySales,
    required this.salesAssumed,
  });

  final String partnershipId;
  final String productVariantId;
  final double commissionRate;
  final PartnershipMoney unitPrice;
  final PartnershipMoney perSale;
  final PartnershipMoney perFiftySales;

  /// The sales count [perFiftySales] projects from — sent by the backend so
  /// the copy stays truthful if the assumption ever changes.
  final int salesAssumed;
}

/// A reel recipe attached to a partnership brief.
class RecipeAttachmentInfo {
  const RecipeAttachmentInfo({
    required this.recipeId,
    required this.recipeVersion,
    required this.isHidden,
    this.title,
    this.thumbnailUrl,
  });

  final String recipeId;
  final int recipeVersion;
  final bool isHidden;
  final String? title;
  final String? thumbnailUrl;
}
