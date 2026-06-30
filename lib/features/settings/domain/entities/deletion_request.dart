class DeletionRequest {
  const DeletionRequest({
    required this.id,
    required this.requestedAt,
    this.scheduledDeletionAt,
  });

  final String id;
  final DateTime requestedAt;
  final DateTime? scheduledDeletionAt;
}
