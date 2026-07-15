class RateTier {
  const RateTier({
    required this.tierName,
    required this.price,
    required this.includedReels,
    this.description,
  });

  final String tierName;
  final double price;
  final int includedReels;
  final String? description;

  factory RateTier.fromJson(Map<String, dynamic> json) => RateTier(
        tierName: (json['tierName'] as String?) ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        includedReels: (json['includedReels'] as num?)?.toInt() ?? 0,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'tierName': tierName,
        'price': price,
        'includedReels': includedReels,
        if (description != null && description!.isNotEmpty)
          'description': description,
      };
}

class CreatorRateCard {
  const CreatorRateCard({
    required this.id,
    required this.version,
    required this.effectiveFromUtc,
    required this.baseRate,
    required this.rates,
    required this.commissionPreference,
    required this.platformPreferences,
    required this.isActive,
    this.notes,
  });

  final String id;
  final int version;
  final DateTime effectiveFromUtc;
  final double baseRate;
  final List<RateTier> rates;
  final double commissionPreference;
  final List<String> platformPreferences;
  final bool isActive;
  final String? notes;

  factory CreatorRateCard.fromJson(Map<String, dynamic> json) => CreatorRateCard(
        id: (json['id'] as String?) ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
        effectiveFromUtc: json['effectiveFromUtc'] is String
            ? DateTime.tryParse(json['effectiveFromUtc'] as String) ??
                DateTime.now()
            : DateTime.now(),
        baseRate: (json['baseRate'] as num?)?.toDouble() ?? 0,
        rates: (json['rates'] as List<dynamic>? ?? const [])
            .map((e) => RateTier.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        commissionPreference:
            (json['commissionPreference'] as num?)?.toDouble() ?? 0,
        platformPreferences:
            (json['platformPreferences'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(growable: false),
        isActive: (json['isActive'] as bool?) ?? true,
        notes: json['notes'] as String?,
      );
}
