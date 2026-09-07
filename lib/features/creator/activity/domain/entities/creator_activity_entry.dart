class CreatorActivityEntry {
  const CreatorActivityEntry({
    required this.id,
    required this.kind,
    this.headline,
    this.body,
    this.actionUrl,
    required this.occurredUtc,
  });

  final String id;
  final int kind;
  final String? headline;
  final String? body;
  final String? actionUrl;
  final DateTime occurredUtc;
}
