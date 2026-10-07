import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/story_composer_screen.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Whether the composer offers video. Off because the backend has nowhere to
/// put video bytes (stories point at a URL; the only staging upload takes
/// JPG/PNG). The composer already previews and posts video — flip this once a
/// story media endpoint accepts it.
const bool storyVideoUploadEnabled = false;

/// The "Add to your story" flow: Camera / Gallery sheet → picker → full-screen
/// composer. Shows "Your story is live" when the composer reports a post.
Future<void> startStoryComposer(BuildContext context) async {
  // Root navigator throughout: the tray can sit inside a shell route, and the
  // sheet and composer should cover its bottom navigation.
  final choice = await showModalBottomSheet<_StorySource>(
    context: context,
    useRootNavigator: true,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusLarge),
      ),
    ),
    builder: (_) => const _StorySourceSheet(),
  );
  if (choice == null || !context.mounted) return;

  final XFile? picked;
  try {
    picked = await _pick(choice);
  } on PlatformException catch (error) {
    if (context.mounted) SmSnackbar.error(context, _pickerMessage(error));
    return;
  }
  if (picked == null || !context.mounted) return;

  final mediaPath = picked.path;
  final posted = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => StoryComposerScreen(
        mediaPath: mediaPath,
        isVideo: choice == _StorySource.galleryVideo,
      ),
    ),
  );
  if ((posted ?? false) && context.mounted) {
    SmSnackbar.success(context, 'Your story is live.');
  }
}

enum _StorySource { camera, gallery, galleryVideo }

Future<XFile?> _pick(_StorySource source) {
  final picker = ImagePicker();
  switch (source) {
    case _StorySource.galleryVideo:
      return picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
    case _StorySource.camera:
    case _StorySource.gallery:
      // Bounded and re-encoded so a full-resolution camera photo lands well
      // under the 5 MB upload limit, as a JPEG the staging upload accepts.
      return picker.pickImage(
        source: source == _StorySource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1440,
        maxHeight: 2560,
      );
  }
}

/// The plugin reports a refused permission as a PlatformException; say what
/// to do about it rather than echoing the code.
String _pickerMessage(PlatformException error) => switch (error.code) {
  'camera_access_denied' =>
    'Camera access is off. Turn it on in Settings to take a story photo.',
  'photo_access_denied' =>
    'Photo access is off. Turn it on in Settings to share from your gallery.',
  _ => 'Could not open that photo. Please try again.',
};

class _StorySourceSheet extends StatelessWidget {
  const _StorySourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.sectionOnBase,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.appHorizontalPadding,
              ),
              child: Text(
                'Add to your story',
                style: DesignTokens.sectionInnerTitle.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            _SourceTile(
              key: const Key('story-source-camera'),
              icon: Icons.photo_camera_outlined,
              label: 'Camera',
              onTap: () => Navigator.of(context).pop(_StorySource.camera),
            ),
            _SourceTile(
              key: const Key('story-source-gallery'),
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: () => Navigator.of(context).pop(_StorySource.gallery),
            ),
            if (storyVideoUploadEnabled)
              _SourceTile(
                key: const Key('story-source-video'),
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: () =>
                    Navigator.of(context).pop(_StorySource.galleryVideo),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.appHorizontalPadding,
      ),
      leading: Icon(icon, color: DesignTokens.iconWhite),
      title: Text(
        label,
        style: DesignTokens.oneLinerRegular.copyWith(
          color: DesignTokens.textWhite,
        ),
      ),
      onTap: onTap,
    );
  }
}
