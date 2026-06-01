import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/vendor_dashboard.dart';

abstract class VendorDashboardRepository {
  Future<Either<NetworkExceptions, VendorDashboard>> getDashboard();
}
