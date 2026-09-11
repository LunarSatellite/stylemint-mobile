class DeliveryStoryChapter {
  const DeliveryStoryChapter({
    required this.sequence,
    required this.title,
    required this.subtitle,
    required this.occurredUtc,
    this.kind = DeliveryStoryChapterKind.unknown,
  });

  final int sequence;
  final String title;
  final String subtitle;
  final DateTime occurredUtc;
  final DeliveryStoryChapterKind kind;

  factory DeliveryStoryChapter.fromJson(Map<String, dynamic> json) =>
      DeliveryStoryChapter(
        sequence: (json['sequence'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitleMarkdown'] as String? ?? '',
        kind: DeliveryStoryChapterKind.fromCode(
          (json['kind'] as num?)?.toInt(),
        ),
        occurredUtc:
            DateTime.tryParse(json['occurredUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

enum DeliveryStoryChapterKind {
  unknown(0),
  sealed(1),
  pickedUp(2),
  onTheMove(3),
  handedOff(4),
  arrivedLocal(5),
  outForDelivery(6),
  delivered(7);

  const DeliveryStoryChapterKind(this.code);

  final int code;

  static DeliveryStoryChapterKind fromCode(int? code) =>
      DeliveryStoryChapterKind.values.firstWhere(
        (kind) => kind.code == code,
        orElse: () => DeliveryStoryChapterKind.unknown,
      );
}
