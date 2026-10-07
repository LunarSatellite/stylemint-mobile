import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/post_composer_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/feed_viewer_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/post_media_picker_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/composer_media_preview.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_avatar.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The post composer, Instagram/Facebook style: who is posting, a caption,
/// then up to 10 photos or one video (≤ 60 s) from the Photo / Video / Camera
/// row. A text-only post still works as before.
///
/// "Post" first uploads each attachment to `POST /v1/social/media` (each tile
/// shows its own progress) and then creates the post with the returned URLs.
/// If an upload fails the composer stays open with everything kept: the tile
/// offers Retry, and Post again only re-sends what didn't make it.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  /// `Post.MaxBodyLength` on the backend.
  static const int _maxBodyLength = 5000;

  final _contentController = TextEditingController();
  bool _isPosting = false;
  String? _errorText;
  final List<String> _taggedProductIds = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  PostComposerNotifier get _composer =>
      ref.read(postComposerNotifierProvider.notifier);

  bool _canPost(PostComposerState media) =>
      !_isPosting &&
      !media.isUploading &&
      (_contentController.text.trim().isNotEmpty || media.items.isNotEmpty);

  Future<void> _pickPhotos() => _pick(() async {
    final slots = ref.read(postComposerNotifierProvider).photoSlotsLeft;
    final photos = await ref
        .read(postMediaPickerProvider)
        .pickPhotos(limit: slots);
    if (!mounted || photos.isEmpty) return;
    final dropped = _composer.addPhotos(photos);
    if (dropped > 0 && mounted) {
      SmSnackbar.info(
        context,
        'A post holds up to ${PostMediaLimits.maxPhotos} photos — '
        '$dropped ${dropped == 1 ? 'was' : 'were'} left out.',
      );
    }
  });

  Future<void> _takePhoto() => _pick(() async {
    final photo = await ref.read(postMediaPickerProvider).takePhoto();
    if (!mounted || photo == null) return;
    _composer.addPhotos([photo]);
  });

  Future<void> _pickVideo() => _pick(() async {
    final video = await ref.read(postMediaPickerProvider).pickVideo();
    if (!mounted || video == null) return;
    if (PostComposerNotifier.isTooLong(video)) {
      SmSnackbar.error(
        context,
        'Videos can be up to 60 seconds long. Trim it and try again.',
      );
      return;
    }
    _composer.setVideo(video);
  });

  /// Runs a picker, turning a refused permission into what to do about it.
  Future<void> _pick(Future<void> Function() pick) async {
    FocusScope.of(context).unfocus();
    try {
      await pick();
    } on PlatformException catch (error) {
      if (mounted) SmSnackbar.error(context, _pickerMessage(error));
    }
  }

  Future<void> _submit() async {
    if (!_canPost(ref.read(postComposerNotifierProvider))) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isPosting = true;
      _errorText = null;
    });

    final hasMedia = ref.read(postComposerNotifierProvider).items.isNotEmpty;
    List<UploadedPostMedia>? media;
    if (hasMedia) {
      media = await _composer.uploadAll();
      if (!mounted) return;
      if (media == null) {
        setState(() {
          _isPosting = false;
          _errorText =
              "Some of your media didn't upload. Tap Retry on it, or Post "
              'again.';
        });
        return;
      }
    }

    final result = await ref
        .read(feedNotifierProvider.notifier)
        .createPost(
          content: _contentController.text.trim(),
          taggedProductIds: _taggedProductIds.isEmpty
              ? null
              : _taggedProductIds,
          media: media,
        );
    if (!mounted) return;

    setState(() => _isPosting = false);
    result.maybeWhen(
      postSuccess: (post) => Navigator.of(context).pop(),
      postFailure: (failure) => setState(
        () => _errorText = hasMedia
            ? "Your media is uploaded but the post didn't go through. "
                  'Tap Post to try again.'
            : 'Failed to create post. Try again.',
      ),
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = ref.watch(postComposerNotifierProvider);
    final viewer = ref.watch(feedViewerProvider);
    final busy = _isPosting || media.isUploading;

    return PopScope(
      // Leaving mid-upload would hide whether the post went up.
      canPop: !busy,
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(
          title: const Text('Create Post', style: DesignTokens.titleLarge),
          backgroundColor: DesignTokens.bgAppFoundation,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.s12),
              child: Center(
                child: ElevatedButton(
                  key: const Key('create-post-submit'),
                  style: DesignTokens.primaryButtonStyle(height: 36).copyWith(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: DesignTokens.s16),
                    ),
                  ),
                  onPressed: _canPost(media) ? _submit : null,
                  child: busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        )
                      : const Text('Post'),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  children: [
                    Row(
                      children: [
                        FeedAvatar(url: viewer?.avatarUrl),
                        const SizedBox(width: DesignTokens.s8),
                        Expanded(
                          child: Text(
                            viewer?.displayName.trim().isNotEmpty ?? false
                                ? viewer!.displayName
                                : 'You',
                            style: DesignTokens.mediumSemibold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    TextFormField(
                      controller: _contentController,
                      onChanged: (_) => setState(() {}),
                      minLines: 3,
                      maxLines: 8,
                      maxLength: _maxBodyLength,
                      enabled: !_isPosting,
                      style: DesignTokens.bodyText,
                      decoration: DesignTokens.inputDecoration(
                        hintText: media.items.isEmpty
                            ? "What's on your mind?"
                            : 'Write a caption…',
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    ComposerMediaPreview(
                      items: media.items,
                      onRemove: _composer.remove,
                      onRetry: (id) => unawaited(_composer.retry(id)),
                    ),
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: DesignTokens.s12),
                        child: Text(
                          _errorText!,
                          key: const Key('create-post-error'),
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.colorError,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _MediaActions(
                canAddPhotos: !_isPosting && media.canAddPhotos,
                canAddVideo: !_isPosting && media.canAddVideo,
                onPhoto: () => unawaited(_pickPhotos()),
                onVideo: () => unawaited(_pickVideo()),
                onCamera: () => unawaited(_takePhoto()),
                hint: media.hasVideo
                    ? '1 video'
                    : media.items.isEmpty
                    ? 'Up to ${PostMediaLimits.maxPhotos} photos or 1 video'
                    : '${media.items.length}/${PostMediaLimits.maxPhotos} '
                          'photos',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The plugin reports a refused permission as a PlatformException; say what
/// to do about it rather than echoing the code (as the stories composer does).
String _pickerMessage(PlatformException error) => switch (error.code) {
  'camera_access_denied' =>
    'Camera access is off. Turn it on in Settings to take a photo.',
  'photo_access_denied' =>
    'Photo access is off. Turn it on in Settings to share from your gallery.',
  _ => 'Could not open that file. Please try again.',
};

/// "Add to your post" row: Photo, Video, Camera.
class _MediaActions extends StatelessWidget {
  const _MediaActions({
    required this.canAddPhotos,
    required this.canAddVideo,
    required this.onPhoto,
    required this.onVideo,
    required this.onCamera,
    required this.hint,
  });

  final bool canAddPhotos;
  final bool canAddVideo;
  final VoidCallback onPhoto;
  final VoidCallback onVideo;
  final VoidCallback onCamera;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(top: BorderSide(color: DesignTokens.sectionOnBase)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s8,
          DesignTokens.s8,
          DesignTokens.s8,
          DesignTokens.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _MediaAction(
                  key: const Key('create-post-add-photo'),
                  icon: Icons.photo_library_outlined,
                  label: 'Photo',
                  onTap: canAddPhotos ? onPhoto : null,
                ),
                _MediaAction(
                  key: const Key('create-post-add-video'),
                  icon: Icons.videocam_outlined,
                  label: 'Video',
                  onTap: canAddVideo ? onVideo : null,
                ),
                _MediaAction(
                  key: const Key('create-post-add-camera'),
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  onTap: canAddPhotos ? onCamera : null,
                ),
              ],
            ),
            Text(hint, style: DesignTokens.smallRegular),
          ],
        ),
      ),
    );
  }
}

class _MediaAction extends StatelessWidget {
  const _MediaAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? DesignTokens.textMuted.withValues(alpha: 0.5)
        : DesignTokens.primaryGreen;
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: DesignTokens.mediumSemibold.copyWith(color: color),
        ),
      ),
    );
  }
}
