import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/story_age.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/story_ring_avatar.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:video_player/video_player.dart';

/// Full-screen Instagram-style story player.
///
/// Swipes sideways between people ([groups]); within one person, tap the right
/// of the screen for the next story and the left third for the previous one,
/// hold to pause, swipe down to close. Photos run 5 s, videos for their own
/// length (capped at the 60 s a story may last). Each story is marked seen as
/// it starts; at the end of someone's stories it moves to the next person, and
/// closes after the last.
///
/// On your own stories it shows the view count and a delete option.
///
/// The `/stories/:userId` route opens it with only [userId] (and no
/// [stories]); it then loads that person's active stories itself.
class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    required this.userId,
    required this.stories,
    this.groups,
    this.initialGroupIndex = 0,
    super.key,
  });

  final String userId;
  final List<Story> stories;

  /// Everyone the viewer can move through, in tray order. When null the viewer
  /// shows [stories] (or loads [userId]'s) on their own.
  final List<StoryGroup>? groups;
  final int initialGroupIndex;

  /// Pushes the viewer over everything, bottom navigation included, starting
  /// at [initialGroupIndex] of [groups].
  static Future<void> open(
    BuildContext context, {
    required List<StoryGroup> groups,
    int initialGroupIndex = 0,
  }) {
    final start = groups[initialGroupIndex];
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: DesignTokens.motionMedium,
        reverseTransitionDuration: DesignTokens.motionFast,
        pageBuilder: (_, _, _) => StoryViewerScreen(
          userId: start.userId,
          stories: start.stories,
          groups: groups,
          initialGroupIndex: initialGroupIndex,
        ),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: DesignTokens.motionCurve,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  /// How far down a drag must travel (or how fast) to close the viewer.
  static const double _dismissDistance = 120;
  static const double _dismissVelocity = 700;

  late List<StoryGroup> _groups;
  late final PageController _pages;
  int _groupIndex = 0;
  bool _loading = false;
  String? _loadError;
  double _dragDy = 0;

  @override
  void initState() {
    super.initState();
    _groups = widget.groups ?? _groupFromStories();
    _groupIndex = _groups.isEmpty
        ? 0
        : widget.initialGroupIndex.clamp(0, _groups.length - 1);
    _pages = PageController(initialPage: _groupIndex);
    _loading = _groups.isEmpty;
    if (_loading) unawaited(_loadAuthor());
  }

  List<StoryGroup> _groupFromStories() {
    final stories = widget.stories;
    if (stories.isEmpty) return const [];
    return [
      StoryGroup(
        userId: widget.userId,
        userName: stories.first.userName,
        userAvatarUrl: stories.first.userAvatarUrl,
        stories: stories,
        hasUnwatched: stories.any((s) => !s.hasWatched),
      ),
    ];
  }

  /// Deep-link entry: fetch the author's active stories.
  Future<void> _loadAuthor() async {
    final either = await ref
        .read(storiesNotifierProvider.notifier)
        .loadStories(widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      either.fold(
        (failure) => _loadError = NetworkExceptions.getMessage(failure),
        (stories) {
          if (stories.isEmpty) {
            _loadError = 'These stories have expired.';
            return;
          }
          _groups = [
            StoryGroup(
              userId: widget.userId,
              userName: stories.first.userName,
              userAvatarUrl: stories.first.userAvatarUrl,
              stories: stories,
              hasUnwatched: stories.any((s) => !s.hasWatched),
            ),
          ];
        },
      );
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _close() {
    if (mounted) unawaited(Navigator.of(context).maybePop());
  }

  void _nextGroup() {
    if (_groupIndex < _groups.length - 1) {
      unawaited(
        _pages.nextPage(
          duration: DesignTokens.motionMedium,
          curve: DesignTokens.motionCurve,
        ),
      );
    } else {
      _close();
    }
  }

  /// Returns whether there was a previous person to go back to.
  bool _previousGroup() {
    if (_groupIndex == 0) return false;
    unawaited(
      _pages.previousPage(
        duration: DesignTokens.motionMedium,
        curve: DesignTokens.motionCurve,
      ),
    );
    return true;
  }

  void _removeStory(String userId, String storyId) {
    final at = _groups.indexWhere((g) => g.userId == userId);
    if (at < 0) return;
    final remaining = _groups[at].stories
        .where((s) => s.id != storyId)
        .toList(growable: false);
    setState(() {
      _groups = [..._groups];
      if (remaining.isEmpty) {
        _groups.removeAt(at);
      } else {
        _groups[at] = _groups[at].copyWith(
          stories: remaining,
          hasUnwatched: remaining.any((s) => !s.hasWatched),
        );
      }
      if (_groups.isNotEmpty && _groupIndex >= _groups.length) {
        _groupIndex = _groups.length - 1;
      }
    });
    if (_groups.isEmpty) {
      _close();
    } else if (_pages.hasClients && _pages.page?.round() != _groupIndex) {
      _pages.jumpToPage(_groupIndex);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final next = math.max(0, _dragDy + details.delta.dy).toDouble();
    if (next != _dragDy) setState(() => _dragDy = next);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragDy > _dismissDistance || velocity > _dismissVelocity) {
      _close();
    } else {
      setState(() => _dragDy = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(storiesCurrentUserProvider);
    final pull = (_dragDy / 400).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // A Scaffold (not bare Material) so snackbars raised here, such as
      // "Story deleted.", show above the viewer instead of behind it.
      child: Scaffold(
        backgroundColor: DesignTokens.baseBlack.withValues(
          alpha: 1 - pull * 0.7,
        ),
        body: GestureDetector(
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: Transform.translate(
            offset: Offset(0, _dragDy),
            child: Transform.scale(
              scale: 1 - pull * 0.12,
              child: _body(me),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(StoriesCurrentUser me) {
    if (_loading) return const SmPageLoader(size: 48);
    if (_groups.isEmpty) {
      return _ViewerMessage(
        message: _loadError ?? 'These stories have expired.',
        onClose: _close,
      );
    }
    return PageView.builder(
      key: const Key('story-viewer-pages'),
      controller: _pages,
      itemCount: _groups.length,
      onPageChanged: (index) => setState(() => _groupIndex = index),
      itemBuilder: (_, index) {
        final group = _groups[index];
        return _StoryGroupView(
          key: ValueKey('story-group-${group.userId}'),
          group: group,
          isOwner: me.owns(group.userId),
          isActive: index == _groupIndex,
          paused: _dragDy > 0,
          onGroupComplete: _nextGroup,
          onPreviousGroup: _previousGroup,
          onClose: _close,
          onStoryDeleted: (storyId) => _removeStory(group.userId, storyId),
        );
      },
    );
  }
}

enum _MediaStatus { loading, ready, failed }

/// One person's stories: progress, media, header, caption and owner tools.
class _StoryGroupView extends ConsumerStatefulWidget {
  const _StoryGroupView({
    required this.group,
    required this.isOwner,
    required this.isActive,
    required this.paused,
    required this.onGroupComplete,
    required this.onPreviousGroup,
    required this.onClose,
    required this.onStoryDeleted,
    super.key,
  });

  final StoryGroup group;
  final bool isOwner;

  /// Only the page on screen plays; the neighbours sit still.
  final bool isActive;
  final bool paused;
  final VoidCallback onGroupComplete;
  final bool Function() onPreviousGroup;
  final VoidCallback onClose;
  final ValueChanged<String> onStoryDeleted;

  @override
  ConsumerState<_StoryGroupView> createState() => _StoryGroupViewState();
}

class _StoryGroupViewState extends ConsumerState<_StoryGroupView>
    with SingleTickerProviderStateMixin {
  static const Duration _photoDuration = Duration(seconds: 5);

  /// A story whose media will not load still gets a short turn on screen, so
  /// the placeholder is readable and the sequence carries on.
  static const Duration _failedDuration = Duration(seconds: 3);
  static const Duration _loadTimeout = Duration(seconds: 15);
  static const Duration _maxVideoDuration = Duration(seconds: 60);

  late final AnimationController _progress;
  late int _index;
  _MediaStatus _status = _MediaStatus.loading;
  VideoPlayerController? _video;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  Timer? _timeout;

  /// Bumped on every story change so late media callbacks are ignored.
  int _loadToken = 0;
  bool _holding = false;
  bool _menuOpen = false;

  /// Stories already reported seen from here; going back to one does not
  /// report it again.
  final Set<String> _marked = {};

  List<Story> get _stories => widget.group.stories;
  Story get _story => _stories[_index];

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _photoDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    // Pick up where this person was left: the first story not yet seen.
    final firstNew = widget.isOwner
        ? -1
        : _stories.indexWhere((s) => !s.hasWatched);
    _index = firstNew < 0 ? 0 : firstNew;
    if (widget.isActive) _loadCurrent();
  }

  @override
  void didUpdateWidget(covariant _StoryGroupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    var reload = false;

    if (!identical(oldWidget.group.stories, _stories) && _stories.isNotEmpty) {
      final currentId = oldWidget.group.stories[_index].id;
      final stillThere = _stories.indexWhere((s) => s.id == currentId);
      if (stillThere >= 0) {
        _index = stillThere;
      } else {
        _index = math.min(_index, _stories.length - 1);
        reload = widget.isActive;
      }
    }

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        reload = true;
      } else {
        _resetMedia();
        _progress
          ..stop()
          ..value = 0;
      }
    }

    if (reload) {
      _loadCurrent();
    } else if (widget.paused != oldWidget.paused) {
      _syncPlayback();
    }
  }

  @override
  void dispose() {
    _resetMedia();
    _progress.dispose();
    super.dispose();
  }

  void _resetMedia() {
    _loadToken++;
    _timeout?.cancel();
    _timeout = null;
    final listener = _imageListener;
    if (listener != null) _imageStream?.removeListener(listener);
    _imageStream = null;
    _imageListener = null;
    final video = _video;
    _video = null;
    if (video != null) unawaited(video.dispose());
  }

  /// Starts the current story from zero: media, timer and the "seen" mark.
  void _loadCurrent() {
    _resetMedia();
    final token = _loadToken;
    _progress
      ..stop()
      ..value = 0;
    final story = _story;
    // Already `loading` on first activation, which runs from initState.
    if (_status != _MediaStatus.loading) {
      setState(() => _status = _MediaStatus.loading);
    }

    // Deferred: this can run from initState/didUpdateWidget, and the mark
    // updates the stories provider, which Riverpod refuses mid-build.
    if (!widget.isOwner && !story.hasWatched && _marked.add(story.id)) {
      scheduleMicrotask(() {
        if (!mounted) return;
        unawaited(
          ref.read(storiesNotifierProvider.notifier).viewStory(story.id),
        );
      });
    }

    final uri = Uri.tryParse(story.mediaUrl);
    if (story.mediaUrl.isEmpty || uri == null) {
      scheduleMicrotask(() => _mediaFailed(token));
      return;
    }
    _timeout = Timer(_loadTimeout, () => _mediaFailed(token));

    if (story.isVideo) {
      final controller = VideoPlayerController.networkUrl(uri);
      _video = controller;
      controller
          .initialize()
          .then((_) {
            if (token != _loadToken || !mounted) return;
            final length = controller.value.duration;
            _mediaReady(
              token,
              length <= Duration.zero
                  ? _photoDuration
                  : (length > _maxVideoDuration ? _maxVideoDuration : length),
            );
          })
          .catchError((Object _) {
            _mediaFailed(token);
          });
      return;
    }

    final stream = CachedNetworkImageProvider(
      story.mediaUrl,
    ).resolve(ImageConfiguration.empty);
    // A cached image reports synchronously, from inside this call; the
    // microtask keeps that out of the build that may be running.
    final listener = ImageStreamListener(
      (info, _) {
        info.dispose();
        scheduleMicrotask(() => _mediaReady(token, _photoDuration));
      },
      onError: (_, _) => scheduleMicrotask(() => _mediaFailed(token)),
    );
    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  void _mediaReady(int token, Duration duration) {
    if (token != _loadToken || !mounted || _status != _MediaStatus.loading) {
      return;
    }
    _timeout?.cancel();
    _progress.duration = duration;
    setState(() => _status = _MediaStatus.ready);
    _syncPlayback();
  }

  void _mediaFailed(int token) {
    if (token != _loadToken || !mounted || _status == _MediaStatus.failed) {
      return;
    }
    _timeout?.cancel();
    final video = _video;
    _video = null;
    if (video != null) unawaited(video.dispose());
    _progress.duration = _failedDuration;
    setState(() => _status = _MediaStatus.failed);
    _syncPlayback();
  }

  /// Runs or holds the timer (and the video) to match what is on screen.
  void _syncPlayback() {
    final run =
        widget.isActive &&
        !widget.paused &&
        !_holding &&
        !_menuOpen &&
        _status != _MediaStatus.loading;
    final video = _video;
    if (run) {
      if (!_progress.isAnimating) unawaited(_progress.forward());
      if (video != null &&
          video.value.isInitialized &&
          !video.value.isPlaying) {
        unawaited(video.play());
      }
    } else {
      _progress.stop();
      if (video != null && video.value.isPlaying) unawaited(video.pause());
    }
  }

  void _next() {
    if (!mounted || !widget.isActive) return;
    if (_index < _stories.length - 1) {
      setState(() => _index++);
      _loadCurrent();
    } else {
      _progress.stop();
      widget.onGroupComplete();
    }
  }

  void _previous() {
    if (_index > 0) {
      setState(() => _index--);
      _loadCurrent();
    } else if (!widget.onPreviousGroup()) {
      _loadCurrent();
    }
  }

  void _setHolding(bool holding) {
    setState(() => _holding = holding);
    _syncPlayback();
  }

  Future<void> _openOwnerMenu() async {
    setState(() => _menuOpen = true);
    _syncPlayback();
    final story = _story;
    final choice = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLarge),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          key: const Key('story-viewer-delete'),
          leading: const Icon(
            Icons.delete_outline,
            color: DesignTokens.colorError,
          ),
          title: Text(
            'Delete story',
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
          onTap: () => Navigator.of(sheetContext).pop(true),
        ),
      ),
    );
    if (!mounted) return;
    if (choice ?? false) await _confirmDelete(story);
    if (!mounted) return;
    setState(() => _menuOpen = false);
    _syncPlayback();
  }

  Future<void> _confirmDelete(Story story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: Text(
          'Delete this story?',
          style: DesignTokens.sectionInnerTitle.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        content: Text(
          'It comes off your story straight away.',
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('story-viewer-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    final either = await ref
        .read(storiesNotifierProvider.notifier)
        .deleteStory(story.id);
    if (!mounted) return;
    either.fold(
      (failure) => SmSnackbar.error(
        context,
        "Couldn't delete the story. ${NetworkExceptions.getMessage(failure)}",
      ),
      (_) {
        SmSnackbar.success(context, 'Story deleted.');
        widget.onStoryDeleted(story.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) return const SizedBox.shrink();
    final story = _story;
    final caption = story.caption?.trim() ?? '';
    final chromeOpacity = _holding ? 0.0 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final width = context.size?.width ?? 0;
        if (details.localPosition.dx < width / 3) {
          _previous();
        } else {
          _next();
        }
      },
      onLongPressStart: (_) => _setHolding(true),
      onLongPressEnd: (_) => _setHolding(false),
      onLongPressCancel: () {
        if (_holding) _setHolding(false);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _media(story),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: DesignTokens.imageScrimTop),
            ),
          ),
          if (caption.isNotEmpty || widget.isOwner)
            const Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x99000000)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: AnimatedOpacity(
              opacity: chromeOpacity,
              duration: DesignTokens.motionFast,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.s8,
                      DesignTokens.s8,
                      DesignTokens.s8,
                      0,
                    ),
                    child: _ProgressBars(
                      count: _stories.length,
                      index: _index,
                      progress: _progress,
                    ),
                  ),
                  _header(story),
                  const Spacer(),
                  if (caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.appHorizontalPadding,
                      ),
                      child: Text(
                        caption,
                        key: const Key('story-viewer-caption'),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.mediumRegular.copyWith(
                          color: DesignTokens.textWhite,
                          shadows: _textShadow,
                        ),
                      ),
                    ),
                  if (widget.isOwner) _ownerBar(story) else
                    const SizedBox(height: DesignTokens.s24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _media(Story story) {
    switch (_status) {
      case _MediaStatus.failed:
        return const _MediaUnavailable();
      case _MediaStatus.loading:
        // The image may already be in the cache and paint before the stream
        // reports; the loader sits over it until then.
        return Stack(
          fit: StackFit.expand,
          children: [
            if (!story.isVideo && story.mediaUrl.isNotEmpty)
              _image(story.mediaUrl),
            const SmPageLoader(size: 40),
          ],
        );
      case _MediaStatus.ready:
        final video = _video;
        if (story.isVideo && video != null && video.value.isInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: video.value.aspectRatio,
              child: VideoPlayer(video),
            ),
          );
        }
        return _image(story.mediaUrl);
    }
  }

  Widget _image(String url) => Image(
    image: CachedNetworkImageProvider(url),
    fit: BoxFit.contain,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const _MediaUnavailable(),
  );

  Widget _header(Story story) {
    final name = widget.isOwner ? 'Your story' : widget.group.userName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s12,
        DesignTokens.s8,
        DesignTokens.s4,
        0,
      ),
      child: Row(
        children: [
          StoryRingAvatar(
            avatarUrl: widget.group.userAvatarUrl,
            name: widget.group.userName,
            diameter: 36,
            ring: StoryRing.none,
          ),
          const SizedBox(width: DesignTokens.s8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
                shadows: _textShadow,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Text(
            storyAge(story.postedAt),
            key: const Key('story-viewer-age'),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
              shadows: _textShadow,
            ),
          ),
          const Spacer(),
          IconButton(
            key: const Key('story-viewer-close'),
            tooltip: 'Close',
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.close,
              color: DesignTokens.iconWhite,
              size: DesignTokens.iconMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerBar(Story story) {
    final views = story.viewCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.appHorizontalPadding,
        DesignTokens.s12,
        DesignTokens.s4,
        DesignTokens.s8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            color: DesignTokens.iconWhite,
            size: DesignTokens.iconSmall + 2,
          ),
          const SizedBox(width: DesignTokens.s6),
          Text(
            views == 1 ? '1 view' : '$views views',
            key: const Key('story-viewer-views'),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
              shadows: _textShadow,
            ),
          ),
          const Spacer(),
          IconButton(
            key: const Key('story-viewer-more'),
            tooltip: 'Story options',
            onPressed: () => unawaited(_openOwnerMenu()),
            icon: const Icon(Icons.more_horiz, color: DesignTokens.iconWhite),
          ),
        ],
      ),
    );
  }
}

const List<Shadow> _textShadow = [
  Shadow(color: Color(0x73000000), blurRadius: 6, offset: Offset(0, 1)),
];

/// The segmented bar across the top: filled for seen, filling for the current
/// one, empty for what is still to come.
class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.count,
    required this.index,
    required this.progress,
  });

  final int count;
  final int index;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, _) => Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: DesignTokens.s4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 2.5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0x59FFFFFF)),
                      FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: i < index
                            ? 1.0
                            : (i == index ? progress.value : 0.0),
                        child: const ColoredBox(color: DesignTokens.textWhite),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaUnavailable extends StatelessWidget {
  const _MediaUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: DesignTokens.iconLight,
            size: DesignTokens.iconXLarge,
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            "This story couldn't load.",
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerMessage extends StatelessWidget {
  const _ViewerMessage({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: IconButton(
              key: const Key('story-viewer-close'),
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close, color: DesignTokens.iconWhite),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.s24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
