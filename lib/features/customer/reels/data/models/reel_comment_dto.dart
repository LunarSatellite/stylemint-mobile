/// `ReelCommentDto` from `/v1/customer/reels/{reelId}/comments`.
class ReelCommentDto {
  const ReelCommentDto({
    required this.id,
    required this.body,
    required this.likeCount,
    required this.parentCommentId,
    required this.createdUtc,
    required this.authorDisplayName,
    required this.authorAvatarUrl,
  });

  final String id;
  final String body;
  final int likeCount;
  final String? parentCommentId;
  final DateTime? createdUtc;
  final String? authorDisplayName;
  final String? authorAvatarUrl;

  factory ReelCommentDto.fromJson(Map<String, dynamic> json) {
    return ReelCommentDto(
      id: (json['id'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      parentCommentId: json['parentCommentId'] as String?,
      createdUtc: DateTime.tryParse(json['createdUtc'] as String? ?? ''),
      authorDisplayName: json['authorDisplayName'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
    );
  }
}
