import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';

abstract class CreatorRepository {
  Future<Either<NetworkExceptions, CreatorApplication>> getApplicationStatus();
  Future<Either<NetworkExceptions, CreatorApplication>> submitApplication(
    CreatorApplicationForm form,
  );
  Future<Either<NetworkExceptions, String>> uploadIdentityDoc(String filePath);
}
