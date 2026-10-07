import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/post_composer_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/post_video_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What the post composer has attached: a 3-across grid of photo thumbnails,
/// or one video preview. Every tile carries its own upload state — a
/// progress ring while uploading, a retry button when it failed — and a
/// remove (×) button whenever it isn't mid-upload.
class ComposerMediaPreview extends StatelessWidget {
  const ComposerMediaPreview({
    required this.items,
    required this.onRemove,
    required this.onRetry,
    super.key,
  });

  final List<ComposerMediaItem> items;
  final void Function(int id) onRemove;
  final void Function(int id) onRetry;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final first = items.first;
    if (first.isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        child: AspectRatio(
          aspectRatio: _videoAspect(first),
          child: _MediaTile(
            item: first,
            onRemove: onRemove,
            onRetry: onRetry,
            child: PostVideoView.file(
              first.picked.path,
              key: const Key('composer-video-preview'),
              duration: first.picked.duration,
            ),
          ),
        ),
      );
    }
    return GridView.count(
      key: const Key('composer-photo-grid'),
      crossAxisCount: 3,
      mainAxisSpacing: DesignTokens.s4,
      crossAxisSpacing: DesignTokens.s4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final item in items)
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: _MediaTile(
              item: item,
              onRemove: onRemove,
              onRetry: onRetry,
              child: Image.file(
                File(item.picked.path),
                fit: BoxFit.cover,
                cacheWidth: 360,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: DesignTokens.bgAppBodyLight,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: DesignTokens.iconLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The clip's own shape, kept between Instagram's 4:5 portrait and 16:9.
  static double _videoAspect(ComposerMediaItem item) {
    final width = item.picked.width;
    final height = item.picked.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 4 / 5;
    }
    return (width / height).clamp(4 / 5, 16 / 9).toDouble();
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.onRemove,
    required this.onRetry,
    required this.child,
  });

  final ComposerMediaItem item;
  final void Function(int id) onRemove;
  final void Function(int id) onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final id = item.id;
    return Stack(
      key: Key('composer-media-$id'),
      fit: StackFit.expand,
      children: [
        child,
        switch (item.status) {
          ComposerMediaStatus.uploading => _Scrim(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 36,
                  child: CircularProgressIndicator(
                    key: Key('composer-progress-$id'),
                    value: item.progress > 0 ? item.progress : null,
                    strokeWidth: 3,
                    color: DesignTokens.primaryGreen,
                    backgroundColor: DesignTokens.textWhite.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '${(item.progress * 100).round()}%',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                ),
              ],
            ),
          ),
          ComposerMediaStatus.failed => _Scrim(
            child: Tooltip(
              message: item.error ?? "Couldn't upload",
              child: TextButton.icon(
                key: Key('composer-retry-$id'),
                onPressed: () => onRetry(id),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: DesignTokens.colorError,
                ),
                label: Text(
                  'Retry',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
            ),
          ),
          ComposerMediaStatus.uploaded => const Positioned(
            left: DesignTokens.s4,
            bottom: DesignTokens.s4,
            child: Icon(
              Icons.check_circle_rounded,
              size: DesignTokens.iconSmall,
              color: DesignTokens.primaryGreen,
            ),
          ),
          ComposerMediaStatus.waiting => const SizedBox.shrink(),
        },
        if (item.status != ComposerMediaStatus.uploading)
          Positioned(
            top: DesignTokens.s4,
            right: DesignTokens.s4,
            child: Material(
              color: DesignTokens.baseBlack.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              child: InkWell(
                key: Key('composer-remove-$id'),
                customBorder: const CircleBorder(),
                onTap: () => onRemove(id),
                child: const Padding(
                  padding: EdgeInsets.all(DesignTokens.s4),
                  child: Icon(
                    Icons.close_rounded,
                    size: DesignTokens.iconSmall,
                    color: DesignTokens.textWhite,
                    semanticLabel: 'Remove',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DesignTokens.baseBlack.withValues(alpha: 0.55),
      child: Center(child: child),
    );
  }
}
