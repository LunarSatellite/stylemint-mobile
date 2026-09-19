/// The customer's side of external-agent commerce.
///
/// An *external agent* is somebody else's software — an AI shopping assistant
/// the customer uses elsewhere — acting inside a **mandate** this customer
/// issued. The mandate is the whole of the agent's authority: scopes, a spend
/// cap, one currency, an optional product allowlist and an expiry of at most
/// [kAgentMandateMaxLifetimeDays] days. Revoking it stops work already in
/// flight, not merely the next request.
///
/// ## The credential
///
/// [IssuedAgentMandate.credential] is the only field in this file that carries
/// the secret, it exists only on the value returned by creation, and it is
/// **never** persisted, logged, copied to the clipboard or put in a route.
/// [AgentMandate] deliberately has no credential field at all, so nothing that
/// outlives the issuing sheet can hold one. `agent_commerce_secrecy_test.dart`
/// fails the build if that changes.
library;

/// One capability a mandate may grant. The wire form is a `[Flags]` bitmask.
enum AgentMandateScope {
  /// Read the published catalogue and product manifests.
  catalogRead(1),

  /// Add lines to this customer's basket, within the allowed products.
  cartWrite(2),

  /// Prepare a checkout and raise a proposal. Places no order.
  checkoutPrepare(4),

  /// Submit an order the customer has **already** confirmed. It does not
  /// permit submitting an unconfirmed one — no scope does.
  orderSubmitAfterCustomerConfirmation(8);

  const AgentMandateScope(this.bit);

  /// The bit this scope occupies in the wire bitmask.
  final int bit;
}

/// A set of scopes, plus whatever bits this build does not recognise.
///
/// A future backend may add a scope before this app knows its name. Dropping
/// the bit would show the customer a mandate that grants less than it does, so
/// unknown bits are kept, counted and shown as "unrecognised" rather than
/// silently discarded. They are also never re-sent on creation: this app only
/// ever asks for permissions it can name.
class AgentScopeSet {
  const AgentScopeSet(this.granted, {this.unrecognisedBits = 0});

  factory AgentScopeSet.fromBits(int bits) {
    final granted = <AgentMandateScope>{};
    var leftover = bits;
    for (final scope in AgentMandateScope.values) {
      if (bits & scope.bit == scope.bit) {
        granted.add(scope);
        leftover &= ~scope.bit;
      }
    }
    return AgentScopeSet(
      granted,
      unrecognisedBits: leftover < 0 ? 0 : leftover,
    );
  }

  /// Empty — grants nothing.
  static const AgentScopeSet none = AgentScopeSet(<AgentMandateScope>{});

  final Set<AgentMandateScope> granted;

  /// Bits set on the wire that this build has no name for.
  final int unrecognisedBits;

  bool get hasUnrecognised => unrecognisedBits != 0;

  bool get isEmpty => granted.isEmpty && unrecognisedBits == 0;

  bool has(AgentMandateScope scope) => granted.contains(scope);

  /// How many unnamed permissions are set, for an honest count in the UI.
  int get unrecognisedCount =>
      unrecognisedBits.toRadixString(2).split('').where((c) => c == '1').length;

  /// Only the named scopes. Never includes [unrecognisedBits].
  int get bits => granted.fold(0, (sum, s) => sum | s.bit);
}

/// Where a mandate stands right now, without colour doing the work.
enum AgentMandateState { active, revoked, expired }

/// A mandate as the customer's own list returns it. **No credential field.**
class AgentMandate {
  const AgentMandate({
    required this.id,
    required this.agentName,
    required this.scopes,
    required this.maxOrderAmount,
    required this.currency,
    required this.allowedProductIds,
    required this.expiresUtc,
    required this.createdUtc,
    this.revokedUtc,
  });

  final String id;
  final String agentName;
  final AgentScopeSet scopes;
  final double maxOrderAmount;
  final String currency;

  /// Empty means "any published product". The backend reads it the same way.
  final List<String> allowedProductIds;
  final DateTime expiresUtc;
  final DateTime createdUtc;
  final DateTime? revokedUtc;

  bool get isProductLimited => allowedProductIds.isNotEmpty;

  AgentMandateState effectiveStateAt(DateTime nowUtc) {
    if (revokedUtc != null) return AgentMandateState.revoked;
    if (!expiresUtc.isAfter(nowUtc)) return AgentMandateState.expired;
    return AgentMandateState.active;
  }
}

/// The result of creating a mandate: the mandate, and the credential **once**.
///
/// This is the single type in the app that may name a credential. It is built
/// in the data source, handed straight to the issuing sheet's `State`, and
/// dropped when that sheet closes. It is never put in a provider, a cache, a
/// repository or a route argument.
class IssuedAgentMandate {
  const IssuedAgentMandate({required this.mandate, required this.credential});

  final AgentMandate mandate;

  /// Shown once, at large size, and then gone from the process. StyleMint
  /// keeps only its hash, so nothing can show it again.
  final String credential;
}

/// A basket an agent prepared and parked at the human approval boundary.
enum AgentProposalStatus {
  pendingCustomerConfirmation(1),
  confirmed(2),
  rejected(3),
  executed(4),
  expired(5),

  /// A status this build does not recognise. Rendered plainly and never
  /// treated as actionable — guessing would be worse than saying so.
  unknown(-1);

  const AgentProposalStatus(this.wire);

  final int wire;

  static AgentProposalStatus fromWire(int? value) {
    for (final s in AgentProposalStatus.values) {
      if (s != AgentProposalStatus.unknown && s.wire == value) return s;
    }
    return AgentProposalStatus.unknown;
  }

  /// Only a pending proposal can be confirmed or rejected. An unknown status
  /// is deliberately not actionable.
  bool get awaitsCustomer =>
      this == AgentProposalStatus.pendingCustomerConfirmation;
}

/// One line of a proposed basket.
///
/// Carries **no image field**. Product photographs belong on product detail
/// and nowhere else (owner directive, 2026-09-16), and this screen is a
/// consent surface, not a shop window: what the customer needs here is the
/// title, the variant, the quantity and the money.
class AgentProposalLine {
  const AgentProposalLine({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.unitPriceAmount,
    required this.lineSubtotalAmount,
    required this.currency,
    this.optionLabel,
    this.sellerHandle,
  });

  final String productId;
  final String title;
  final int quantity;
  final double unitPriceAmount;
  final double lineSubtotalAmount;
  final String currency;

  /// "M / Emerald", or the SKU when the product has no options.
  final String? optionLabel;

  /// Who it is being bought from, where the line names them.
  final String? sellerHandle;
}

class AgentProposal {
  const AgentProposal({
    required this.id,
    required this.mandateId,
    required this.lines,
    required this.quotedTotal,
    required this.currency,
    required this.status,
    required this.expiresUtc,
    required this.createdUtc,
    this.rawStatus,
  });

  final String id;
  final String mandateId;
  final List<AgentProposalLine> lines;
  final double quotedTotal;
  final String currency;
  final AgentProposalStatus status;

  /// The wire value, kept so an unrecognised status can be reported exactly.
  final int? rawStatus;
  final DateTime expiresUtc;
  final DateTime createdUtc;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  bool expiredAt(DateTime nowUtc) => !expiresUtc.isAfter(nowUtc);

  /// A proposal the customer can still act on. An expired one is shown, but
  /// its buttons are gone.
  bool actionableAt(DateTime nowUtc) =>
      status.awaitsCustomer && !expiredAt(nowUtc);
}

/// One thing an agent asked for, and what happened — including refusals.
///
/// A refusal is not an error to be swallowed. It is the evidence that the
/// limits the customer set are doing something, so it is a first-class row.
class AgentActivityEntry {
  const AgentActivityEntry({
    required this.id,
    required this.agentName,
    required this.action,
    required this.allowed,
    required this.recordedUtc,
    this.mandateId,
    this.errorCode,
    this.detail,
  });

  final String id;
  final String agentName;

  /// Dotted wire verb, e.g. `cart.add` or `proposal.execute`.
  final String action;

  /// False for a refusal. Refusals are never filtered out of the feed.
  final bool allowed;
  final DateTime recordedUtc;
  final String? mandateId;
  final String? errorCode;
  final String? detail;
}

/// One product the customer can put on a mandate's allowlist.
///
/// Carries a title and a line of supporting text and **no image**: this is a
/// consent list, and the product-photo directive keeps photographs on product
/// detail. Where these come from is the caller's business — today the
/// customer's own saved items, which is the only set of products the app can
/// name without sending them browsing mid-consent.
class AgentAllowlistCandidate {
  const AgentAllowlistCandidate({
    required this.productId,
    required this.title,
    this.subtitle,
  });

  final String productId;
  final String title;
  final String? subtitle;
}

// ── Limits the backend enforces, checked here so the customer sees them ────

/// `AgentPurchaseMandate.MaxLifetimeDays`.
const int kAgentMandateMaxLifetimeDays = 90;

/// `AgentPurchaseMandate.MaxAgentNameLength`.
const int kAgentMandateMaxNameLength = 120;

/// The largest spend cap the backend will accept.
const double kAgentMandateMaxOrderAmount = 100000000;

/// A mandate may allow at most this many specific products.
const int kAgentMandateMaxAllowedProducts = 500;

enum MandateExpiryProblem { notInFuture, beyondMaxLifetime }

/// The 90-day ceiling, refused here rather than at the server so the customer
/// reads a sentence instead of a rejected request.
MandateExpiryProblem? validateMandateExpiry({
  required DateTime expiresUtc,
  required DateTime nowUtc,
}) {
  if (!expiresUtc.isAfter(nowUtc)) return MandateExpiryProblem.notInFuture;
  if (expiresUtc.isAfter(
    nowUtc.add(const Duration(days: kAgentMandateMaxLifetimeDays)),
  )) {
    return MandateExpiryProblem.beyondMaxLifetime;
  }
  return null;
}

enum MandateCapProblem { missing, notANumber, notPositive, aboveCeiling }

MandateCapProblem? validateMandateCap(String raw) {
  final text = raw.trim().replaceAll(',', '');
  if (text.isEmpty) return MandateCapProblem.missing;
  final value = double.tryParse(text);
  if (value == null) return MandateCapProblem.notANumber;
  if (value <= 0) return MandateCapProblem.notPositive;
  if (value > kAgentMandateMaxOrderAmount) {
    return MandateCapProblem.aboveCeiling;
  }
  return null;
}

enum MandateCurrencyProblem { wrongLength, notLetters }

MandateCurrencyProblem? validateMandateCurrency(String raw) {
  final code = raw.trim();
  if (code.length != 3) return MandateCurrencyProblem.wrongLength;
  if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(code)) {
    return MandateCurrencyProblem.notLetters;
  }
  return null;
}
