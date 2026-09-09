enum DropPartyStatus { scheduled, live, ended, cancelled }

class DropParty {
  const DropParty({
    required this.id,
    required this.creatorProfileId,
    required this.vendorProfileId,
    required this.reelId,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.duration,
    required this.joinCode,
    required this.status,
    required this.attendeeCount,
    required this.reelIsOrphaned,
    this.wentLiveAt,
    this.endedAt,
    this.cancellationReason,
  });

  final String id;
  final String creatorProfileId;
  final String vendorProfileId;
  final String reelId;
  final String title;
  final String description;
  final DateTime startsAt;
  final Duration duration;
  final String joinCode;
  final DropPartyStatus status;
  final int attendeeCount;
  final bool reelIsOrphaned;
  final DateTime? wentLiveAt;
  final DateTime? endedAt;
  final String? cancellationReason;

  DateTime get endsAt => startsAt.add(duration);
}
