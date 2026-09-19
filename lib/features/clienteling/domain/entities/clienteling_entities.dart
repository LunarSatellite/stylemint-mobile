/// Domain entities for the clienteling capability — `v1/clienteling/*` and
/// `v1/vendor/clienteling/*`.
///
/// Pure Dart: no Flutter, no Dio. Every field here exists on the wire. Nothing
/// is derived, defaulted or filled in: a value the backend does not send is
/// `null` and the UI renders it as absent.
library;

/// Lifecycle of a vendor's grant of permission for one associate to serve one
/// named customer. `unknown` is a wire value this build does not recognise —
/// it is never treated as active.
enum ClientAssignmentStatus { active, revoked, unknown }

/// What an associate did. Every row carries both identities.
enum ClientelingActivityType {
  briefViewed,
  sessionOpened,
  sessionClosed,
  outreachAttempted,
  outcomeClaimed,
  outcomeConfirmed,
  outcomeRejected,
  accessRefused,
  unknown,
}

/// Channels an associate may ask the platform to reach a customer on.
enum ClientelingOutreachChannel { email, sms, unknown }

/// What the platform did with an outreach request. A blocked attempt is stored
/// exactly like a sent one, so the UI shows blocked attempts rather than
/// hiding them.
enum ClientelingOutreachDecision {
  sent,
  blockedNoConsent,
  blockedQuietHours,
  blockedNoContactPoint,
  blockedNotPermitted,
  dispatchFailed,
  unknown,
}

/// Attribution state of an assisted outcome. `claimed` is an unverified
/// assertion by the associate and is NEVER credit; only `confirmed` — which
/// requires a recorded confirmation by the customer account itself — is.
enum AssistedOutcomeStatus { claimed, confirmed, rejected, unknown }

/// One customer an associate is permitted to serve.
class ClientAssignment {
  const ClientAssignment({
    required this.assignmentId,
    required this.vendorAccountId,
    required this.associateAccountId,
    required this.customerAccountId,
    required this.status,
    required this.grantedUtc,
    this.customerDisplayName,
    this.customerHandle,
    this.note,
    this.revokedUtc,
  });

  final String assignmentId;
  final String vendorAccountId;
  final String associateAccountId;
  final String customerAccountId;

  /// Null when the backend sent no name. Never substituted.
  final String? customerDisplayName;

  /// Null when the customer has no handle.
  final String? customerHandle;

  final ClientAssignmentStatus status;
  final String? note;

  /// Null when the backend sent no usable timestamp.
  final DateTime? grantedUtc;
  final DateTime? revokedUtc;
}

/// Whether the platform would carry a message on this channel right now — and
/// nothing about where it would go. The associate never receives the
/// customer's email address or phone number.
class Contactability {
  const Contactability({
    required this.channel,
    required this.allowed,
    required this.decision,
    this.reason,
  });

  final ClientelingOutreachChannel channel;
  final bool allowed;
  final ClientelingOutreachDecision decision;

  /// The backend's own words for why. Null when it sent none.
  final String? reason;
}

/// One order of this customer that this vendor is part of. Status and shape
/// only: the backend sends no money, no addresses and no per-line detail, so
/// there is none to show.
class ClientOrderSummary {
  const ClientOrderSummary({
    required this.orderId,
    this.orderNumber,
    this.vendorSubOrderStatus,
    this.placedUtc,
    this.itemCount,
  });

  final String orderId;
  final String? orderNumber;
  final String? vendorSubOrderStatus;
  final DateTime? placedUtc;

  /// Null when the backend did not send a count. Not defaulted to zero.
  final int? itemCount;
}

/// The whole of what an associate is told about a customer.
class ClientBrief {
  const ClientBrief({
    required this.assignmentId,
    required this.vendorAccountId,
    required this.associateAccountId,
    required this.customerAccountId,
    required this.customerAccountActive,
    required this.contactability,
    required this.recentOrdersWithThisVendor,
    required this.withheld,
    this.customerDisplayName,
    this.customerHandle,
  });

  final String assignmentId;
  final String vendorAccountId;
  final String associateAccountId;
  final String customerAccountId;
  final String? customerDisplayName;
  final String? customerHandle;
  final bool customerAccountActive;
  final List<Contactability> contactability;
  final List<ClientOrderSummary> recentOrdersWithThisVendor;

  /// What the platform is deliberately holding back, in its own words. Part of
  /// the contract, not decoration — it makes the absence legible.
  final List<String> withheld;
}

/// A period of serving one customer.
class AssistSession {
  const AssistSession({
    required this.sessionId,
    required this.assignmentId,
    required this.vendorAccountId,
    required this.associateAccountId,
    required this.customerAccountId,
    required this.isOpen,
    this.purpose,
    this.openedUtc,
    this.closedUtc,
  });

  final String sessionId;
  final String assignmentId;
  final String vendorAccountId;
  final String associateAccountId;
  final String customerAccountId;
  final String? purpose;
  final DateTime? openedUtc;
  final DateTime? closedUtc;
  final bool isOpen;
}

/// One request to carry a message to a customer, sent or blocked.
class OutreachAttempt {
  const OutreachAttempt({
    required this.outreachId,
    required this.customerAccountId,
    required this.channel,
    required this.decision,
    required this.sent,
    this.sessionId,
    this.subject,
    this.decisionReason,
    this.requestedUtc,
  });

  final String outreachId;
  final String customerAccountId;
  final String? sessionId;
  final ClientelingOutreachChannel channel;
  final ClientelingOutreachDecision decision;
  final bool sent;
  final String? subject;
  final String? decisionReason;
  final DateTime? requestedUtc;
}

/// An associate's claim to have assisted one order, and the customer's answer.
class AssistedOutcome {
  const AssistedOutcome({
    required this.outcomeId,
    required this.sessionId,
    required this.vendorAccountId,
    required this.associateAccountId,
    required this.customerAccountId,
    required this.orderId,
    required this.status,
    required this.isCredited,
    this.orderNumber,
    this.orderPlacedUtc,
    this.note,
    this.claimedUtc,
    this.confirmedByAccountId,
    this.decidedUtc,
  });

  final String outcomeId;
  final String sessionId;
  final String vendorAccountId;
  final String associateAccountId;
  final String customerAccountId;
  final String orderId;
  final String? orderNumber;
  final DateTime? orderPlacedUtc;
  final AssistedOutcomeStatus status;
  final String? note;
  final DateTime? claimedUtc;
  final String? confirmedByAccountId;
  final DateTime? decidedUtc;

  /// True only when the customer confirmed. The credit predicate.
  final bool isCredited;

  /// Whether the customer still has to answer this claim.
  bool get awaitsCustomerAnswer => status == AssistedOutcomeStatus.claimed;
}

/// One recorded clienteling action, visible to both the associate who took it
/// and the customer it was taken on.
class ClientelingActivity {
  const ClientelingActivity({
    required this.activityId,
    required this.associateAccountId,
    required this.customerAccountId,
    required this.type,
    this.vendorAccountId,
    this.sessionId,
    this.detail,
    this.subjectId,
    this.occurredUtc,
  });

  final String activityId;
  final String? vendorAccountId;
  final String associateAccountId;
  final String customerAccountId;
  final String? sessionId;
  final ClientelingActivityType type;
  final String? detail;
  final String? subjectId;
  final DateTime? occurredUtc;
}
