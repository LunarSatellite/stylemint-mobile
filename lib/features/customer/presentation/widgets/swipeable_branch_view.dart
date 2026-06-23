import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lays the shell's branch navigators in a horizontal [PageView] so the user
/// can swipe left/right between the bottom-bar tabs, in addition to tapping.
///
/// Supplied as the shell route's `navigatorContainerBuilder`. Each branch is
/// kept alive (preserving its navigation stack + scroll position) and stays in
/// sync with [StatefulNavigationShell.currentIndex] — bottom-bar taps and deep
/// links animate the page, and swipes drive `goBranch`.
class SwipeableBranchView extends StatefulWidget {
  const SwipeableBranchView({
    required this.navigationShell,
    required this.branches,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  /// The branch Navigator widgets, one per tab, from the shell route.
  final List<Widget> branches;

  @override
  State<SwipeableBranchView> createState() => _SwipeableBranchViewState();
}

class _SwipeableBranchViewState extends State<SwipeableBranchView> {
  late final PageController _controller = PageController(
    initialPage: widget.navigationShell.currentIndex,
  );

  @override
  void didUpdateWidget(SwipeableBranchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync the page when the branch changed from a bottom-bar tap or deep link
    // (a swipe already moved the page, so the rounded page matches the index).
    final index = widget.navigationShell.currentIndex;
    if (_controller.hasClients && _controller.page?.round() != index) {
      unawaited(
        _controller.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.branches.length,
      onPageChanged: (index) {
        if (index != widget.navigationShell.currentIndex) {
          widget.navigationShell.goBranch(index);
        }
      },
      itemBuilder: (context, index) {
        final isActive = index == widget.navigationShell.currentIndex;
        return _KeepAliveBranch(
          // Mirror go_router's default indexed-stack container: only the
          // active branch ticks (drives animations/video — see ReelPlayer's
          // TickerMode pause) and receives pointer events.
          child: TickerMode(
            enabled: isActive,
            child: IgnorePointer(
              ignoring: !isActive,
              child: widget.branches[index],
            ),
          ),
        );
      },
    );
  }
}

/// Keeps an off-screen branch mounted so its state survives tab swipes.
class _KeepAliveBranch extends StatefulWidget {
  const _KeepAliveBranch({required this.child});

  final Widget child;

  @override
  State<_KeepAliveBranch> createState() => _KeepAliveBranchState();
}

class _KeepAliveBranchState extends State<_KeepAliveBranch>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
