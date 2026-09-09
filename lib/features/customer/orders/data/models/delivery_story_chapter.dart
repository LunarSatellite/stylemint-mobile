class DeliveryStoryChapter {
  const DeliveryStoryChapter({
    required this.sequence,
    required this.title,
    required this.subtitle,
    required this.occurredUtc,
  });

  final int sequence;
  final String title;
  final String subtitle;
  final DateTime occurredUtc;

  factory DeliveryStoryChapter.fromJson(Map<String, dynamic> json) =>
      DeliveryStoryChapter(
        sequence: (json['sequence'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitleMarkdown'] as String? ?? '',
        occurredUtc: DateTime.tryParse(json['occurredUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}
