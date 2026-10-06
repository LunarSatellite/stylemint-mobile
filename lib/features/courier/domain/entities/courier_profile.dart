/// Where a courier application has got to. Mirrors the backend's
/// `CourierProfileState`.
///
/// The app branches hard on this, because the four non-working states need
/// four different screens, not one "not ready yet" message: an applicant needs
/// the KYC form, a rejected applicant needs the reason, a suspended courier
/// needs to know why and for how long, and a banned one has nothing to do.
enum CourierProfileState {
  applied(1),
  kycInReview(2),
  rejected(3),
  onboarded(4),
  active(5),
  suspended(6),
  banned(7);

  const CourierProfileState(this.wire);

  final int wire;

  static CourierProfileState fromWire(int? value) =>
      CourierProfileState.values.firstWhere(
        (state) => state.wire == value,
        orElse: () => CourierProfileState.applied,
      );

  /// How to name this state to the courier themselves.
  ///
  /// Not the enum name: "kycInReview" is ours, and "Onboarded" tells a rider
  /// nothing about why no work is arriving. The gate screen writes a full
  /// explanation per state; this is the short form for a profile row.
  String get label => switch (this) {
    CourierProfileState.applied => 'Application submitted',
    CourierProfileState.kycInReview => 'Documents under review',
    CourierProfileState.rejected => 'Not approved',
    // Named for what it means to them — cleared, not yet receiving work —
    // because the backend only sends offers to Active couriers.
    CourierProfileState.onboarded => 'Approved, awaiting activation',
    CourierProfileState.active => 'Active',
    CourierProfileState.suspended => 'Suspended',
    CourierProfileState.banned => 'Closed',
  };

  /// Whether this courier's STATE allows them to be offered and carry work.
  ///
  /// Onboarded counts. It did not used to: the backend gated on Active, and
  /// nothing ever advanced a courier into Active — not a completed hop, not
  /// approval, only an operator pressing the reinstate button — so an
  /// approved rider was permanently ineligible. The gate is now being on
  /// shift (`CourierProfile.isOnline`), with cleared review required
  /// alongside it, which is what this answers.
  ///
  /// Must agree with the server's candidate query, which filters
  /// `IsOnline && State IN (Onboarded, Active)`. State alone is not enough to
  /// receive work — see [CourierProfile.isOnline].
  bool get canCarry =>
      this == CourierProfileState.onboarded ||
      this == CourierProfileState.active;

  /// Whether the courier is waiting on someone else rather than on themselves.
  bool get isAwaitingReview => this == CourierProfileState.kycInReview;

  /// Whether this courier has passed its checks — the delivery equivalent of
  /// an approved profile application, and exactly what Identity accepts as
  /// grounds for activating `RoleType.Courier`.
  ///
  /// Was broader than [canCarry] when that meant Active only. Since 1e44f097
  /// the two agree on membership — the server's candidate query filters
  /// IsOnline && State IN (Onboarded, Active) — and availability is carried by
  /// the rider's own online switch rather than by the lifecycle state.
  /// Suspended and Banned are excluded — they had it taken away, and a role
  /// claiming otherwise would disagree with the only thing that decides
  /// whether a parcel can be carried.
  ///
  /// Must agree with `DeliveryCourierStandingLookup` on the server. If the two
  /// drift, the app shows a courier a role the backend then refuses to
  /// activate, silently.
  bool get hasClearedChecks =>
      this == CourierProfileState.onboarded ||
      this == CourierProfileState.active;
}

/// How far up the delivery ladder a courier is. Mirrors `DeliveryTier`.
///
/// It decides which offers reach them: Neighbor is short local hops, Traveler
/// unlocks journeys declared in advance, Pro is the full network.
enum DeliveryTier {
  neighbor(1),
  traveler(2),
  pro(3);

  const DeliveryTier(this.wire);

  final int wire;

  static DeliveryTier fromWire(int? value) => DeliveryTier.values.firstWhere(
    (tier) => tier.wire == value,
    orElse: () => DeliveryTier.neighbor,
  );

  String get label => switch (this) {
    DeliveryTier.neighbor => 'Neighbour',
    DeliveryTier.traveler => 'Traveller',
    DeliveryTier.pro => 'Pro',
  };
}

/// Mirrors `VehicleKind`.
enum CourierVehicle {
  foot(1),
  bicycle(2),
  motorcycle(3),
  car(4),
  van(5);

  const CourierVehicle(this.wire);

  final int wire;

  static CourierVehicle? fromWire(int? value) => value == null
      ? null
      : CourierVehicle.values.where((v) => v.wire == value).firstOrNull;

  String get label => switch (this) {
    CourierVehicle.foot => 'On foot',
    CourierVehicle.bicycle => 'Bicycle',
    CourierVehicle.motorcycle => 'Motorcycle',
    CourierVehicle.car => 'Car',
    CourierVehicle.van => 'Van',
  };
}

class CourierProfile {
  const CourierProfile({
    required this.id,
    required this.accountId,
    required this.state,
    required this.tier,
    required this.homeGeohash,
    this.vehicle,
    required this.escrowHeldAmount,
    required this.escrowRequiredAmount,
    required this.escrowCurrency,
    this.kycVerifiedUtc,
    this.suspendedReason,
    required this.failureStreak,
    this.isOnline = false,
    this.onlineChangedUtc,
    this.accountDisplayName,
    this.accountEmail,
    this.accountPhone,
  });

  final String id;
  final String accountId;
  final CourierProfileState state;
  final DeliveryTier tier;
  final String homeGeohash;
  final CourierVehicle? vehicle;

  /// Escrow is a deposit held against the parcels a courier carries. When held
  /// is below required, the router stops sending offers — which is a far more
  /// common reason for "no work" than having no work, so the dashboard shows
  /// both numbers rather than only the balance.
  final double escrowHeldAmount;
  final double escrowRequiredAmount;
  final String escrowCurrency;

  final DateTime? kycVerifiedUtc;
  final String? suspendedReason;

  /// Consecutive failed hops. The backend demotes a tier on a streak, so this
  /// is the number worth showing before it costs the courier something.
  final int failureStreak;

  /// Whether the courier is on shift and willing to be offered parcels.
  ///
  /// This, not [state], is what decides whether offers reach them: the
  /// backend's router gates on it because nothing ever advanced a courier
  /// into Active. Going on shift still requires cleared review, so a
  /// suspended or rejected courier cannot switch it on.
  final bool isOnline;

  /// When they last went on or off shift.
  final DateTime? onlineChangedUtc;

  /// Who the courier is, resolved from Identity by the server rather than
  /// stored on the profile — a courier profile holds an account id and
  /// nothing else about the person.
  ///
  /// Nullable because an account that signed up by phone may have set no
  /// display name, and an account with no email has none. The profile screen
  /// shows the gap rather than a placeholder.
  final String? accountDisplayName;
  final String? accountEmail;
  final String? accountPhone;

  bool get escrowShortfall => escrowHeldAmount < escrowRequiredAmount;

  double get escrowOutstanding =>
      escrowShortfall ? escrowRequiredAmount - escrowHeldAmount : 0;
}

/// Mirrors `DeviceKeyState`.
enum DeviceKeyState {
  active(1),
  revoked(2);

  const DeviceKeyState(this.wire);

  final int wire;

  static DeviceKeyState fromWire(int? value) =>
      DeviceKeyState.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => DeviceKeyState.active,
      );
}

/// A registered signing key, as the server sees it.
///
/// The private half never appears here — it lives only in this device's secure
/// storage (see `CourierDeviceKey`). A key listed as active that this device
/// cannot sign with means the key belongs to a different phone, which is the
/// case worth telling the courier about rather than silently failing a pickup.
class CourierDeviceKeyInfo {
  const CourierDeviceKeyInfo({
    required this.id,
    required this.publicKeyId,
    required this.deviceModel,
    required this.registeredUtc,
    required this.state,
    this.revokedUtc,
    this.revocationReason,
  });

  final String id;
  final String publicKeyId;
  final String deviceModel;
  final DateTime registeredUtc;
  final DeviceKeyState state;
  final DateTime? revokedUtc;
  final String? revocationReason;

  bool get isActive => state == DeviceKeyState.active;
}

/// Mirrors `TravelPlanState`.
enum TravelPlanState {
  proposed(1),
  confirmed(2),
  inProgress(3),
  completed(4),
  cancelled(5),
  expired(6);

  const TravelPlanState(this.wire);

  final int wire;

  static TravelPlanState fromWire(int? value) =>
      TravelPlanState.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => TravelPlanState.proposed,
      );

  bool get isOpen =>
      this == TravelPlanState.proposed ||
      this == TravelPlanState.confirmed ||
      this == TravelPlanState.inProgress;

  String get label => switch (this) {
    TravelPlanState.proposed => 'Proposed',
    TravelPlanState.confirmed => 'Confirmed',
    TravelPlanState.inProgress => 'In progress',
    TravelPlanState.completed => 'Completed',
    TravelPlanState.cancelled => 'Cancelled',
    TravelPlanState.expired => 'Expired',
  };
}

/// A journey the courier has declared, which the router matches
/// Traveler-tier hops against.
class CourierTravelPlan {
  const CourierTravelPlan({
    required this.id,
    required this.originGeohash,
    required this.destinationGeohash,
    required this.departsUtcStart,
    required this.departsUtcEnd,
    required this.arrivesUtcExpected,
    required this.vehicle,
    required this.maxWeightGrams,
    required this.state,
    this.cancellationReason,
  });

  final String id;
  final String originGeohash;
  final String destinationGeohash;
  final DateTime departsUtcStart;
  final DateTime departsUtcEnd;
  final DateTime arrivesUtcExpected;
  final CourierVehicle? vehicle;
  final double maxWeightGrams;
  final TravelPlanState state;
  final String? cancellationReason;
}

/// A reliability window, as the backend computed it.
///
/// Every rate is already a ratio in 0..1 server-side; nothing here recomputes
/// them from the counts, because the counts and the rates come from the same
/// snapshot and a client-side division would disagree with the tier decision
/// the backend actually made.
class CourierReliability {
  const CourierReliability({
    required this.windowStartUtc,
    required this.windowEndUtc,
    required this.hopsCompleted,
    required this.hopsAccepted,
    required this.hopsDeclined,
    required this.hopsFailed,
    required this.hopsOnTime,
    required this.averageCustomerRating,
    required this.onTimeRate,
    required this.acceptanceRate,
    required this.reliabilityScore,
  });

  final DateTime windowStartUtc;
  final DateTime windowEndUtc;
  final int hopsCompleted;
  final int hopsAccepted;
  final int hopsDeclined;
  final int hopsFailed;
  final int hopsOnTime;
  final double averageCustomerRating;
  final double onTimeRate;
  final double acceptanceRate;
  final double reliabilityScore;
}
