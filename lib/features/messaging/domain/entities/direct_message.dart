/// A single text message inside a [MessageThread]. v1 carries only body
/// text; attachment ids will be added when the backend lands them.
class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.threadId,
    required this.senderAccountId,
    required this.body,
    required this.sentUtc,
  });

  final String id;
  final String threadId;
  final String senderAccountId;
  final String body;
  final DateTime sentUtc;
}
