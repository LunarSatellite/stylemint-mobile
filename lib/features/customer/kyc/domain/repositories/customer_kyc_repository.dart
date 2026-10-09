import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';

abstract class CustomerKycRepository {
  Future<Either<EmiFailure, CustomerKyc>> getKyc();

  Future<Either<EmiFailure, CustomerKyc>> startSession();

  Future<Either<EmiFailure, CustomerKycDocument>> uploadDocument({
    required String sessionId,
    required KycDocumentKind kind,
    required File file,
  });

  Future<Either<EmiFailure, CustomerKyc>> submit({
    required String sessionId,
    required KycDetails details,
  });
}
