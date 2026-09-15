import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/datasources/codes_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/resolved_code.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/repositories/codes_repository.dart';
import 'package:uuid/uuid.dart';

class CodesRepositoryImpl implements CodesRepository {
  CodesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CodesRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, ResolvedCode>> resolve(
    String code,
    CodeScanVia via,
  ) => guardedNetworkCall(networkInfo, () async {
    final dto = await remoteDataSource.resolve(
      code: code,
      via: via,
      // A fresh key per open, so opening the code again counts again.
      idempotencyKey: _uuid.v4(),
    );
    return dto.toDomain(requestedCode: code);
  });

  @override
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> getMyProfileCode() =>
      guardedNetworkCall(
        networkInfo,
        () async => (await remoteDataSource.getMyProfileCode(
          idempotencyKey: _uuid.v4(),
        )).toDomain(),
      );

  @override
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> rotateMyProfileCode() =>
      guardedNetworkCall(
        networkInfo,
        () async => (await remoteDataSource.rotateMyProfileCode(
          idempotencyKey: _uuid.v4(),
        )).toDomain(),
      );
}
