enum InquiryStatus {
  open,
  replied,
  expired;

  String get label => switch (this) {
        InquiryStatus.open => 'Open',
        InquiryStatus.replied => 'Replied',
        InquiryStatus.expired => 'Expired',
      };
}

class ProductInquiry {
  const ProductInquiry({
    required this.id,
    required this.question,
    required this.status,
    this.openedAt,
    this.responseDeadlineAt,
    this.reply,
    this.repliedAt,
  });

  final String id;
  final String question;
  final InquiryStatus status;
  final DateTime? openedAt;
  final DateTime? responseDeadlineAt;
  final String? reply;
  final DateTime? repliedAt;

  ProductInquiry copyWith({
    String? id,
    String? question,
    InquiryStatus? status,
    DateTime? openedAt,
    DateTime? responseDeadlineAt,
    String? reply,
    DateTime? repliedAt,
  }) {
    return ProductInquiry(
      id: id ?? this.id,
      question: question ?? this.question,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      responseDeadlineAt: responseDeadlineAt ?? this.responseDeadlineAt,
      reply: reply ?? this.reply,
      repliedAt: repliedAt ?? this.repliedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductInquiry &&
      other.id == id &&
      other.question == question &&
      other.status == status &&
      other.openedAt == openedAt &&
      other.responseDeadlineAt == responseDeadlineAt &&
      other.reply == reply &&
      other.repliedAt == repliedAt;

  @override
  int get hashCode => Object.hash(
        id,
        question,
        status,
        openedAt,
        responseDeadlineAt,
        reply,
        repliedAt,
      );
}
