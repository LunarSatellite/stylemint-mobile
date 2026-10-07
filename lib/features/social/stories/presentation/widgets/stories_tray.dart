import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/notifiers/stories_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/story_viewer_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/story_composer_launcher.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/story_ring_avatar.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_shimmer.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The order people are shown and played in: your own stories first, then
/// everyone with something new, then everyone already seen. Within each, the
/// backend's newest-first order holds.
List<StoryGroup> storyPlaylist(
  List<StoryGroup> groups,
  StoriesCurrentUser me,
) => [
  ...groups.where((g) => me.owns(g.userId)).take(1),
  ...groups.where((g) => !me.owns(g.userId) && g.hasUnwatched),
  ...groups.where((g) => !me.owns(g.userId) && !g.hasUnwatched),
];

/// Where a [StoriesTray] is drawn, which decides its colours.
enum StoriesTrayStyle {
  /// Laid over a playing reel: transparent, white labels, soft top scrim.
  overlay,

  /// On an app surface such as the Community home.
  surface,
}

/// The Instagram-style row of story bubbles: "Your story" first, then everyone
/// with an active story — new ones before ones already seen.
///
/// With [hideWhenEmpty] the tray collapses to nothing until someone has
/// actually posted a story — the reels feed uses that, so an empty tray never
/// covers a reel.
class StoriesTray extends ConsumerWidget {
  const StoriesTray({
    super.key,
    this.style = StoriesTrayStyle.surface,
    this.hideWhenEmpty = false,
  });

  final StoriesTrayStyle style;
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storiesNotifierProvider);
    final groups = state.maybeWhen(
      loadSuccess: (loaded) => loaded,
      orElse: () => null,
    );
    // Decided before anything else is read, so a hidden tray costs nothing.
    if (hideWhenEmpty && (groups == null || groups.isEmpty)) {
      return const SizedBox.shrink();
    }

    final metrics = _TrayMetrics.of(style);
    final me = ref.watch(storiesCurrentUserProvider);
    final failed = state.maybeWhen(
      loadFailure: (_) => true,
      orElse: () => false,
    );

    final playlist = storyPlaylist(groups ?? const <StoryGroup>[], me);
    final first = playlist.firstOrNull;
    final mine = first != null && me.owns(first.userId) ? first : null;
    final ordered = mine == null ? playlist : playlist.sublist(1);

    void openAt(StoryGroup group) => unawaited(
      StoryViewerScreen.open(
        context,
        groups: playlist,
        initialGroupIndex: playlist.indexOf(group),
      ),
    );

    final yourStory = _YourStoryBubble(
      metrics: metrics,
      me: me,
      mine: mine,
      onOpen: mine == null ? null : () => openAt(mine),
      onAdd: () => unawaited(startStoryComposer(context)),
    );

    final List<Widget> bubbles;
    if (groups != null) {
      bubbles = [
        yourStory,
        for (final group in ordered)
          _StoryBubble(
            key: ValueKey('stories-tray-bubble-${group.userId}'),
            metrics: metrics,
            label: group.userName,
            avatarUrl: group.userAvatarUrl,
            ring: group.hasUnwatched ? StoryRing.unwatched : StoryRing.watched,
            onTap: () => openAt(group),
          ),
      ];
    } else if (failed) {
      bubbles = [
        yourStory,
        _RetryBubble(
          metrics: metrics,
          onTap: () => unawaited(
            ref.read(storiesNotifierProvider.notifier).loadStoryGroups(),
          ),
        ),
      ];
    } else {
      bubbles = [
        yourStory,
        for (var i = 0; i < 4; i++) _PlaceholderBubble(metrics: metrics),
      ];
    }

    return SizedBox(
      key: const Key('stories-tray'),
      height: metrics.trayHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: metrics.verticalPadding,
        ),
        itemCount: bubbles.length,
        separatorBuilder: (_, _) => const SizedBox(width: DesignTokens.s4),
        itemBuilder: (_, index) => bubbles[index],
      ),
    );
  }
}

/// Sizes and colours per [StoriesTrayStyle]. The overlay row stays at 96 px
/// tall, labels included, so it sits over a reel without crowding it.
class _TrayMetrics {
  const _TrayMetrics({
    required this.diameter,
    required this.verticalPadding,
    required this.labelColor,
    required this.labelShadows,
    required this.watchedRing,
    required this.badgeBorder,
  });

  factory _TrayMetrics.of(StoriesTrayStyle style) => switch (style) {
    StoriesTrayStyle.overlay => const _TrayMetrics(
      diameter: 64,
      verticalPadding: DesignTokens.s6,
      labelColor: DesignTokens.textWhite,
      labelShadows: [
        Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 1)),
      ],
      watchedRing: Color(0x8CFFFFFF),
      badgeBorder: DesignTokens.baseBlack,
    ),
    StoriesTrayStyle.surface => const _TrayMetrics(
      diameter: 72,
      verticalPadding: DesignTokens.s8,
      labelColor: DesignTokens.textLight,
      labelShadows: null,
      watchedRing: DesignTokens.sectionOnBase,
      badgeBorder: DesignTokens.bgAppFoundation,
    ),
  };

  final double diameter;
  final double verticalPadding;
  final Color labelColor;
  final List<Shadow>? labelShadows;
  final Color watchedRing;
  final Color badgeBorder;

  static const double labelGap = DesignTokens.s4;
  static const double labelHeight = 16;

  double get itemWidth => diameter + DesignTokens.s8;
  double get trayHeight =>
      diameter + labelGap + labelHeight + verticalPadding * 2;

  TextStyle get labelStyle => DesignTokens.tiny.copyWith(
    color: labelColor,
    shadows: labelShadows,
  );
}

/// A bubble with its name underneath, cut to one line.
class _BubbleFrame extends StatelessWidget {
  const _BubbleFrame({
    required this.metrics,
    required this.label,
    required this.avatar,
    this.onTap,
  });

  final _TrayMetrics metrics;
  final String label;
  final Widget avatar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: metrics.itemWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(height: _TrayMetrics.labelGap),
              SizedBox(
                height: _TrayMetrics.labelHeight,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: metrics.labelStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.metrics,
    required this.label,
    required this.avatarUrl,
    required this.ring,
    required this.onTap,
    super.key,
  });

  final _TrayMetrics metrics;
  final String label;
  final String avatarUrl;
  final StoryRing ring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BubbleFrame(
      metrics: metrics,
      label: label,
      onTap: onTap,
      avatar: StoryRingAvatar(
        avatarUrl: avatarUrl,
        name: label,
        diameter: metrics.diameter,
        ring: ring,
        watchedRingColor: metrics.watchedRing,
      ),
    );
  }
}

/// "Your story": your avatar with a "+" badge. With stories up it wears a ring
/// and opens them, and the badge alone opens the composer; without, the whole
/// bubble opens the composer.
class _YourStoryBubble extends StatelessWidget {
  const _YourStoryBubble({
    required this.metrics,
    required this.me,
    required this.mine,
    required this.onOpen,
    required this.onAdd,
  });

  final _TrayMetrics metrics;
  final StoriesCurrentUser me;
  final StoryGroup? mine;
  final VoidCallback? onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final hasStories = mine != null;
    final avatarUrl = me.avatarUrl.isNotEmpty
        ? me.avatarUrl
        : (mine?.userAvatarUrl ?? '');
    const badgeSize = 22.0;

    return KeyedSubtree(
      key: const Key('stories-tray-your-story'),
      child: _BubbleFrame(
        metrics: metrics,
        label: 'Your story',
        onTap: onOpen ?? onAdd,
        avatar: SizedBox.square(
          dimension: metrics.diameter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              StoryRingAvatar(
                avatarUrl: avatarUrl,
                name: me.displayName,
                diameter: metrics.diameter,
                // Your own stories always count as seen, so the ring here
                // just says "you have a story up".
                ring: hasStories ? StoryRing.unwatched : StoryRing.none,
              ),
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: GestureDetector(
                  key: const Key('stories-tray-add-story'),
                  onTap: onAdd,
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    label: 'Add to your story',
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: metrics.badgeBorder,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 14,
                        color: DesignTokens.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBubble extends StatelessWidget {
  const _PlaceholderBubble({required this.metrics});

  final _TrayMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ExcludeSemantics(
      child: SizedBox(
        width: metrics.itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SmShimmer.circle(radius: metrics.diameter / 2, enabled: !still),
            const SizedBox(height: _TrayMetrics.labelGap),
            SizedBox(
              height: _TrayMetrics.labelHeight,
              child: Center(
                child: SmShimmer.text(
                  width: metrics.diameter * 0.7,
                  height: 8,
                  enabled: !still,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryBubble extends StatelessWidget {
  const _RetryBubble({required this.metrics, required this.onTap});

  final _TrayMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BubbleFrame(
      metrics: metrics,
      label: 'Retry',
      onTap: onTap,
      avatar: Container(
        key: const Key('stories-tray-retry'),
        width: metrics.diameter,
        height: metrics.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: metrics.watchedRing, width: 1.2),
        ),
        child: Icon(Icons.refresh, color: metrics.labelColor),
      ),
    );
  }
}
