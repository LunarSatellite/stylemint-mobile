/// The server's answer to a StyleMint reel like or unlike.
///
/// Pure-Dart domain entity — no JSON, no Dio.
class ReelLikeResult {
  const ReelLikeResult({required this.liked, this.likeCount});

  /// Whether the viewer now likes the reel.
  final bool liked;

  /// The reel's like count after the change (platform likes plus StyleMint
  /// likes). Null when the server did not send one.
  final int? likeCount;
}
