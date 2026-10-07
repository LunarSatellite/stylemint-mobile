/// Photo or video on a post. Matches the backend's `PostMediaKind`
/// (Image = 1, Video = 2).
enum PostMediaKind { image, video }

/// The composer's limits, mirrored from the backend: `CreatePostVmValidator`
/// (up to 10 photos, or one video alone) and `IPostMediaUploadService`
/// (10 MB per photo; per video 60 s and, for now, 24 MB — see below).
abstract final class PostMediaLimits {
  static const int maxPhotos = 10;
  static const int maxPhotoBytes = 10 * 1024 * 1024;
  // The API accepts 60 MB, but the public nginx in front of it still caps
  // request bodies at 25 MB (raise client_max_body_size for /v1/social/media,
  // then lift this). Refusing here gives a clear message instead of a 413.
  static const int maxVideoBytes = 24 * 1024 * 1024;
  static int get maxVideoMegabytes => maxVideoBytes ~/ (1024 * 1024);
  static const Duration maxVideoDuration = Duration(seconds: 60);
}

/// A file staged by `POST /v1/social/media`. Posts reference it by [url];
/// the size fields go into `CreatePostVm.Media` (`widthPx`, `heightPx`,
/// `durationSeconds`). The server reads them from the file header when it
/// can, so any of them may be null here.
class UploadedPostMedia {
  const UploadedPostMedia({
    required this.url,
    required this.kind,
    required this.contentType,
    this.width,
    this.height,
    this.durationSeconds,
    this.thumbnailUrl,
  });

  final String url;
  final PostMediaKind kind;
  final String contentType;
  final int? width;
  final int? height;
  final int? durationSeconds;
  final String? thumbnailUrl;

  bool get isVideo => kind == PostMediaKind.video;

  UploadedPostMedia copyWith({
    String? url,
    PostMediaKind? kind,
    String? contentType,
    int? width,
    int? height,
    int? durationSeconds,
    String? thumbnailUrl,
  }) {
    return UploadedPostMedia(
      url: url ?? this.url,
      kind: kind ?? this.kind,
      contentType: contentType ?? this.contentType,
      width: width ?? this.width,
      height: height ?? this.height,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}

const _videoExtensions = {'mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'};

/// Whether a post media URL points at a video. Posts carry their media as a
/// flat list of URLs (`PostDto.images`), and the upload endpoint stores every
/// video under a `.mp4` / `.mov` name, so the extension is the signal.
bool isVideoMediaUrl(String url) {
  var path = url;
  final cut = path.indexOf(RegExp('[?#]'));
  if (cut >= 0) path = path.substring(0, cut);
  final slash = path.lastIndexOf('/');
  final name = slash >= 0 ? path.substring(slash + 1) : path;
  final dot = name.lastIndexOf('.');
  if (dot < 0) return false;
  return _videoExtensions.contains(name.substring(dot + 1).toLowerCase());
}
