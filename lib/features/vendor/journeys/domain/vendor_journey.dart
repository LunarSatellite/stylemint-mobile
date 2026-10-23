/// The seller side of collaborative journey reels (journey reels contract
/// v1 §4). Pure Dart.
library;

/// `JourneyState`.
enum JourneyState {
  active,
  ended;

  static JourneyState fromWire(Object? raw) =>
      raw == 2 || raw == 'ended' || raw == 'Ended'
      ? JourneyState.ended
      : JourneyState.active;

  int get wire => this == JourneyState.active ? 1 : 2;
}

/// `JourneyStepState`. Only invited and active steps reach the seller app.
enum JourneyStepState {
  invited,
  active,
  left,
  removed,
  declined;

  static JourneyStepState fromWire(Object? raw) => switch (raw) {
    1 || 'invited' || 'Invited' => JourneyStepState.invited,
    3 || 'left' || 'Left' => JourneyStepState.left,
    4 || 'removed' || 'Removed' => JourneyStepState.removed,
    5 || 'declined' || 'Declined' => JourneyStepState.declined,
    _ => JourneyStepState.active,
  };
}

/// `JourneyRole`: the caller's place in a journey.
enum JourneyRole {
  owner,
  member,
  invitee;

  static JourneyRole fromWire(Object? raw) => switch (raw) {
    1 || 'owner' || 'Owner' => JourneyRole.owner,
    3 || 'invitee' || 'Invitee' => JourneyRole.invitee,
    _ => JourneyRole.member,
  };

  int get wire => switch (this) {
    JourneyRole.owner => 1,
    JourneyRole.member => 2,
    JourneyRole.invitee => 3,
  };
}

/// `JourneyStepHiddenReason`.
enum JourneyStepHiddenReason {
  none,
  awaitingReel,
  reelNotPublished,
  reelModerated,
  reelMissing,
  journeyEnded;

  static JourneyStepHiddenReason fromWire(Object? raw) => switch (raw) {
    1 => JourneyStepHiddenReason.awaitingReel,
    2 => JourneyStepHiddenReason.reelNotPublished,
    3 => JourneyStepHiddenReason.reelModerated,
    4 => JourneyStepHiddenReason.reelMissing,
    5 => JourneyStepHiddenReason.journeyEnded,
    _ => JourneyStepHiddenReason.none,
  };

  /// Why the step is not on the buyers' feed, said plainly. Null when it is.
  String? get sentence => switch (this) {
    JourneyStepHiddenReason.none => null,
    JourneyStepHiddenReason.awaitingReel => 'Waiting for them to accept',
    JourneyStepHiddenReason.reelNotPublished => 'Hidden: the reel is not published',
    JourneyStepHiddenReason.reelModerated =>
      'Hidden: the reel was taken down by a moderator',
    JourneyStepHiddenReason.reelMissing => 'Hidden: the reel no longer exists',
    JourneyStepHiddenReason.journeyEnded => 'The journey has ended',
  };
}

/// One open step (`VendorJourneyDto.steps[]`).
class VendorJourneyStep {
  const VendorJourneyStep({
    required this.id,
    required this.index,
    required this.state,
    required this.vendorAccountId,
    required this.vendorName,
    this.vendorLogoUrl,
    this.reelId,
    this.thumbnailUrl,
    this.caption,
    this.isVisible = false,
    this.hiddenReason = JourneyStepHiddenReason.none,
    this.inviteNote,
    this.invitedUtc,
    this.acceptedUtc,
  });

  final String id;
  final int index;
  final JourneyStepState state;
  final String vendorAccountId;
  final String vendorName;
  final String? vendorLogoUrl;
  final String? reelId;
  final String? thumbnailUrl;
  final String? caption;
  final bool isVisible;
  final JourneyStepHiddenReason hiddenReason;
  final String? inviteNote;
  final DateTime? invitedUtc;
  final DateTime? acceptedUtc;

  bool get isInvite => state == JourneyStepState.invited;
}

/// `VendorJourneyDto`.
class VendorJourney {
  const VendorJourney({
    required this.id,
    required this.state,
    required this.ownerVendorAccountId,
    required this.ownerName,
    required this.myRole,
    required this.steps,
    this.title,
    this.city,
    this.ownerLogoUrl,
    this.myStepId,
    this.isLive = false,
    this.visibleStepCount = 0,
    this.maxSteps = 8,
    this.endedUtc,
    this.endedByAdmin = false,
    this.endReason,
    this.updatedUtc,
  });

  final String id;
  final String? title;
  final String? city;
  final JourneyState state;
  final String ownerVendorAccountId;
  final String ownerName;
  final String? ownerLogoUrl;
  final JourneyRole myRole;
  final String? myStepId;
  final bool isLive;
  final int visibleStepCount;
  final int maxSteps;
  final DateTime? endedUtc;
  final bool endedByAdmin;
  final String? endReason;
  final DateTime? updatedUtc;

  /// Open steps (invited and active), in order.
  final List<VendorJourneyStep> steps;

  bool get isEnded => state == JourneyState.ended;
  bool get isOwner => myRole == JourneyRole.owner;
  bool get isInvitee => myRole == JourneyRole.invitee;

  /// The title, or "{owner} journey" (contract §6 `journeyTitle`).
  String get displayTitle {
    final named = title?.trim();
    if (named != null && named.isNotEmpty) return named;
    return ownerName.trim().isEmpty ? 'Journey' : '${ownerName.trim()} journey';
  }

  VendorJourneyStep? get myStep {
    final id = myStepId;
    if (id == null) return null;
    for (final step in steps) {
      if (step.id == id) return step;
    }
    return null;
  }

  bool get canAddSteps => !isEnded && steps.length < maxSteps;

  /// The same journey with its steps in a new order (a drag not yet saved).
  VendorJourney withSteps(List<VendorJourneyStep> reordered) => VendorJourney(
    id: id,
    title: title,
    city: city,
    state: state,
    ownerVendorAccountId: ownerVendorAccountId,
    ownerName: ownerName,
    ownerLogoUrl: ownerLogoUrl,
    myRole: myRole,
    myStepId: myStepId,
    isLive: isLive,
    visibleStepCount: visibleStepCount,
    maxSteps: maxSteps,
    endedUtc: endedUtc,
    endedByAdmin: endedByAdmin,
    endReason: endReason,
    updatedUtc: updatedUtc,
    steps: List.unmodifiable(reordered),
  );

  /// Whether [step] is the owner's own (it cannot be removed; the owner
  /// ends the journey instead).
  bool isOwnerStep(VendorJourneyStep step) =>
      step.vendorAccountId == ownerVendorAccountId;
}

/// A business to invite (`JourneyVendorDto`).
class JourneyVendor {
  const JourneyVendor({
    required this.vendorAccountId,
    required this.businessName,
    this.logoUrl,
    this.city,
    this.category = 0,
    this.isVerified = false,
  });

  final String vendorAccountId;
  final String businessName;
  final String? logoUrl;
  final String? city;

  /// 0 product seller · 1 hotel · 2 travel agency · 3 bank.
  final int category;
  final bool isVerified;

  String get categoryLabel => switch (category) {
    1 => 'Hotel',
    2 => 'Travel agency',
    3 => 'Bank',
    _ => 'Shop',
  };
}

/// One of my reels, for the reel picker (`JourneyReelOptionDto`).
class JourneyReelOption {
  const JourneyReelOption({
    required this.reelId,
    this.thumbnailUrl,
    this.caption,
    this.publishedAtUtc,
    this.journeyCount = 0,
    this.canUse = true,
    this.reason,
  });

  final String reelId;
  final String? thumbnailUrl;
  final String? caption;
  final DateTime? publishedAtUtc;
  final int journeyCount;
  final bool canUse;
  final String? reason;
}
