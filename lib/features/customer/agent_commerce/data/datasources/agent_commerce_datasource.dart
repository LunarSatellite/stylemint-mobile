import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/domain/entities/agent_mandate.dart';

/// The customer's half of `v1/agent-commerce/*` — every route here is called
/// with the customer's own JWT. The agent's half of the door
/// (`v1/agent-commerce/agent/*`) is somebody else's software and is never
/// called from this app.
///
/// All three mutations are `[Idempotent]` on the backend, so the caller owns
/// the `Idempotency-Key` and reuses the *same* key across retries of one
/// attempt: a retried "Issue" tap must not mint a second credential, and a
/// retried "Revoke" tap must not fail against its own first success.
///
/// ## Credential handling
///
/// [issueMandate] is the only method that can ever see a credential. It
/// returns it inside [IssuedAgentMandate] and keeps no copy — no field, no
/// cache, no log line here holds it. [listMandates] cannot recover it; the
/// backend stores only a SHA-256 hash and deliberately omits it from every
/// other response, and this data source does not pretend otherwise.
abstract class AgentCommerceDataSource {
  /// Issues a mandate. The returned credential is shown once and is never
  /// retrievable again.
  Future<IssuedAgentMandate> issueMandate({
    required String agentName,
    required AgentScopeSet scopes,
    required double maxOrderAmount,
    required String currency,
    required List<String> allowedProductIds,
    required DateTime expiresUtc,
    required String idempotencyKey,
  });

  /// The customer's mandates, newest first. Never includes a credential.
  Future<List<AgentMandate>> listMandates();

  /// Withdraws a mandate. Reaches work already running, not just the next
  /// request.
  Future<void> revokeMandate({
    required String mandateId,
    required String idempotencyKey,
  });

  /// Baskets agents have prepared, newest first.
  Future<List<AgentProposal>> listProposals();

  /// The human act the whole boundary rests on.
  Future<AgentProposal> confirmProposal({
    required String proposalId,
    required String idempotencyKey,
  });

  Future<AgentProposal> rejectProposal({
    required String proposalId,
    required String idempotencyKey,
  });

  /// Everything any agent asked for on this customer's behalf — allowed and
  /// refused alike.
  Future<List<AgentActivityEntry>> listActivity({int limit});
}

class AgentCommerceRemoteDataSource implements AgentCommerceDataSource {
  const AgentCommerceRemoteDataSource({required ApiClient apiClient})
    : _api = apiClient;

  final ApiClient _api;

  static const String _mandates = '/v1/agent-commerce/mandates';
  static const String _proposals = '/v1/agent-commerce/proposals';
  static const String _activity = '/v1/agent-commerce/activity';

  static Options _auth(String idempotencyKey) => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );

  @override
  Future<IssuedAgentMandate> issueMandate({
    required String agentName,
    required AgentScopeSet scopes,
    required double maxOrderAmount,
    required String currency,
    required List<String> allowedProductIds,
    required DateTime expiresUtc,
    required String idempotencyKey,
  }) async {
    // The credential comes back in the response *body*. Nothing about this
    // request puts anything secret in the path or the query string, so it
    // cannot reach an access log or a proxy trace.
    final response = await _api.post(
      _mandates,
      data: <String, dynamic>{
        'agentName': agentName.trim(),
        // Only scopes this build can name are ever requested.
        'scopes': scopes.bits,
        'maxOrderAmount': maxOrderAmount,
        'currency': currency.trim().toUpperCase(),
        'allowedProductIds': allowedProductIds,
        'expiresUtc': expiresUtc.toUtc().toIso8601String(),
      },
      options: _auth(idempotencyKey),
    );
    return parseIssuedAgentMandate(_asMap(response));
  }

  @override
  Future<List<AgentMandate>> listMandates() async {
    final response = await _api.get(_mandates);
    return _asList(response).map(parseAgentMandate).toList(growable: false);
  }

  @override
  Future<void> revokeMandate({
    required String mandateId,
    required String idempotencyKey,
  }) async {
    await _api.authDelete(
      '$_mandates/$mandateId',
      options: _auth(idempotencyKey),
    );
  }

  @override
  Future<List<AgentProposal>> listProposals() async {
    final response = await _api.get(_proposals);
    return _asList(response).map(parseAgentProposal).toList(growable: false);
  }

  @override
  Future<AgentProposal> confirmProposal({
    required String proposalId,
    required String idempotencyKey,
  }) async {
    final response = await _api.post(
      '$_proposals/$proposalId/confirm',
      options: _auth(idempotencyKey),
    );
    return parseAgentProposal(_asMap(response));
  }

  @override
  Future<AgentProposal> rejectProposal({
    required String proposalId,
    required String idempotencyKey,
  }) async {
    final response = await _api.post(
      '$_proposals/$proposalId/reject',
      options: _auth(idempotencyKey),
    );
    return parseAgentProposal(_asMap(response));
  }

  @override
  Future<List<AgentActivityEntry>> listActivity({int limit = 50}) async {
    // The only query parameter this feature ever sends, and it is a count.
    final response = await _api.get(
      _activity,
      queryParameters: <String, dynamic>{'limit': limit},
    );
    return _asList(
      response,
    ).map(parseAgentActivityEntry).toList(growable: false);
  }
}

// ── Parsing ───────────────────────────────────────────────────────────────

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

List<Map<String, dynamic>> _asList(dynamic value) =>
    (value is List ? value : const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);

String _string(dynamic v) => v is String ? v : (v?.toString() ?? '');

double _money(dynamic v) =>
    v is num ? v.toDouble() : (double.tryParse(_string(v)) ?? 0);

int _int(dynamic v, {int fallback = 0}) =>
    v is num ? v.toInt() : (int.tryParse(_string(v)) ?? fallback);

DateTime _utc(dynamic v) =>
    DateTime.tryParse(_string(v))?.toUtc() ?? DateTime.utc(1970);

DateTime? _utcOrNull(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(_string(v))?.toUtc();
}

/// Scopes arrive as a `[Flags]` bitmask number, but a server configured with
/// a string enum converter would send `"CatalogRead, CartWrite"`. Both are
/// read, and a name this build does not know still raises the bit through
/// [AgentScopeSet.unrecognisedBits] rather than vanishing.
int parseScopeBits(dynamic raw) {
  if (raw is num) return raw.toInt();
  final text = _string(raw).trim();
  if (text.isEmpty) return 0;
  final asNumber = int.tryParse(text);
  if (asNumber != null) return asNumber;
  var bits = 0;
  var sawUnknownName = false;
  for (final part in text.split(',')) {
    final name = part.trim().toLowerCase();
    if (name.isEmpty || name == 'none') continue;
    var matched = false;
    for (final scope in AgentMandateScope.values) {
      if (scope.name.toLowerCase() == name) {
        bits |= scope.bit;
        matched = true;
        break;
      }
    }
    if (!matched) sawUnknownName = true;
  }
  // An unnamed scope must not read as "not granted". Raise one bit above the
  // highest this build knows so the UI can say an unrecognised permission is
  // in force without inventing a name for it.
  if (sawUnknownName) bits |= 1 << 8;
  return bits;
}

AgentMandate parseAgentMandate(Map<String, dynamic> json) => AgentMandate(
  id: _string(json['id']),
  agentName: _string(json['agentName']),
  scopes: AgentScopeSet.fromBits(parseScopeBits(json['scopes'])),
  maxOrderAmount: _money(json['maxOrderAmount']),
  currency: _string(json['currency']).toUpperCase(),
  allowedProductIds:
      (json['allowedProductIds'] is List
              ? json['allowedProductIds'] as List
              : const <dynamic>[])
          .map(_string)
          .where((s) => s.isNotEmpty)
          .toList(growable: false),
  expiresUtc: _utc(json['expiresUtc']),
  createdUtc: _utc(json['createdUtc']),
  revokedUtc: _utcOrNull(json['revokedUtc']),
);

/// The one parse that yields a credential. It reads `agentToken` and hands it
/// straight back inside [IssuedAgentMandate]; it stores nothing.
IssuedAgentMandate parseIssuedAgentMandate(Map<String, dynamic> json) =>
    IssuedAgentMandate(
      mandate: parseAgentMandate(_asMap(json['mandate'])),
      credential: _string(json['agentToken']),
    );

AgentProposalLine parseAgentProposalLine(
  Map<String, dynamic> json,
  String fallbackCurrency,
) {
  final quantity = _int(json['quantity'], fallback: 1);
  final unit = _money(json['unitPriceAmount']);
  final subtotalRaw = json['lineSubtotalAmount'];
  return AgentProposalLine(
    productId: _string(json['productId']),
    title: _string(json['productTitleSnapshot']),
    quantity: quantity,
    unitPriceAmount: unit,
    lineSubtotalAmount: subtotalRaw == null
        ? unit * quantity
        : _money(subtotalRaw),
    currency:
        (_string(json['unitPriceCurrency']).isEmpty
                ? fallbackCurrency
                : _string(json['unitPriceCurrency']))
            .toUpperCase(),
    optionLabel:
        _blankToNull(json['optionLabel']) ??
        _blankToNull(json['variantLabelSnapshot']),
    sellerHandle: _blankToNull(json['creatorHandleSnapshot']),
  );
}

String? _blankToNull(dynamic v) {
  final text = _string(v).trim();
  return text.isEmpty ? null : text;
}

AgentProposal parseAgentProposal(Map<String, dynamic> json) {
  final currency = _string(json['currency']).toUpperCase();
  final rawStatus = json['status'];
  return AgentProposal(
    id: _string(json['id']),
    mandateId: _string(json['mandateId']),
    lines: _asList(
      json['items'],
    ).map((e) => parseAgentProposalLine(e, currency)).toList(growable: false),
    quotedTotal: _money(json['quotedTotal']),
    currency: currency,
    status: AgentProposalStatus.fromWire(parseProposalStatusWire(rawStatus)),
    rawStatus: parseProposalStatusWire(rawStatus),
    expiresUtc: _utc(json['expiresUtc']),
    createdUtc: _utc(json['createdUtc']),
  );
}

/// Accepts the numeric wire form and the string name, and returns `null` for
/// anything this build cannot place — which renders as "unrecognised", never
/// as "pending".
int? parseProposalStatusWire(dynamic raw) {
  if (raw is num) return raw.toInt();
  final text = _string(raw).trim();
  if (text.isEmpty) return null;
  final asNumber = int.tryParse(text);
  if (asNumber != null) return asNumber;
  for (final s in AgentProposalStatus.values) {
    if (s != AgentProposalStatus.unknown &&
        s.name.toLowerCase() == text.toLowerCase()) {
      return s.wire;
    }
  }
  return null;
}

AgentActivityEntry parseAgentActivityEntry(
  Map<String, dynamic> json,
) => AgentActivityEntry(
  id: _string(json['id']),
  agentName: _string(json['agentName']),
  action: _string(json['action']),
  // Absent reads as a refusal on purpose: the safe answer for a row we cannot
  // classify is "this did not go through", never "this was allowed".
  allowed: json['allowed'] == true,
  recordedUtc: _utc(json['recordedUtc']),
  mandateId: _blankToNull(json['mandateId']),
  errorCode: _blankToNull(json['errorCode']),
  detail: _blankToNull(json['detail']),
);
