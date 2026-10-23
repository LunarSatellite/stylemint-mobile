import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

/// A reel's place in a collaborative journey (journey reels contract v1 §2,
/// `ReelJourneyDto`): businesses' reels linked in order, e.g. a bus company's
/// reel, then a Pokhara hotel's, then a paragliding school's.
///
/// Pure Dart. `stepIndex` and every step `index` are 0-based; people see
/// `stepIndex + 1`.
class ReelJourney {
  const ReelJourney({
    required this.journeyId,
    required this.stepIndex,
    required this.steps,
    this.title,
    this.city,
    int? stepCount,
    this.prevReelId,
    this.nextReelId,
  }) : _stepCount = stepCount;

  final String journeyId;
  final String? title;
  final String? city;

  /// This reel's position among the journey's visible steps.
  final int stepIndex;
  final int? _stepCount;
  final String? prevReelId;
  final String? nextReelId;

  /// Every visible step, in the owner's order.
  final List<ReelJourneyStep> steps;

  /// How many steps there are: the server's count, else the steps sent.
  int get stepCount => _stepCount ?? steps.length;

  /// Whether there is anything to swipe to: at least two steps, and this
  /// reel is one of them.
  bool get isSwipeable =>
      steps.length >= 2 && stepIndex >= 0 && stepIndex < steps.length;

  /// The title, or "{first business} journey" when the owner left it blank.
  String get displayTitle {
    final named = title?.trim();
    if (named != null && named.isNotEmpty) return named;
    final first = steps.isEmpty ? '' : steps.first.vendorName.trim();
    return first.isEmpty ? 'Journey' : '$first journey';
  }

  /// The step after [index], or null at the end.
  ReelJourneyStep? stepAfter(int index) =>
      index + 1 < steps.length ? steps[index + 1] : null;

  /// The same journey, seen from step [index]: what that step's own reel
  /// would have carried.
  ReelJourney atStep(int index) => ReelJourney(
    journeyId: journeyId,
    title: title,
    city: city,
    stepIndex: index,
    stepCount: stepCount,
    steps: steps,
    prevReelId: index > 0 && index - 1 < steps.length
        ? steps[index - 1].reelId
        : null,
    nextReelId: index + 1 < steps.length ? steps[index + 1].reelId : null,
  );

  /// The index of the step showing [reelId], or -1.
  int indexOfReel(String reelId) =>
      steps.indexWhere((step) => step.reelId == reelId);
}

/// One business's step in a [ReelJourney].
class ReelJourneyStep {
  const ReelJourneyStep({
    required this.stepId,
    required this.index,
    required this.vendorAccountId,
    required this.vendorName,
    required this.reelId,
    this.vendorLogoUrl,
    this.thumbnailUrl,
  });

  final String stepId;
  final int index;
  final String vendorAccountId;
  final String vendorName;
  final String? vendorLogoUrl;
  final String reelId;
  final String? thumbnailUrl;
}

/// A whole journey (`GET /v1/journeys/{id}`): its steps in order and each
/// step's reel, by reel id, each carrying the journey seen from its step.
class PublicJourney {
  const PublicJourney({required this.journey, required this.reels});

  final ReelJourney journey;
  final Map<String, Reel> reels;

  /// The journey as seen from the step showing [reelId] (step 0 when that
  /// reel is not one of its steps).
  ReelJourney journeyFor(String reelId) {
    final index = journey.indexOfReel(reelId);
    return journey.atStep(index < 0 ? 0 : index);
  }
}
