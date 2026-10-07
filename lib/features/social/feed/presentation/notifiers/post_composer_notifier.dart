import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/repositories/feed_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/post_media_picker_provider.dart';

/// Where one attached file is on its way to the server.
enum ComposerMediaStatus { waiting, uploading, uploaded, failed }

/// One photo/video attached in the post composer.
class ComposerMediaItem {
  const ComposerMediaItem({
    required this.id,
    required this.picked,
    this.status = ComposerMediaStatus.waiting,
    this.progress = 0,
    this.uploaded,
    this.error,
  });

  /// Local id, stable while the composer is open (list positions shift on
  /// remove).
  final int id;
  final PickedPostMedia picked;
  final ComposerMediaStatus status;

  /// 0–1 while [status] is uploading.
  final double progress;
  final UploadedPostMedia? uploaded;

  /// Why the last upload failed, for the tile and the retry prompt.
  final String? error;

  bool get isVideo => picked.isVideo;

  ComposerMediaItem _uploading(double progress) => ComposerMediaItem(
    id: id,
    picked: picked,
    status: ComposerMediaStatus.uploading,
    progress: progress,
  );

  ComposerMediaItem _done(UploadedPostMedia media) => ComposerMediaItem(
    id: id,
    picked: picked,
    status: ComposerMediaStatus.uploaded,
    progress: 1,
    uploaded: media,
  );

  ComposerMediaItem _failed(String message) => ComposerMediaItem(
    id: id,
    picked: picked,
    status: ComposerMediaStatus.failed,
    error: message,
  );
}

/// The composer's attachments. A plain immutable value (the feed's freezed
/// unions are generated; this screen-local list of per-file upload states is
/// not a load/success/failure shape anyway).
class PostComposerState {
  const PostComposerState({this.items = const []});

  final List<ComposerMediaItem> items;

  bool get hasVideo => items.any((item) => item.isVideo);

  bool get isUploading =>
      items.any((item) => item.status == ComposerMediaStatus.uploading);

  bool get hasFailedUpload =>
      items.any((item) => item.status == ComposerMediaStatus.failed);

  /// Photos may be added while no video is attached, up to the limit.
  int get photoSlotsLeft =>
      hasVideo ? 0 : PostMediaLimits.maxPhotos - items.length;

  bool get canAddPhotos => !isUploading && photoSlotsLeft > 0;

  /// A video is a post on its own, so it can only be added to an empty
  /// composer (Instagram/Facebook: a carousel of photos, or one video).
  bool get canAddVideo => !isUploading && items.isEmpty;
}

/// Holds what the composer has attached and uploads it to
/// `POST /v1/social/media` before the post is created. Creating the post
/// itself stays with `FeedNotifier.createPost`, which puts it in the feed.
class PostComposerNotifier extends StateNotifier<PostComposerState> {
  PostComposerNotifier(this._repository) : super(const PostComposerState());

  final FeedRepository _repository;
  int _nextId = 0;

  /// Attaches gallery/camera photos. Returns how many were left out because
  /// the post was full (or a video is attached).
  int addPhotos(List<PickedPostMedia> photos) {
    final fitting = photos
        .where((photo) => !photo.isVideo)
        .take(state.photoSlotsLeft)
        .toList(growable: false);
    if (fitting.isNotEmpty) {
      state = PostComposerState(
        items: [
          ...state.items,
          for (final photo in fitting)
            ComposerMediaItem(id: _nextId++, picked: photo),
        ],
      );
    }
    return photos.length - fitting.length;
  }

  /// Attaches a video. Returns false when it can't be: something is already
  /// attached, or the clip is over the length limit.
  bool setVideo(PickedPostMedia video) {
    if (!state.canAddVideo || !video.isVideo || isTooLong(video)) return false;
    state = PostComposerState(
      items: [ComposerMediaItem(id: _nextId++, picked: video)],
    );
    return true;
  }

  /// Over 60 s (a second of slack for the picker's rounding), when known.
  static bool isTooLong(PickedPostMedia video) {
    final duration = video.duration;
    return duration != null &&
        duration >
            PostMediaLimits.maxVideoDuration + const Duration(seconds: 1);
  }

  /// Detaches an item. An upload in flight can't be cancelled, so its tile
  /// has no remove button and this ignores it.
  void remove(int id) {
    final item = _find(id);
    if (item == null || item.status == ComposerMediaStatus.uploading) return;
    state = PostComposerState(
      items: [
        for (final other in state.items)
          if (other.id != id) other,
      ],
    );
  }

  /// Uploads every attachment not yet on the server, in order, one at a
  /// time (each tile shows its own progress). Already-uploaded ones are
  /// kept, so after a failure "Post" again only retries what failed.
  ///
  /// Returns the media for `createPost`, sizes merged, or null when anything
  /// failed to upload.
  Future<List<UploadedPostMedia>?> uploadAll() async {
    for (final id in [for (final item in state.items) item.id]) {
      await _upload(id);
      if (!mounted) return null;
    }
    final items = state.items;
    if (items.any((item) => item.uploaded == null)) return null;
    return [for (final item in items) _forPost(item)];
  }

  /// Re-uploads one failed attachment (the tile's retry button).
  Future<void> retry(int id) => _upload(id);

  Future<void> _upload(int id) async {
    final item = _find(id);
    if (item == null ||
        item.uploaded != null ||
        item.status == ComposerMediaStatus.uploading) {
      return;
    }
    _replace(id, (current) => current._uploading(0));

    final either = await _repository.uploadPostMedia(
      path: item.picked.path,
      kind: item.picked.kind,
      onProgress: (sent, total) {
        if (!mounted || total <= 0) return;
        final progress = (sent / total).clamp(0.0, 1.0).toDouble();
        final current = _find(id);
        // Progress fires per chunk; a 1% step is all the bar can show.
        if (current == null ||
            current.status != ComposerMediaStatus.uploading ||
            progress - current.progress < 0.01) {
          return;
        }
        _replace(id, (c) => c._uploading(progress));
      },
    );
    if (!mounted) return;
    either.fold(
      (failure) => _replace(id, (c) => c._failed(uploadFailureMessage(failure))),
      (media) => _replace(id, (c) => c._done(media)),
    );
  }

  /// What a failed upload tile says. The server's own sentence for a refused
  /// file ("Videos can be up to 60 seconds long…"); otherwise a short, honest
  /// retry prompt.
  static String uploadFailureMessage(NetworkExceptions failure) {
    if (failure.validationCode != null) {
      return NetworkExceptions.getMessage(failure);
    }
    if (failure.isNoInternet) return 'No internet connection.';
    return "Couldn't upload. Tap to retry.";
  }

  /// The device's decoded photo size beats the server's header read (which
  /// ignores EXIF rotation); for video the server's track header, which
  /// knows the display rotation, wins. Duration is the server's when known.
  static UploadedPostMedia _forPost(ComposerMediaItem item) {
    final uploaded = item.uploaded!;
    final picked = item.picked;
    if (!uploaded.isVideo) {
      return uploaded.copyWith(width: picked.width, height: picked.height);
    }
    final pickedSeconds = picked.duration == null
        ? null
        : picked.duration!.inSeconds
              .clamp(1, PostMediaLimits.maxVideoDuration.inSeconds)
              .toInt();
    return UploadedPostMedia(
      url: uploaded.url,
      kind: uploaded.kind,
      contentType: uploaded.contentType,
      width: uploaded.width ?? picked.width,
      height: uploaded.height ?? picked.height,
      durationSeconds: uploaded.durationSeconds ?? pickedSeconds,
      thumbnailUrl: uploaded.thumbnailUrl,
    );
  }

  ComposerMediaItem? _find(int id) {
    for (final item in state.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _replace(int id, ComposerMediaItem Function(ComposerMediaItem) update) {
    if (_find(id) == null) return;
    state = PostComposerState(
      items: [
        for (final item in state.items)
          if (item.id == id) update(item) else item,
      ],
    );
  }
}
