import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/journey/journey_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_landing_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/reel_view_recorder.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reels_pager.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A reel opened by id at `/reels/:reelId`: a StyleMint share link (the
/// Android App Link lands here) or a search result.
///
/// Opens full screen in the same [ReelsPager] as the Home feed: the landed
/// reel first, then its related reels, then the general feed, so the viewer
/// keeps scrolling. A back button floats top-left over the reel, beside the
/// rail and overlays every feed page already draws over its player.
class ReelDetailScreen extends ConsumerStatefulWidget {
  const ReelDetailScreen({required this.reelId, this.journeyId, super.key});

  final String reelId;

  /// `?journey=` on the link (journey reels contract v1 §3): open the reel
  /// as that journey's step, even when its own `journeys[0]` names another
  /// (or none). Null: the reel's own journey, if any, as in the feed.
  final String? journeyId;

  @override
  ConsumerState<ReelDetailScreen> createState() => _ReelDetailScreenState();
}

class _ReelDetailScreenState extends ConsumerState<ReelDetailScreen> {
  final ReelsPagerController _pager = ReelsPagerController();

  /// Reels watched here count the same as reels watched in the feed. Read
  /// once and held: the last reel's dwell arrives during dispose, when a
  /// provider can no longer be looked up.
  late final ReelViewRecorder _views = ref.read(reelViewRecorderProvider);

  @override
  void didUpdateWidget(ReelDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reelId != widget.reelId) _pager.jumpToStart();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final landing = reelLandingNotifierProvider(widget.reelId);
    final state = ref.watch(landing);
    return Scaffold(
      backgroundColor: DesignTokens.baseBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          switch (state) {
            ReelLandingLoading() => const SmPageLoader(),
            ReelLandingFailure(:final failure) => SmErrorView(
              message: failure.isNotFound
                  ? 'This reel is no longer available.'
                  : "Couldn't load this reel.",
              onRetry: () => unawaited(ref.read(landing.notifier).load()),
            ),
            ReelLandingReady(:final reels) => _ready(reels),
          },
          const _BackButton(),
        ],
      ),
    );
  }

  Widget _ready(List<Reel> reels) {
    final landing = reelLandingNotifierProvider(widget.reelId);
    final shown = _withLinkedJourney(reels);
    if (shown == null) return const SmPageLoader();
    return ReelsPager(
      controller: _pager,
      reels: shown,
      onNearEnd: () => unawaited(ref.read(landing.notifier).fetchNextPage()),
      onReelDwell: _views.recordDwell,
    );
  }

  List<Reel>? _adoptedFrom;
  List<Reel>? _adopted;

  /// [reels] with the landed reel set up as a step of the linked journey.
  ///
  /// Unchanged without `?journey=`, when the reel already carries that
  /// journey, or when the journey cannot be loaded (ended, unknown, no
  /// journeys on the server yet) or does not include the reel — the reel
  /// then plays as an ordinary reel. Null while the journey is still
  /// loading: the page waits rather than playing the reel plain and then
  /// rebuilding it as a journey a moment later.
  ///
  /// The adopted list is kept while [reels] is the same list, so the pager
  /// is not handed a new list on every build.
  List<Reel>? _withLinkedJourney(List<Reel> reels) {
    final journeyId = widget.journeyId;
    if (journeyId == null || journeyId.isEmpty || reels.isEmpty) return reels;
    final landed = reels.first;
    if (landed.journey?.journeyId == journeyId) return reels;
    final journey = ref.watch(publicJourneyProvider(journeyId));
    if (journey.isLoading && !journey.hasValue) return null;
    final loaded = journey.value;
    if (loaded == null ||
        !loaded.journey.isSwipeable ||
        loaded.journey.indexOfReel(landed.id) < 0) {
      return reels;
    }
    if (identical(_adoptedFrom, reels) && _adopted != null) return _adopted;
    _adoptedFrom = reels;
    return _adopted = [
      landed.copyWith(journey: loaded.journeyFor(landed.id)),
      ...reels.skip(1),
    ];
  }
}

/// Floats over the top-left of the reel, clear of the status bar and of the
/// sound button on the right.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s12),
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => context.popOrHome(),
            style: IconButton.styleFrom(
              backgroundColor: DesignTokens.baseBlack.withValues(alpha: 0.45),
              fixedSize: const Size.square(40),
              minimumSize: const Size.square(40),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: DesignTokens.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}
