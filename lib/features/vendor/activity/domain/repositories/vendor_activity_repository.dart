import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/domain/entities/vendor_activity_entry.dart';

abstract interface class VendorActivityRepository {
  Future<Either<NetworkExceptions, List<VendorActivityEntry>>> getActivity({
    int pageSize,
    String? cursor,
  });
}
