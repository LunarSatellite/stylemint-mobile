import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The storefront page frame: a top bar that turns solid once the cover has
/// scrolled away, the hero (its cover runs under the bar), a tab bar that
/// sticks under the top bar, and the selected tab's slivers.
///
/// Switching tabs while the tab bar is pinned keeps it pinned and returns to
/// where the viewer left that tab.
class StorefrontScaffold extends StatefulWidget {
  const StorefrontScaffold({
    required this.title,
    required this.hero,
    required this.coverExtent,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
    required this.slivers,
    super.key,
    this.onShare,
    this.shareLabel = 'Share',
    this.onNearEnd,
    this.contentVersion,
  });

  /// Shown in the top bar once it is solid.
  final String title;

  /// Starts with the cover. The top [topBarExtentOf] of it sits under the
  /// top bar.
  final Widget hero;

  /// Height of the cover at the top of [hero], including the part under the
  /// top bar. The bar turns solid as the cover leaves.
  final double coverExtent;
  final List<String> tabs;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  /// The selected tab's content.
  final List<Widget> slivers;
  final VoidCallback? onShare;
  final String shareLabel;

  /// Called when the end of the content is close; load the next page.
  final VoidCallback? onNearEnd;

  /// Change it when the content may have grown or shrunk, so the end is
  /// checked again even without scrolling.
  final Object? contentVersion;

  static const double toolbarHeight = 52;

  /// Start the next page this close to the end.
  static const double nearEndExtent = 800;

  /// Status bar plus toolbar.
  static double topBarExtentOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + toolbarHeight;

  /// Tab bar height at the ambient text scale.
  static double tabBarExtentOf(BuildContext context) => math.max(
    48,
    (MediaQuery.textScalerOf(context).scale(14) * 1.4 + 26).roundToDouble(),
  );

  @override
  State<StorefrontScaffold> createState() => _StorefrontScaffoldState();
}

class _StorefrontScaffoldState extends State<StorefrontScaffold>
    with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _solid = ValueNotifier<double>(0);
  final Map<int, double> _offsets = {};
  TabController? _tabs;
  double _barExtent = StorefrontScaffold.toolbarHeight;

  /// Scroll offset at which the tab bar pins (the hero's layout height).
  double _heroExtent = 0;
  bool _endCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabs ??= _createTabs();
  }

  TabController _createTabs() => TabController(
    length: widget.tabs.length,
    vsync: this,
    initialIndex: widget.selectedTab.clamp(0, widget.tabs.length - 1),
    animationDuration: MallMetrics.reduceMotion(context)
        ? Duration.zero
        : DesignTokens.motionMedium,
  );

  @override
  void didUpdateWidget(StorefrontScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    final tabs = _tabs;
    if (tabs != null && oldWidget.tabs.length != widget.tabs.length) {
      tabs.dispose();
      _tabs = _createTabs();
    } else if (tabs != null && tabs.index != widget.selectedTab) {
      tabs.animateTo(widget.selectedTab);
    }
    if (oldWidget.selectedTab != widget.selectedTab) {
      _restoreScroll(oldWidget.selectedTab, widget.selectedTab);
    } else if (oldWidget.contentVersion != widget.contentVersion) {
      _scheduleEndCheck();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _solid.dispose();
    _tabs?.dispose();
    super.dispose();
  }

  void _onScroll() {
    _updateSolid();
    if (_scroll.position.extentAfter < StorefrontScaffold.nearEndExtent) {
      widget.onNearEnd?.call();
    }
  }

  void _updateSolid() {
    if (!_scroll.hasClients) return;
    const fadeLength = 56.0;
    final solidAt = math.max(fadeLength, widget.coverExtent - _barExtent);
    final value = ((_scroll.offset - (solidAt - fadeLength)) / fadeLength)
        .clamp(0.0, 1.0);
    if (value != _solid.value) _solid.value = value;
  }

  void _restoreScroll(int from, int to) {
    if (!_scroll.hasClients) return;
    final current = _scroll.offset;
    _offsets[from] = current;
    final pin = _heroExtent;
    if (pin <= 0 || current < pin) {
      // The hero is still in view: stay where the viewer is.
      _scheduleEndCheck();
      return;
    }
    final target = math.max(pin, _offsets[to] ?? pin);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(math.min(target, _scroll.position.maxScrollExtent));
      _checkEnd();
    });
  }

  void _scheduleEndCheck() {
    if (_endCheckScheduled) return;
    _endCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _endCheckScheduled = false;
      if (mounted) _checkEnd();
    });
  }

  void _checkEnd() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < StorefrontScaffold.nearEndExtent) {
      widget.onNearEnd?.call();
    }
  }

  void _onHeroExtent(double extent) {
    if (!mounted || extent == _heroExtent) return;
    setState(() => _heroExtent = extent);
    _updateSolid();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    _barExtent = topInset + StorefrontScaffold.toolbarHeight;
    final tabExtent = StorefrontScaffold.tabBarExtentOf(context);
    final heroExtent = _heroExtent;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _TopBarDelegate(
              extent: _barExtent,
              topInset: topInset,
              title: widget.title,
              solid: _solid,
              onShare: widget.onShare,
              shareLabel: widget.shareLabel,
            ),
          ),
          SliverToBoxAdapter(
            child: _UnderTopBar(
              pull: _barExtent,
              onExtent: _onHeroExtent,
              child: widget.hero,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              controller: _tabs!,
              labels: widget.tabs,
              extent: tabExtent,
              onTap: widget.onTabChanged,
            ),
          ),
          ...widget.slivers,
          // Lets the tab bar stay pinned when a tab's content is short.
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final needed =
                  constraints.viewportMainAxisExtent -
                  (constraints.precedingScrollExtent - heroExtent);
              return SliverToBoxAdapter(
                child: SizedBox(height: math.max(0, needed)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopBarDelegate extends SliverPersistentHeaderDelegate {
  const _TopBarDelegate({
    required this.extent,
    required this.topInset,
    required this.title,
    required this.solid,
    required this.onShare,
    required this.shareLabel,
  });

  final double extent;
  final double topInset;
  final String title;
  final ValueNotifier<double> solid;
  final VoidCallback? onShare;
  final String shareLabel;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final share = onShare;
    return ValueListenableBuilder<double>(
      valueListenable: solid,
      builder: (context, t, _) => ColoredBox(
        color: DesignTokens.bgAppFoundation.withValues(alpha: t),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            top: topInset,
            start: DesignTokens.s8,
            end: DesignTokens.s8,
          ),
          child: SizedBox(
            height: StorefrontScaffold.toolbarHeight,
            child: Row(
              children: [
                _BarButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Back',
                  solid: t,
                  onPressed: context.popOrHome,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: ExcludeSemantics(
                    excluding: t < 0.5,
                    child: Opacity(
                      opacity: t,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                if (share != null)
                  _BarButton(
                    icon: Icons.ios_share_rounded,
                    tooltip: shareLabel,
                    solid: t,
                    onPressed: share,
                  )
                else
                  const SizedBox(width: DesignTokens.minTouchTarget),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TopBarDelegate oldDelegate) =>
      extent != oldDelegate.extent ||
      topInset != oldDelegate.topInset ||
      title != oldDelegate.title ||
      solid != oldDelegate.solid ||
      onShare != oldDelegate.onShare ||
      shareLabel != oldDelegate.shareLabel;
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.solid,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;

  /// 0 over the cover (dark disc for contrast), 1 on the solid bar.
  final double solid;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x73000000).withValues(
          alpha: 0.45 * (1 - solid),
        ),
        fixedSize: const Size.square(DesignTokens.minTouchTarget),
        minimumSize: const Size.square(DesignTokens.minTouchTarget),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 19, color: DesignTokens.textWhite),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({
    required this.controller,
    required this.labels,
    required this.extent,
    required this.onTap,
  });

  final TabController controller;
  final List<String> labels;
  final double extent;
  final ValueChanged<int> onTap;

  static const double _indicatorWeight = 2;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        boxShadow: overlapsContent ? DesignTokens.shadowCard : null,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TabBar(
          controller: controller,
          onTap: onTap,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: DesignTokens.s4,
          ),
          labelPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: DesignTokens.s12,
          ),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          // White 2dp underline (the indicator's default side).
          indicator: const UnderlineTabIndicator(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          labelColor: DesignTokens.textWhite,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          overlayColor: const WidgetStatePropertyAll(Color(0x0FFFFFFF)),
          splashFactory: NoSplash.splashFactory,
          tabs: [
            for (final label in labels)
              Tab(height: extent - _indicatorWeight, text: label),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      controller != oldDelegate.controller ||
      extent != oldDelegate.extent ||
      onTap != oldDelegate.onTap ||
      !_sameLabels(labels, oldDelegate.labels);

  static bool _sameLabels(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Lays [child] out at its natural height but takes [pull] less space and
/// paints [pull] higher, so its top runs under the pinned top bar.
class _UnderTopBar extends SingleChildRenderObjectWidget {
  const _UnderTopBar({
    required this.pull,
    required this.onExtent,
    required Widget super.child,
  });

  final double pull;
  final ValueChanged<double> onExtent;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderUnderTopBar(pull: pull, onExtent: onExtent);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderUnderTopBar renderObject,
  ) {
    renderObject
      ..pull = pull
      ..onExtent = onExtent;
  }
}

class _RenderUnderTopBar extends RenderProxyBox {
  _RenderUnderTopBar({required double pull, required this.onExtent})
    : _pull = pull;

  double _pull;
  double _reported = -1;
  ValueChanged<double> onExtent;

  double get pull => _pull;

  set pull(double value) {
    if (value == _pull) return;
    _pull = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(child.size.width, math.max(0, child.size.height - _pull)),
    );
    final extent = size.height;
    if (extent != _reported) {
      _reported = extent;
      SchedulerBinding.instance.addPostFrameCallback((_) => onExtent(extent));
    }
  }

  @override
  Rect get paintBounds =>
      Rect.fromLTWH(0, -_pull, size.width, size.height + _pull);

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset.translate(0, -_pull));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(0, -_pull),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, -_pull, 0, 1);
  }
}
