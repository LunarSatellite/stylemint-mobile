import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/handover_delegation_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/handover_delegation.dart';

/// The customer's half of delegated parcel handover
/// (`/v1/deliveries/{trackingNumber}/handover-delegations`).
///
/// Both mutations are `[Idempotent]` on the backend, so the caller owns the
/// `Idempotency-Key` and reuses the *same* key across retries of one attempt —
/// a retried "Authorise" tap must not mint a second code, and a retried
/// "Revoke" tap must not 409 against its own first success.
///
/// ## Code handling
///
/// [authorise] is the only method that can see a `verificationCode`. It
/// returns it inside [IssuedHandoverDelegation] and keeps no copy: there is
/// no field, no cache and no log line here that holds it. [list] cannot
/// recover it — the backend deliberately omits it — and this data source does
/// not pretend otherwise.
abstract class HandoverDelegationDataSource {
  /// Authorises one named person for this parcel. The returned code is shown
  /// once and never retrievable again.
  Future<IssuedHandoverDelegation> authorise({
    required String trackingNumber,
    required String delegateDisplayName,
    required String delegateContact,
    required DelegateRelationship relationship,
    required Set<DelegatedException> allowedExceptions,
    required DateTime windowStartUtc,
    required DateTime windowEndUtc,
    required String idempotencyKey,
  });

  /// The caller's delegations for this parcel. Never includes a code.
  Future<List<HandoverDelegation>> list(String trackingNumber);

  /// Withdraws an authorisation. Reaches a handover already in progress, not
  /// just the next attempt.
  Future<HandoverDelegation> revoke({
    required String trackingNumber,
    required String delegationId,
    required String idempotencyKey,
    String? reason,
  });
}

class HandoverDelegationRemoteDataSource
    implements HandoverDelegationDataSource {
  const HandoverDelegationRemoteDataSource({required ApiClient apiClient})
    : _api = apiClient;

  final ApiClient _api;

  static String _path(String trackingNumber) =>
      '/v1/deliveries/$trackingNumber/handover-delegations';

  @override
  Future<IssuedHandoverDelegation> authorise({
    required String trackingNumber,
    required String delegateDisplayName,
    required String delegateContact,
    required DelegateRelationship relationship,
    required Set<DelegatedException> allowedExceptions,
    required DateTime windowStartUtc,
    required DateTime windowEndUtc,
    required String idempotencyKey,
  }) async {
    // The code comes back in the response *body*. Nothing about this request
    // puts anything secret in the path or the query string, so it cannot
    // reach an access log, a Referer header or a browser history.
    final response = await _api.post(
      _path(trackingNumber),
      data: authoriseHandoverBody(
        delegateDisplayName: delegateDisplayName,
        delegateContact: delegateContact,
        relationship: relationship,
        allowedExceptions: allowedExceptions,
        windowStartUtc: windowStartUtc,
        windowEndUtc: windowEndUtc,
      ),
      options: Options(
        headers: <String, dynamic>{
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return parseIssuedHandoverDelegation(
      (response as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
    );
  }

  @override
  Future<List<HandoverDelegation>> list(String trackingNumber) async {
    final response = await _api.get(_path(trackingNumber));
    return (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (e) => HandoverDelegationDto.fromJson(
            e.cast<String, dynamic>(),
          ).toDomain(),
        )
        .toList(growable: false);
  }

  @override
  Future<HandoverDelegation> revoke({
    required String trackingNumber,
    required String delegationId,
    required String idempotencyKey,
    String? reason,
  }) async {
    final trimmed = reason?.trim() ?? '';
    final response = await _api.authDelete(
      '${_path(trackingNumber)}/$delegationId',
      data: <String, dynamic>{if (trimmed.isNotEmpty) 'reason': trimmed},
      options: Options(
        headers: <String, dynamic>{
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return HandoverDelegationDto.fromJson(
      (response as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
    ).toDomain();
  }
}
