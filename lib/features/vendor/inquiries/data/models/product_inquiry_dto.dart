/// `ProductInquiryDto` from `/v1/product-inquiries/vendor`.
/// State enum (int): Open=1, Replied=2, Expired=3.
enum ProductInquiryState {
  open(1, 'Open'),
  replied(2, 'Replied'),
  expired(3, 'Expired');

  const ProductInquiryState(this.value, this.label);
  final int value;
  final String label;

  static ProductInquiryState fromValue(int v) =>
      values.firstWhere((e) => e.value == v,
          orElse: () => ProductInquiryState.open);
}

class ProductInquiryDto {
  const ProductInquiryDto({
    required this.id,
    required this.question,
    required this.state,
    required this.openedUtc,
    required this.responseDeadlineUtc,
    required this.reply,
    required this.repliedUtc,
  });

  final String id;
  final String question;
  final ProductInquiryState state;
  final DateTime? openedUtc;
  final DateTime? responseDeadlineUtc;
  final String? reply;
  final DateTime? repliedUtc;

  factory ProductInquiryDto.fromJson(Map<String, dynamic> json) {
    return ProductInquiryDto(
      id: (json['id'] as String?) ?? '',
      question: (json['question'] as String?) ?? '',
      state: ProductInquiryState.fromValue((json['state'] as num?)?.toInt() ?? 1),
      openedUtc: DateTime.tryParse(json['openedUtc'] as String? ?? ''),
      responseDeadlineUtc:
          DateTime.tryParse(json['responseDeadlineUtc'] as String? ?? ''),
      reply: json['reply'] as String?,
      repliedUtc: DateTime.tryParse(json['repliedUtc'] as String? ?? ''),
    );
  }
}
