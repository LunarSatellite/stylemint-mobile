import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/datasources/creator_documents_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/identity_document.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_documents_repository.dart';
import 'package:uuid/uuid.dart';

class CreatorDocumentsRepositoryImpl implements CreatorDocumentsRepository {
  CreatorDocumentsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorDocumentsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<NetworkEither<IdentityDocument>> uploadIdentityDocument({
    required File file,
    required IdentityDocumentType type,
    IdentityDocumentSide side = IdentityDocumentSide.notApplicable,
  }) =>
      _guard(() async {
        final session = await _ensureSession();
        final blob = await remoteDataSource.uploadBlob(file);
        return remoteDataSource.registerDocument(
          sessionId: session.id,
          type: type,
          side: side,
          blob: blob,
          idempotencyKey: const Uuid().v4(),
        );
      });

  @override
  Future<NetworkEither<List<IdentityDocument>>> listSubmittedDocuments() =>
      _guard(() async {
        final session = await remoteDataSource.getActiveSession();
        if (session == null) return const <IdentityDocument>[];
        return remoteDataSource.listBySession(session.id);
      });

  @override
  Future<NetworkEither<Unit>> submitForReview() => _guard(() async {
        final session = await remoteDataSource.getActiveSession();
        if (session == null) {
          throw const NetworkExceptions.validation(
            code: 'Upload a document before submitting for review.',
          );
        }
        await remoteDataSource.submitSession(session.id, const Uuid().v4());
        return unit;
      });

  /// Reuses the open session so a creator uploading a front and a back does
  /// not end up with two sessions holding one document each.
  Future<KycSession> _ensureSession() async {
    final existing = await remoteDataSource.getActiveSession();
    if (existing != null) return existing;
    return remoteDataSource.startSession(idempotencyKey: const Uuid().v4());
  }

  Future<NetworkEither<T>> _guard<T>(Future<T> Function() call) async {
    if (!await networkInfo.isConnected) {
      return networkLeft<T>(const NetworkExceptions.noInternetConnection());
    }
    try {
      return networkRight<T>(await call());
    } on DioException catch (e) {
      return networkLeft<T>(
        NetworkExceptions.server(e.message ?? 'Server error'),
      );
    } on NetworkExceptions catch (e) {
      return networkLeft<T>(e);
    } on Exception {
      return networkLeft<T>(const NetworkExceptions.unexpectedError());
    }
  }
}
