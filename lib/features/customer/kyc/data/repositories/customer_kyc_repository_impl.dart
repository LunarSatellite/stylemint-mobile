import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/repositories/emi_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/data/datasources/customer_kyc_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/kyc_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/repositories/customer_kyc_repository.dart';
import 'package:uuid/uuid.dart';

class CustomerKycRepositoryImpl implements CustomerKycRepository {
  CustomerKycRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CustomerKycRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  /// The contract's per-file limit (jpeg/png/heic, ≤ 10 MB). Checked here so
  /// an oversized photo is named before anything is sent, rather than coming
  /// back as a bare 413 from the gateway.
  static const maxDocumentBytes = 10 * 1024 * 1024;

  @override
  Future<Either<EmiFailure, CustomerKyc>> getKyc() =>
      guardedEmiCall(networkInfo, remoteDataSource.getKyc);

  @override
  Future<Either<EmiFailure, CustomerKyc>> startSession() => guardedEmiCall(
    networkInfo,
    () => remoteDataSource.startSession(idempotencyKey: _uuid.v4()),
  );

  @override
  Future<Either<EmiFailure, CustomerKycDocument>> uploadDocument({
    required String sessionId,
    required KycDocumentKind kind,
    required File file,
  }) async {
    // A picked photo lives in the app's temp directory, which the OS may
    // reclaim — a buyer who picks, leaves and comes back can return to a path
    // with nothing behind it. Say so instead of failing inside Dio.
    if (!await file.exists()) {
      return left(
        EmiFailure.local(KycLocalCode.photoGone, missing: [kind.wire]),
      );
    }
    final length = await file.length();
    if (length == 0) {
      return left(
        EmiFailure.local(KycLocalCode.photoEmpty, missing: [kind.wire]),
      );
    }
    if (length > maxDocumentBytes) {
      return left(
        EmiFailure.local(KycLocalCode.photoTooLarge, missing: [kind.wire]),
      );
    }
    return guardedEmiCall(
      networkInfo,
      () => remoteDataSource.uploadDocument(
        sessionId: sessionId,
        kind: kind,
        file: file,
      ),
    );
  }

  @override
  Future<Either<EmiFailure, CustomerKyc>> submit({
    required String sessionId,
    required KycDetails details,
  }) => guardedEmiCall(
    networkInfo,
    () => remoteDataSource.submit(
      sessionId: sessionId,
      details: details,
      idempotencyKey: _uuid.v4(),
    ),
  );
}
