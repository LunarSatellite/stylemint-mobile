import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';

/// `PostMediaUploadDto` from `POST /v1/social/media`:
/// `{ url, mediaType, contentType, sizeBytes, width?, height?,
/// durationSeconds?, thumbnailUrl? }`. `mediaType` is the backend enum
/// (Image = 1, Video = 2), serialized as a number; a string name is accepted
/// too. Hand-written rather than freezed — it is a flat read-only shape.
class PostMediaUploadDto {
  const PostMediaUploadDto({
    required this.url,
    required this.kind,
    required this.contentType,
    this.width,
    this.height,
    this.durationSeconds,
    this.thumbnailUrl,
  });

  factory PostMediaUploadDto.fromJson(Map<String, dynamic> json) {
    final contentType = (json['contentType'] ?? '').toString();
    return PostMediaUploadDto(
      url: (json['url'] ?? '').toString(),
      kind: _kindOf(json['mediaType'], contentType),
      contentType: contentType,
      width: _positiveInt(json['width']),
      height: _positiveInt(json['height']),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  final String url;
  final PostMediaKind kind;
  final String contentType;
  final int? width;
  final int? height;
  final int? durationSeconds;
  final String? thumbnailUrl;

  UploadedPostMedia toDomain() => UploadedPostMedia(
    url: url,
    kind: kind,
    contentType: contentType,
    width: width,
    height: height,
    durationSeconds: durationSeconds,
    thumbnailUrl: thumbnailUrl,
  );

  static PostMediaKind _kindOf(Object? raw, String contentType) {
    if (raw == 2 || (raw is String && raw.toLowerCase() == 'video')) {
      return PostMediaKind.video;
    }
    if (raw == null && contentType.startsWith('video/')) {
      return PostMediaKind.video;
    }
    return PostMediaKind.image;
  }

  static int? _positiveInt(Object? raw) {
    final value = (raw as num?)?.toInt();
    return value != null && value > 0 ? value : null;
  }
}
