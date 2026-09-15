import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_like_result.dart';

/// DTO for `POST` / `DELETE /v1/customer/reels/{reelId}/like`:
/// `{ "reelId": "...", "liked": true, "likeCount": 129 }`.
///
/// Parsed tolerantly: a missing `liked` falls back to the state the request
/// asked for, and a missing `likeCount` stays null so the caller keeps its
/// own count.
class ReelLikeResponseDto {
  const ReelLikeResponseDto({
    required this.liked,
    this.reelId,
    this.likeCount,
  });

  factory ReelLikeResponseDto.fromJson(
    Object? json, {
    required bool requestedLiked,
  }) {
    final map = json is Map ? json : const <String, dynamic>{};
    final liked = map['liked'];
    final count = map['likeCount'];
    final reelId = map['reelId'];
    return ReelLikeResponseDto(
      reelId: reelId is String ? reelId : null,
      liked: liked is bool ? liked : requestedLiked,
      likeCount: count is num ? count.toInt() : null,
    );
  }

  final String? reelId;
  final bool liked;
  final int? likeCount;

  ReelLikeResult toDomain() => ReelLikeResult(
    liked: liked,
    likeCount: likeCount == null || likeCount! < 0 ? null : likeCount,
  );
}
