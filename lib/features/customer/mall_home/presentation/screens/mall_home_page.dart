import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_zones.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/mall_home_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/home_mode_switch.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_home_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_home_skeleton.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_home_states.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Mall: `GET api/v1/public/home` drawn zone by zone in server order,
/// under Home's "Mall | Reels" switch.
///
/// The page owns two things the blocks cannot own themselves — the scroll
/// offset the cinematic zone reads for depth, and which imagery is worth
/// warming — and otherwise stays out of the way. Sections are built lazily by
/// a `SliverList`, so a page of nine blocks costs one screen of widgets and
/// each block introduces itself as it comes into view.
class MallHomePage extends ConsumerStatefulWidget {
  const MallHomePage({super.key});

  @override
  ConsumerState<MallHomePage> createState() => _MallHomePageState();
}

class _MallHomePageState extends ConsumerState<MallHomePage> {
  final ScrollController _scroll = ScrollController();

  /// Published to the blocks that move with the page. Stops changing once the
  /// cinematic zone is well out of sight, so scrolling the rest of the page
  /// notifies nothing at all.
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);

  final Set<String> _precached = <String>{};

  /// Past this there is no parallax left to drive.
  static const double _maxTrackedOffset = 1200;

  /// Cards warmed from the first product rail.
  static const int _precacheRailCards = 4;

  MallHomeNotifier get _notifier => ref.read(mallHomeNotifierProvider.notifier);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _offset.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final raw = _scroll.offset;
    final next = raw < 0
        ? 0.0
        : (raw > _maxTrackedOffset ? _maxTrackedOffset : raw);
    if (next != _offset.value) _offset.value = next;
  }

  Future<void> _refresh() async {
    final updated = await _notifier.refresh();
    if (!updated && mounted) {
      SmSnackbar.error(context, "Couldn't refresh the Mall. Please try again.");
    }
  }

  /// Home re-tapped while the Mall shows: back to the top, then refresh.
  void _onReselected() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      if (MallMetrics.reduceMotion(context)) {
        _scroll.jumpTo(0);
      } else {
        unawaited(
          _scroll.animateTo(
            0,
            duration: DesignTokens.motionSlow,
            curve: DesignTokens.motionCurve,
          ),
        );
      }
    }
    ref
        .read(mallHomeNotifierProvider)
        .maybeWhen(
          loadSuccess: (_) => unawaited(_refresh()),
          loadInProgress: () {},
          orElse: () => unawaited(_notifier.load()),
        );
  }

  /// Warms the hero and the first rail only.
  ///
  /// Each image is decoded at the size it will be drawn at rather than at its
  /// natural size — warming a full-resolution campaign photograph into a
  /// 3.8 GB device is how a home page gets itself killed.
  void _schedulePrecache(MallHome home) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final warm = <({String url, int width})>[];

    final hero = home.sections.whereType<HomeCampaignsSection>().firstOrNull;
    final heroUrl = hero?.items.firstOrNull?.heroImageUrl;
    if (heroUrl != null) {
      warm.add((url: heroUrl, width: (screenWidth * ratio).round()));
    }

    final rail = home.sections.whereType<HomeProductsSection>().firstOrNull;
    if (rail != null) {
      final cardWidth = (MallProductCard.regularWidth * ratio).round();
      for (final product in rail.items.take(_precacheRailCards)) {
        final url = product.imageUrl;
        if (url != null) warm.add((url: url, width: cardWidth));
      }
    }

    final pending = warm.where((item) => !_precached.contains(item.url));
    if (pending.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final item in pending) {
        if (!_precached.add(item.url)) continue;
        unawaited(
          precacheImage(
            ResizeImage(
              CachedNetworkImageProvider(item.url),
              width: item.width,
            ),
            context,
            onError: (_, _) {},
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen<int>(mallHomeReselectedProvider, (_, _) => _onReselected())
      ..listen<bool>(mallViewerSignedInProvider, (previous, next) {
        // Signing in or out changes what the page is personalised for.
        if (previous != next) unawaited(_notifier.refresh());
      });

    final state = ref.watch(mallHomeNotifierProvider);
    final topInset = homeTopInset(context);
    return ColoredBox(
      color: DesignTokens.bgAppFoundation,
      child: state.when(
        initial: () => MallHomeSkeleton(topInset: topInset),
        loadInProgress: () => MallHomeSkeleton(topInset: topInset),
        loadFailure: (failure) => _problem(
          failure.isNoInternet
              ? MallHomeProblem.offline
              : MallHomeProblem.unreachable,
          topInset,
          onRetry: () => unawaited(_notifier.load()),
        ),
        loadSuccess: (home) => home.sections.isEmpty
            ? _problem(
                MallHomeProblem.empty,
                topInset,
                onRetry: () => unawaited(_refresh()),
              )
            : _buildHome(home, topInset),
      ),
    );
  }

  Widget _problem(
    MallHomeProblem problem,
    double topInset, {
    required VoidCallback onRetry,
  }) => RefreshIndicator(
    onRefresh: _refresh,
    edgeOffset: topInset,
    color: DesignTokens.textWhite,
    backgroundColor: DesignTokens.surfaceRaised,
    child: MallHomeStateView(
      problem: problem,
      onRetry: onRetry,
      topInset: topInset,
    ),
  );

  Widget _buildHome(MallHome home, double topInset) {
    _schedulePrecache(home);
    final sections = home.sections;
    final firstName = home.greetingFirstName;
    final leadsWithHero = sections.first is HomeCampaignsSection;
    final greeting = firstName == null
        ? null
        : _Greeting(
            salutation: mallSalutation(ref.read(mallClockProvider)()),
            name: firstName,
            onHero: leadsWithHero,
          );
    final markers = _sectionMarkers(sections);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return MallScrollLink(
      offset: _offset,
      child: RefreshIndicator(
        onRefresh: _refresh,
        edgeOffset: topInset,
        color: DesignTokens.textWhite,
        backgroundColor: DesignTokens.surfaceRaised,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          // Flutter's default cache extent (250px) is deliberately left
          // alone: it builds the next block just before it is needed and
          // keeps the rest of a nine-block page out of memory.
          slivers: [
            // The hero runs under the Home switch; every other opening needs
            // the inset drawn for it.
            if (!leadsWithHero) ...[
              SliverToBoxAdapter(child: SizedBox(height: topInset)),
              if (greeting != null) SliverToBoxAdapter(child: greeting),
            ],
            SliverList.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final isHero = section is HomeCampaignsSection;
                final block = MallHomeSectionView(
                  key: ValueKey('mall-section-${section.id}-$index'),
                  section: section,
                  index: markers[index],
                  topInset: topInset,
                  overline: isHero ? greeting : null,
                );
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: isHero
                        ? 0
                        : (index == 0 ? DesignTokens.s24 : DesignTokens.s40),
                  ),
                  // The hero carries its own motion; everything else arrives
                  // once, as it scrolls into view.
                  child: isHero ? block : MallEnter(child: block),
                );
              },
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: DesignTokens.s48 + bottomInset),
            ),
          ],
        ),
      ),
    );
  }

  /// 1-based marker for every section that draws a numbered header; 0 for the
  /// ones that do not.
  ///
  /// Only blocks that actually show a marker are counted, so the numbers a
  /// reader sees run 01, 02, 03 with no gaps where a full-bleed block sat.
  static List<int> _sectionMarkers(List<HomeSection> sections) {
    final markers = <int>[];
    var next = 0;
    for (final section in sections) {
      final numbered = switch (section) {
        // The stage and the trust strip carry no header.
        HomeCampaignsSection() || HomeTrustSection() => false,
        // The drop plate carries its own title, not a numbered header.
        HomeProductsSection(:final items) => !isDropBlock(items),
        _ => true,
      };
      if (numbered) next++;
      markers.add(numbered ? next : 0);
    }
    return markers;
  }
}

/// "Good evening, Sumendra" — Asia/Kathmandu time of day.
///
/// Over the hero it sits on the top scrim and fades with the rest of the
/// stage copy; without a hero it opens the page on its own.
class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.salutation,
    required this.name,
    required this.onHero,
  });

  final String salutation;
  final String name;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$salutation, '),
          TextSpan(
            text: name,
            style: const TextStyle(
              color: DesignTokens.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: onHero ? 14 : 16,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: onHero ? DesignTokens.textLight : DesignTokens.textMuted,
      ),
    );
    if (onHero) return text;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
      child: text,
    );
  }
}
