import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_journey.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';

/// A whole journey, every step's reel included (`GET /v1/journeys/{id}`).
///
/// Fetched once per journey however many of its steps are swiped through.
/// No automatic retry: a 404 (the journey ended, or the server has no
/// journeys yet) should settle at once so the steps fall back to their own
/// reels.
final FutureProviderFamily<PublicJourney, String> publicJourneyProvider =
    FutureProvider.autoDispose.family<PublicJourney, String>(
      (ref, journeyId) =>
          ref.watch(reelsRemoteDataSourceProvider).getJourney(journeyId),
      retry: (_, _) => null,
    );

/// A journey step's reel: `(journeyId, reelId)`.
typedef JourneyStepKey = ({String journeyId, String reelId});

/// The reel behind one journey step, carrying the journey seen from that
/// step. From the journey when it loads; otherwise the reel on its own
/// (`GET /v1/public/reels/{id}`), whose `journeys[0]` says the same thing.
/// Null when neither can be read — the step says it is unavailable.
final FutureProviderFamily<Reel?, JourneyStepKey> journeyStepReelProvider =
    FutureProvider.autoDispose.family<Reel?, JourneyStepKey>((ref, key) async {
      PublicJourney? journey;
      try {
        journey = await ref.watch(publicJourneyProvider(key.journeyId).future);
      } on Object {
        journey = null;
      }
      final fromJourney = journey?.reels[key.reelId];
      if (fromJourney != null) return fromJourney;

      final either = await ref
          .watch(reelsRepositoryProvider)
          .getReelDetail(key.reelId);
      return either.fold((_) => null, (reel) {
        if (journey != null && journey.journey.indexOfReel(reel.id) >= 0) {
          return reel.copyWith(journey: journey.journeyFor(reel.id));
        }
        return reel;
      });
    }, retry: (_, _) => null);

/// Whether the journey indicator still shows its "swipe →" hint.
class JourneyHintState {
  const JourneyHintState({
    this.loaded = false,
    this.seen = 0,
    this.dismissed = false,
  });

  final bool loaded;

  /// Journey reels the hint has been shown on.
  final int seen;

  /// Dismissed by hand, or the viewer already swiped between steps.
  final bool dismissed;

  bool get showsHint =>
      loaded && !dismissed && seen < JourneyHintNotifier.timesShown;
}

/// Remembers, on this device only, how often the journey swipe hint has
/// been shown and whether it was dismissed.
class JourneyHintNotifier extends StateNotifier<JourneyHintState> {
  JourneyHintNotifier() : super(const JourneyHintState()) {
    unawaited(_load());
  }

  /// How many journey reels show the hint before it stops by itself.
  static const int timesShown = 3;

  static const String seenKey = 'journey_swipe_hint_seen';
  static const String dismissedKey = 'journey_swipe_hint_dismissed';

  final Set<String> _countedReels = {};

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      state = JourneyHintState(
        loaded: true,
        seen: prefs.getInt(seenKey) ?? 0,
        dismissed: prefs.getBool(dismissedKey) ?? false,
      );
    } on Object {
      // Storage unavailable: show the hint as if new; nothing is remembered.
      if (mounted) state = const JourneyHintState(loaded: true);
    }
  }

  /// Counts one journey reel the hint appeared on — once per reel per run.
  /// The card that asked keeps showing its hint (it took its own snapshot of
  /// [JourneyHintState.showsHint]); later reels see the new count.
  void recordShown(String reelId) {
    if (!state.showsHint || !_countedReels.add(reelId)) return;
    final seen = state.seen + 1;
    state = JourneyHintState(
      loaded: state.loaded,
      seen: seen,
      dismissed: state.dismissed,
    );
    unawaited(_save((prefs) => prefs.setInt(seenKey, seen)));
  }

  /// Never show the hint again on this device.
  void dismiss() {
    if (state.dismissed) return;
    state = JourneyHintState(
      loaded: state.loaded,
      seen: state.seen,
      dismissed: true,
    );
    unawaited(_save((prefs) => prefs.setBool(dismissedKey, true)));
  }

  Future<void> _save(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } on Object {
      // Best effort: a hint shown once more is harmless.
    }
  }
}

final StateNotifierProvider<JourneyHintNotifier, JourneyHintState>
journeyHintProvider =
    StateNotifierProvider<JourneyHintNotifier, JourneyHintState>(
      (ref) => JourneyHintNotifier(),
    );
