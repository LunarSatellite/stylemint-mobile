import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/entities/creator_performance.dart';

abstract class CreatorPerformanceRepository {
  Future<Either<NetworkExceptions, List<CreatorPerformance>>>
  getCreatorPerformance({int? windowDays, int limit = 50});
}
