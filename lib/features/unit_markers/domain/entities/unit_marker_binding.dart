import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';

/// When a marker was attached to the physical item — backend
/// `UnitBindingStage`, serialised by name.
///
/// Both values are moments at which a person is holding the goods, which is
/// the only moment at which the binding can be true.
enum UnitBindingStage {
  pack('Pack', 'While packing'),
  handover('Handover', 'At handover'),
  unrecognised('', 'Stage not recognised');

  const UnitBindingStage(this.wire, this.label);

  final String wire;
  final String label;

  static UnitBindingStage fromJson(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      final needle = raw.toLowerCase();
      for (final value in values) {
        if (value != unrecognised && value.wire.toLowerCase() == needle) {
          return value;
        }
      }
    }
    return unrecognised;
  }

  /// The two a seller may choose. [unrecognised] is a read-side fallback and
  /// is never offered as an option.
  static const List<UnitBindingStage> selectable = [pack, handover];
}

/// How far an order line has travelled, as far as binding needs to know —
/// backend `OrderLineFulfilmentStage`.
///
/// The client keeps this so the bind screen can say *before* the call why a
/// control is closed, instead of letting the seller press a button that was
/// always going to be refused. The backend still decides; this only explains.
enum OrderLineFulfilmentStage {
  awaitingPack('AwaitingPack'),
  packed('Packed'),
  handedOver('HandedOver'),
  delivered('Delivered'),
  cancelled('Cancelled'),

  /// A stage this build does not know. Treated as *not bindable* and
  /// explained as unknown — never as an open door.
  unrecognised('');

  const OrderLineFulfilmentStage(this.wire);

  final String wire;

  static OrderLineFulfilmentStage fromJson(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      final needle = raw.toLowerCase();
      for (final value in values) {
        if (value != unrecognised && value.wire.toLowerCase() == needle) {
          return value;
        }
      }
    }
    return unrecognised;
  }

  /// True only at the two stages the backend accepts.
  bool get allowsBinding =>
      this == OrderLineFulfilmentStage.packed ||
      this == OrderLineFulfilmentStage.handedOver;

  /// Correction closes at exactly the same moment binding does, and for the
  /// same reason: once the parcel is with the buyer, which physical item they
  /// hold can no longer be observed.
  bool get allowsCorrection => allowsBinding;

  /// A heading for the closed-controls notice, naming *what* is closed rather
  /// than using one phrase for every stage. Null while the controls are open.
  String? get bindingClosedHeading => switch (this) {
    OrderLineFulfilmentStage.packed ||
    OrderLineFulfilmentStage.handedOver => null,
    OrderLineFulfilmentStage.awaitingPack => 'Nothing to tag yet',
    // Binding closes here too, but a packer reaching this screen after
    // delivery is almost always trying to fix a mis-scan, so the heading
    // names the thing they came for.
    OrderLineFulfilmentStage.delivered => 'Correction is closed',
    OrderLineFulfilmentStage.cancelled => 'This line was cancelled',
    OrderLineFulfilmentStage.unrecognised => 'Stage not recognised',
  };

  /// Why the controls are closed, in the seller's own terms. Null while they
  /// are open.
  ///
  /// This is the app's own wording, used *before* a call is made. Once a call
  /// has been made the server's sentence is shown instead — see
  /// [UnitMarkerBindRefusal].
  String? get bindingClosedReason => switch (this) {
    OrderLineFulfilmentStage.packed ||
    OrderLineFulfilmentStage.handedOver => null,
    OrderLineFulfilmentStage.awaitingPack =>
      'Nothing is packed on this order yet, so there is no item to tag.',
    OrderLineFulfilmentStage.delivered =>
      'This order has reached the buyer. Which physical item they hold can no '
          'longer be observed, so a marker can no longer be bound or '
          'corrected on it.',
    OrderLineFulfilmentStage.cancelled =>
      'This order line was cancelled, so there is no unit to tag.',
    OrderLineFulfilmentStage.unrecognised =>
      'This order line is at a stage this version of the app does not '
          'recognise, so it does not offer to bind or correct a marker.',
  };
}

/// One binding of a marker to an order line — backend `UnitMarkerBindingVm`.
///
/// The seller sees the order ids here because it is their own order. Nothing
/// on this type may travel to the public scan surface.
class UnitMarkerBinding {
  const UnitMarkerBinding({
    required this.id,
    required this.markerReference,
    required this.orderId,
    required this.subOrderId,
    required this.subOrderLineId,
    required this.boundAtStage,
    required this.boundAt,
    this.correctsBindingId,
    this.supersededAt,
    this.supersededReason,
  });

  final String id;
  final String markerReference;
  final String orderId;
  final String subOrderId;
  final String subOrderLineId;
  final UnitBindingStage boundAtStage;
  final DateTime? boundAt;

  /// Set on the row a correction created, pointing back at the row it
  /// replaced. The superseded row is kept; a correction is a second fact, not
  /// an erasure of the first.
  final String? correctsBindingId;

  /// Set on the row a correction retired. Null means this binding still
  /// stands.
  final DateTime? supersededAt;

  /// The reason the seller gave when correcting. Null on a row that was never
  /// superseded; never a canned string — the backend requires the seller's
  /// own words.
  final String? supersededReason;

  bool get isLive => supersededAt == null;
  bool get isCorrection => correctsBindingId != null;
}

/// Why the backend refused a bind or a correction, kept apart by *kind*
/// because the three read completely differently to a packer.
enum UnitMarkerBindRefusalKind {
  /// 409 `state.conflict` — the marker already carries a live binding. Not an
  /// error and not a retry: the seller has to decide whether the first
  /// binding was wrong, and if it was, record a correction with a reason.
  alreadyBound,

  /// 400 `rule.violation` — the stage, the variant or the line's quantity
  /// will not allow it. The backend's own sentence says which.
  ruleRefused,

  /// 404 — no such marker, or no such order line for this seller.
  ///
  /// A `403` ("this marker belongs to another vendor") is **not** in this
  /// list, because the shared `mapDioExceptionToNetworkException` folds 401
  /// and 403 into one `auth()` failure. The app cannot tell them apart
  /// without changing that mapper, so a 403 stays a failure rather than being
  /// guessed into a refusal here. Guessing is how a screen ends up telling a
  /// seller something that is not true.
  notFound,
}

/// A refusal, with the server's own wording kept intact.
///
/// The app never rewrites the sentence. The backend knows whether the line was
/// delivered, cancelled, over its quantity or minted for another variant, and
/// says so; paraphrasing it here is how a screen ends up telling a seller
/// something that is not true.
class UnitMarkerBindRefusal {
  const UnitMarkerBindRefusal({required this.kind, required this.message});

  final UnitMarkerBindRefusalKind kind;

  /// Rendered verbatim.
  final String message;
}

/// What a bind or a correction ended in. Success and refusal are different
/// outcomes and neither is an error state.
sealed class UnitMarkerBindOutcome {
  const UnitMarkerBindOutcome();
}

final class UnitMarkerBound extends UnitMarkerBindOutcome {
  const UnitMarkerBound(this.binding);

  final UnitMarkerBinding binding;
}

final class UnitMarkerBindRefused extends UnitMarkerBindOutcome {
  const UnitMarkerBindRefused(this.refusal);

  final UnitMarkerBindRefusal refusal;
}

/// The marker a packer is holding, paired with what is known about it.
/// Kept for the bind screen's summary line — never the secret.
typedef UnitMarkerSummary = ({String reference, UnitMarkerStatus status});

/// Maps a sub-order's `SubOrderState` int onto the stage the binding routes
/// reason about.
///
/// This mirrors `OrdersUnitMarkerOrderLineLookup.MapStage` on the backend,
/// value for value, so the app's explanation and the server's refusal agree.
/// It is only ever used to *explain* — the server still decides — and an
/// int this build does not know maps to
/// [OrderLineFulfilmentStage.unrecognised] rather than to something bindable.
OrderLineFulfilmentStage orderLineStageFromSubOrderState(int state) =>
    switch (state) {
      // With the buyer, or back from them: unit identity is no longer
      // observable, so binding and correction both close.
      7 || 9 => OrderLineFulfilmentStage.delivered,
      8 => OrderLineFulfilmentStage.cancelled,
      // Packed and still in the seller's hands. ReadyToShip is the legacy
      // path's Packed.
      4 || 13 => OrderLineFulfilmentStage.packed,
      // Gone to a courier and moving; still bindable, because a handover scan
      // is a person holding the parcel and the tag at the same moment.
      5 || 6 || 10 || 11 || 14 => OrderLineFulfilmentStage.handedOver,
      // Pending, Paid, AwaitingFulfillment, Accepted — nothing is packed yet.
      1 || 2 || 3 || 12 => OrderLineFulfilmentStage.awaitingPack,
      _ => OrderLineFulfilmentStage.unrecognised,
    };
