import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/data/datasources/clienteling_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/repositories/clienteling_repository.dart';

class AssociateClientelingRepositoryImpl
    implements AssociateClientelingRepository {
  AssociateClientelingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ClientelingRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, ClientAssignmentPage>> listMyClients({
    String? cursor,
    int pageSize = 20,
  }) => guardedNetworkCall(networkInfo, () async {
    final page = await remoteDataSource.listMyClients(
      cursor: cursor,
      pageSize: pageSize,
    );
    return ClientAssignmentPage(
      items: page.items,
      nextCursor: page.nextCursor,
    );
  });

  @override
  Future<Either<NetworkExceptions, ClientBrief>> getBrief(
    String customerAccountId,
  ) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.getBrief(customerAccountId),
  );

  @override
  Future<Either<NetworkExceptions, AssistSession>> openSession({
    required String customerAccountId,
    required String purpose,
    required String idempotencyKey,
  }) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.openSession(
      customerAccountId: customerAccountId,
      purpose: purpose,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Either<NetworkExceptions, AssistSession>> closeSession({
    required String sessionId,
    required String idempotencyKey,
  }) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.closeSession(
      sessionId: sessionId,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Either<NetworkExceptions, OutreachAttempt>> sendOutreach({
    required String customerAccountId,
    required ClientelingOutreachChannel channel,
    required String subject,
    required String body,
    required String idempotencyKey,
    String? sessionId,
  }) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.sendOutreach(
      customerAccountId: customerAccountId,
      channel: channel,
      subject: subject,
      body: body,
      idempotencyKey: idempotencyKey,
      sessionId: sessionId,
    ),
  );

  @override
  Future<Either<NetworkExceptions, AssistedOutcome>> claimOutcome({
    required String sessionId,
    required String orderId,
    required String idempotencyKey,
    String? note,
  }) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.claimOutcome(
      sessionId: sessionId,
      orderId: orderId,
      idempotencyKey: idempotencyKey,
      note: note,
    ),
  );

  @override
  Future<Either<NetworkExceptions, List<ClientelingActivity>>> listMyActivity({
    String? customerAccountId,
    int limit = 50,
  }) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.listMyActivity(
      customerAccountId: customerAccountId,
      limit: limit,
    ),
  );
}

class CustomerClientelingRepositoryImpl
    implements CustomerClientelingRepository {
  CustomerClientelingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ClientelingRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<ClientelingActivity>>> listHistory({
    int limit = 50,
  }) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.listMyHistory(limit: limit),
  );

  @override
  Future<Either<NetworkExceptions, List<AssistedOutcome>>> listClaims({
    int limit = 50,
  }) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.listMyClaims(limit: limit),
  );

  @override
  Future<Either<NetworkExceptions, AssistedOutcome>> confirmOutcome({
    required String outcomeId,
    required String idempotencyKey,
  }) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.confirmOutcome(
      outcomeId: outcomeId,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Either<NetworkExceptions, AssistedOutcome>> rejectOutcome({
    required String outcomeId,
    required String idempotencyKey,
  }) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.rejectOutcome(
      outcomeId: outcomeId,
      idempotencyKey: idempotencyKey,
    ),
  );
}
