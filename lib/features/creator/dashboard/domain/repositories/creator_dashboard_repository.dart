import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';

abstract class CreatorDashboardRepository {
  Future<Either<NetworkExceptions, CreatorDashboard>> getDashboard();
}
