import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:video_player/video_player.dart';

/// Full-screen preview of a picked photo (or video) with an optional caption
/// and "Share to story". Pops `true` once the story is posted; the launcher
/// shows the confirmation and the tray has already been told to reload.
///
/// A failed post keeps the screen, the media and the caption, and says why —
/// the button becomes "Try again".
class StoryComposerScreen extends ConsumerStatefulWidget {
  const StoryComposerScreen({
    required this.mediaPath,
    this.isVideo = false,
    super.key,
  });

  final String mediaPath;
  final bool isVideo;

  @override
  ConsumerState<StoryComposerScreen> createState() =>
      _StoryComposerScreenState();
}

class _StoryComposerScreenState extends ConsumerState<StoryComposerScreen> {
  /// `CreateStoryVm` caps the caption at 500 characters.
  static const int _maxCaptionLength = 500;

  final _caption = TextEditingController();
  VideoPlayerController? _video;
  bool _videoFailed = false;
  bool _posting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) unawaited(_startVideo());
  }

  Future<void> _startVideo() async {
    final controller = VideoPlayerController.file(File(widget.mediaPath));
    _video = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      _videoFailed = true;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _caption.dispose();
    unawaited(_video?.dispose());
    super.dispose();
  }

  Future<void> _share() async {
    if (_posting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _posting = true;
      _error = null;
    });
    final caption = _caption.text.trim();
    final either = await ref
        .read(storiesNotifierProvider.notifier)
        .createStory(
          mediaFile: widget.mediaPath,
          caption: caption.isEmpty ? null : caption,
        );
    if (!mounted) return;
    either.fold(
      (failure) => setState(() {
        _posting = false;
        _error = NetworkExceptions.getMessage(failure);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Leaving mid-upload would hide whether the story went up.
      canPop: !_posting,
      child: Scaffold(
        backgroundColor: DesignTokens.baseBlack,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _preview(),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: DesignTokens.imageScrimTop,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      key: const Key('story-composer-close'),
                      tooltip: 'Discard',
                      onPressed: _posting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(
                        Icons.close,
                        color: DesignTokens.iconWhite,
                        size: DesignTokens.iconMedium,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _bottomPanel(),
                ],
              ),
            ),
            if (_posting) const _PostingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    if (!widget.isVideo) {
      return Image.file(
        File(widget.mediaPath),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _PreviewUnavailable(),
      );
    }
    final video = _video;
    if (_videoFailed) return const _PreviewUnavailable();
    if (video == null || !video.value.isInitialized) {
      return const SmPageLoader(size: 48);
    }
    return Center(
      child: AspectRatio(
        aspectRatio: video.value.aspectRatio,
        child: VideoPlayer(video),
      ),
    );
  }

  Widget _bottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.appHorizontalPadding,
        DesignTokens.s24,
        DesignTokens.appHorizontalPadding,
        DesignTokens.s12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xB3000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: DesignTokens.s12),
          ],
          TextField(
            key: const Key('story-composer-caption'),
            controller: _caption,
            enabled: !_posting,
            minLines: 1,
            maxLines: 3,
            maxLength: _maxCaptionLength,
            textCapitalization: TextCapitalization.sentences,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textWhite,
            ),
            cursorColor: DesignTokens.primaryGreen,
            decoration: InputDecoration(
              hintText: 'Add a caption…',
              hintStyle: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textLight,
              ),
              counterText: '',
              filled: true,
              fillColor: DesignTokens.glassFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                borderSide: const BorderSide(color: DesignTokens.glassStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                borderSide: const BorderSide(color: DesignTokens.glassStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                borderSide: const BorderSide(color: DesignTokens.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
            height: DesignTokens.buttonHeight,
            child: ElevatedButton.icon(
              key: const Key('story-composer-share'),
              onPressed: _posting ? null : _share,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: DesignTokens.textDark,
                disabledBackgroundColor: DesignTokens.bgAppBodyLight,
                shape: const StadiumBorder(),
                textStyle: DesignTokens.oneLinerSemibold,
              ),
              icon: Icon(_error == null ? Icons.send_rounded : Icons.refresh),
              label: Text(_error == null ? 'Share to story' : 'Try again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('story-composer-error'),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.warningFillDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: DesignTokens.colorWarning,
            size: DesignTokens.iconSmall + 4,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              "Your story wasn't shared. $message",
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.warningTextLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostingOverlay extends StatelessWidget {
  const _PostingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SmBrandLoader(size: 56, semanticLabel: 'Sharing your story'),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'Sharing your story…',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewUnavailable extends StatelessWidget {
  const _PreviewUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            color: DesignTokens.iconLight,
            size: DesignTokens.iconXLarge,
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            "Preview isn't available, but you can still share it.",
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
