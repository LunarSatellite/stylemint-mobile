import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';

abstract interface class BrandStudioRepository {
  Future<Either<NetworkExceptions, BrandStudioInsights>> getInsights({
    int? windowDays,
  });
}
