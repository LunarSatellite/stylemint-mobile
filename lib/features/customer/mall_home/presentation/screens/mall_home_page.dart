import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/mall_home_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/home_mode_switch.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_home_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_home_skeleton.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Mall: `GET api/v1/public/home` drawn section by section in server
/// order, under Home's "Mall | Reels" switch.
class MallHomePage extends ConsumerStatefulWidget {
  const MallHomePage({super.key});

  @override
  ConsumerState<MallHomePage> createState() => _MallHomePageState();
}

class _MallHomePageState extends ConsumerState<MallHomePage> {
  final ScrollController _scroll = ScrollController();
  final Set<String> _precached = <String>{};

  MallHomeNotifier get _notifier => ref.read(mallHomeNotifierProvider.notifier);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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

  /// Warms campaign imagery so the hero doesn't pop in page by page.
  void _schedulePrecache(MallHome home) {
    final urls = [
      for (final section in home.sections.whereType<HomeCampaignsSection>())
        for (final campaign in section.items) ?campaign.heroImageUrl,
    ].where((url) => !_precached.contains(url)).toList();
    if (urls.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final url in urls) {
        if (!_precached.add(url)) continue;
        unawaited(
          precacheImage(
            CachedNetworkImageProvider(url),
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
        loadFailure: (failure) => Padding(
          padding: EdgeInsetsDirectional.only(top: topInset),
          child: SmErrorView(
            message: failure.isNoInternet
                ? 'No internet connection. Check your connection and try '
                      'again.'
                : "We couldn't load the Mall. Please try again.",
            onRetry: () => unawaited(_notifier.load()),
          ),
        ),
        loadSuccess: (home) => _buildHome(home, topInset),
      ),
    );
  }

  Widget _buildHome(MallHome home, double topInset) {
    _schedulePrecache(home);
    final firstName = home.greetingFirstName;
    final sections = home.sections;
    final leadProducts = sections.indexWhere((s) => s is HomeProductsSection);

    return RefreshIndicator(
      onRefresh: _refresh,
      edgeOffset: topInset,
      color: DesignTokens.textWhite,
      backgroundColor: DesignTokens.surfaceRaised,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topInset)),
          if (firstName != null)
            SliverToBoxAdapter(
              child: _Greeting(
                salutation: mallSalutation(ref.read(mallClockProvider)()),
                name: firstName,
              ),
            ),
          if (sections.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: MallEmptyState(
                icon: Icons.storefront_outlined,
                title: 'The Mall is getting ready',
                body: 'New arrivals, creators and brands will appear here '
                    'soon.',
                actionLabel: 'Refresh',
                onAction: () => unawaited(_refresh()),
              ),
            )
          else
            for (final (index, section) in sections.indexed)
              SliverToBoxAdapter(
                key: ValueKey('mall-section-${section.id}-$index'),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: index == 0 ? DesignTokens.s4 : DesignTokens.s40,
                  ),
                  child: MallHomeSectionView(
                    section: section,
                    prominent: index == leadProducts,
                  ),
                ),
              ),
          const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s48)),
        ],
      ),
    );
  }
}

/// "Good evening, Sumendra" — Asia/Kathmandu time of day.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.salutation, required this.name});

  final String salutation;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
      child: Text.rich(
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
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.35,
          color: DesignTokens.textMuted,
        ),
      ),
    );
  }
}
