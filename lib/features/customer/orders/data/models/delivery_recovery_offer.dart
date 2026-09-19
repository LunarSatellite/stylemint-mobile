/// Voyager "AI Delivery Guardian and Predictive Recovery" — the customer-side
/// projection of `DeliveryRecoveryOfferDto`.
///
/// The backend deliberately keeps the remedy set small and versions it by
/// adding new values, so everything here treats [DeliveryRemedyKind] as an
/// open set: an unrecognised wire value parses to
/// [DeliveryRemedyKind.unknown] while keeping the raw string, and the UI
/// falls back to the backend's own [DeliveryRecoveryOffer.description]
/// rather than throwing or rendering an empty card.
library;

/// What a remedy actually does. Open set — see the library doc.
enum DeliveryRemedyKind {
  /// Cancel the delayed sub-order and start the refund. Irreversible.
  cancelForRefund(1, 'CancelForRefund'),

  /// Open a support ticket about this delivery on the customer's behalf.
  prioritySupportReview(2, 'PrioritySupportReview'),

  /// A remedy this build does not know about. Never thrown for, never blank:
  /// the offer still renders from its backend-supplied description.
  unknown(0, 'Unknown');

  const DeliveryRemedyKind(this.code, this.wireName);

  final int code;
  final String wireName;

  /// Accepts either the string name (`"CancelForRefund"`, the host's default
  /// web policy) or the numeric enum value, case-insensitively.
  static DeliveryRemedyKind fromWire(Object? raw) {
    if (raw is num) {
      return DeliveryRemedyKind.values.firstWhere(
        (kind) => kind.code == raw.toInt(),
        orElse: () => DeliveryRemedyKind.unknown,
      );
    }
    if (raw is String) {
      final needle = raw.trim().toLowerCase();
      return DeliveryRemedyKind.values.firstWhere(
        (kind) => kind.wireName.toLowerCase() == needle,
        orElse: () => DeliveryRemedyKind.unknown,
      );
    }
    return DeliveryRemedyKind.unknown;
  }
}

/// Lifecycle of one offer. `Expired` covers "lifetime ran out", "the delivery
/// moved" and "a sibling remedy was accepted" — all three mean not acceptable.
enum DeliveryRecoveryOfferStatus {
  offered(1, 'Offered'),
  accepted(2, 'Accepted'),
  expired(3, 'Expired'),
  unknown(0, 'Unknown');

  const DeliveryRecoveryOfferStatus(this.code, this.wireName);

  final int code;
  final String wireName;

  static DeliveryRecoveryOfferStatus fromWire(Object? raw) {
    if (raw is num) {
      return DeliveryRecoveryOfferStatus.values.firstWhere(
        (status) => status.code == raw.toInt(),
        orElse: () => DeliveryRecoveryOfferStatus.unknown,
      );
    }
    if (raw is String) {
      final needle = raw.trim().toLowerCase();
      return DeliveryRecoveryOfferStatus.values.firstWhere(
        (status) => status.wireName.toLowerCase() == needle,
        orElse: () => DeliveryRecoveryOfferStatus.unknown,
      );
    }
    return DeliveryRecoveryOfferStatus.unknown;
  }
}

/// One remedy the platform can genuinely carry out for a slipping delivery.
class DeliveryRecoveryOffer {
  const DeliveryRecoveryOffer({
    required this.offerId,
    required this.trackingNumber,
    required this.remedy,
    required this.rawRemedy,
    required this.status,
    required this.riskReasonCode,
    required this.description,
    required this.requiresRefundWindowAcknowledgement,
    required this.offeredUtc,
    required this.expiresUtc,
    this.acceptedUtc,
    this.outcomeReference,
  });

  factory DeliveryRecoveryOffer.fromJson(Map<String, dynamic> json) {
    final offeredUtc = _parseUtc(json['offeredUtc']);
    return DeliveryRecoveryOffer(
      offerId: json['offerId']?.toString() ?? '',
      trackingNumber: json['trackingNumber'] as String? ?? '',
      remedy: DeliveryRemedyKind.fromWire(json['remedy']),
      rawRemedy: json['remedy']?.toString() ?? '',
      status: DeliveryRecoveryOfferStatus.fromWire(json['status']),
      riskReasonCode: json['riskReasonCode'] as String? ?? '',
      description: (json['description'] as String? ?? '').trim(),
      requiresRefundWindowAcknowledgement:
          json['requiresRefundWindowAcknowledgement'] as bool? ?? false,
      offeredUtc: offeredUtc,
      // A missing expiry must not read as "expired in 1970" — that would
      // hide a live offer. Fall back to the backend's 30-minute lifetime.
      expiresUtc:
          _tryParseUtc(json['expiresUtc']) ??
          offeredUtc.add(const Duration(minutes: 30)),
      acceptedUtc: _tryParseUtc(json['acceptedUtc']),
      outcomeReference: json['outcomeReference'] as String?,
    );
  }

  final String offerId;
  final String trackingNumber;

  /// Parsed kind; [DeliveryRemedyKind.unknown] for a value added after this
  /// build shipped.
  final DeliveryRemedyKind remedy;

  /// The wire value exactly as sent, kept so an unknown remedy can still be
  /// reported and debugged without guessing.
  final String rawRemedy;

  final DeliveryRecoveryOfferStatus status;
  final String riskReasonCode;

  /// The backend's own customer-facing sentence for this remedy. This is the
  /// text an unknown remedy kind renders.
  final String description;

  /// When true the customer must actively confirm they understand the
  /// refund window before this offer may be accepted. Never pre-set.
  final bool requiresRefundWindowAcknowledgement;

  final DateTime offeredUtc;
  final DateTime expiresUtc;
  final DateTime? acceptedUtc;
  final String? outcomeReference;

  bool get isOffered => status == DeliveryRecoveryOfferStatus.offered;

  /// True once the 30-minute window has passed at [nowUtc].
  bool hasLapsedAt(DateTime nowUtc) =>
      !nowUtc.toUtc().isBefore(expiresUtc.toUtc());

  /// The only condition under which a control for this offer may be tapped.
  bool isActionableAt(DateTime nowUtc) => isOffered && !hasLapsedAt(nowUtc);

  Duration remainingAt(DateTime nowUtc) {
    final left = expiresUtc.toUtc().difference(nowUtc.toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  static DateTime _parseUtc(Object? raw) =>
      _tryParseUtc(raw) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static DateTime? _tryParseUtc(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}
