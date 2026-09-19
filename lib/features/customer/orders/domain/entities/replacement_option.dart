import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class ReplacementOption {
  const ReplacementOption({
    required this.variantId,
    required this.label,
    required this.price,
  });

  factory ReplacementOption.fromJson(Map<String, dynamic> json) =>
      ReplacementOption(
        variantId: json['variantId'] as String? ?? '',
        label: json['label'] as String? ?? 'Variant',
        price: Money(
          amount: (json['priceAmount'] as num?)?.toDouble() ?? 0,
          currency: json['priceCurrency'] as String? ?? 'NPR',
        ),
      );

  final String variantId;
  final String label;
  final Money price;
}

enum ReturnResolutionChoice { refund, replacement }
