import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';

/// One page of client assignments plus the cursor to ask for the next.
class ClientAssignmentPage {
  const ClientAssignmentPage({required this.items, this.nextCursor});

  final List<ClientAssignment> items;
  final String? nextCursor;
}

/// The associate's half of clienteling — `v1/clienteling/associate/*`.
///
/// Every route acts FOR a named customer and never AS one. Authorisation is
/// data, not a role: the backend requires an active vendor team membership AND
/// a live per-customer assignment, so a caller with neither simply gets an
/// empty client book.
abstract interface class AssociateClientelingRepository {
  /// `GET /v1/clienteling/associate/clients`
  Future<Either<NetworkExceptions, ClientAssignmentPage>> listMyClients({
    String? cursor,
    int pageSize,
  });

  /// `GET /v1/clienteling/associate/clients/{customerAccountId}/brief`
  ///
  /// Reading this is itself recorded and is visible to the customer.
  Future<Either<NetworkExceptions, ClientBrief>> getBrief(
    String customerAccountId,
  );

  /// `POST /v1/clienteling/associate/sessions`
  Future<Either<NetworkExceptions, AssistSession>> openSession({
    required String customerAccountId,
    required String purpose,
    required String idempotencyKey,
  });

  /// `POST /v1/clienteling/associate/sessions/{sessionId}/close`
  Future<Either<NetworkExceptions, AssistSession>> closeSession({
    required String sessionId,
    required String idempotencyKey,
  });

  /// `POST /v1/clienteling/associate/outreach`
  ///
  /// Returns the platform's decision. A blocked request is a successful call
  /// with a blocked decision, not a failure.
  Future<Either<NetworkExceptions, OutreachAttempt>> sendOutreach({
    required String customerAccountId,
    required ClientelingOutreachChannel channel,
    required String subject,
    required String body,
    required String idempotencyKey,
    String? sessionId,
  });

  /// `POST /v1/clienteling/associate/outcomes`
  Future<Either<NetworkExceptions, AssistedOutcome>> claimOutcome({
    required String sessionId,
    required String orderId,
    required String idempotencyKey,
    String? note,
  });

  /// `GET /v1/clienteling/associate/activity`
  Future<Either<NetworkExceptions, List<ClientelingActivity>>> listMyActivity({
    String? customerAccountId,
    int limit,
  });
}

/// The customer's half — `v1/clienteling/me/*`. Requires the Customer role.
///
/// The customer is the only party who can turn an associate's claim into
/// credit; there is no timer and no vendor override.
abstract interface class CustomerClientelingRepository {
  /// `GET /v1/clienteling/me/history`
  Future<Either<NetworkExceptions, List<ClientelingActivity>>> listHistory({
    int limit,
  });

  /// `GET /v1/clienteling/me/assisted-outcomes`
  Future<Either<NetworkExceptions, List<AssistedOutcome>>> listClaims({
    int limit,
  });

  /// `POST /v1/clienteling/me/assisted-outcomes/{outcomeId}/confirm`
  Future<Either<NetworkExceptions, AssistedOutcome>> confirmOutcome({
    required String outcomeId,
    required String idempotencyKey,
  });

  /// `POST /v1/clienteling/me/assisted-outcomes/{outcomeId}/reject`
  Future<Either<NetworkExceptions, AssistedOutcome>> rejectOutcome({
    required String outcomeId,
    required String idempotencyKey,
  });
}
