import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/domain/entities/vendor_profile.dart';

abstract class VendorProfileRepository {
  Future<NetworkEither<VendorProfile>> getMyProfile(String accountId);
}
