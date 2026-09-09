import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/data/datasources/vendor_profile_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/data/repositories/vendor_profile_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/domain/entities/vendor_profile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/domain/repositories/vendor_profile_repository.dart';

final vendorProfileRemoteDataSourceProvider =
    Provider<VendorProfileRemoteDataSource>(
      (ref) => VendorProfileRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final vendorProfileRepositoryProvider = Provider<VendorProfileRepository>(
  (ref) => VendorProfileRepositoryImpl(
    remoteDataSource: ref.watch(vendorProfileRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final myVendorProfileProvider = FutureProvider.family<VendorProfile?, String>(
  (ref, accountId) async {
    if (accountId.isEmpty) return null;
    final result = await ref
        .read(vendorProfileRepositoryProvider)
        .getMyProfile(accountId);
    return result.fold((_) => null, (profile) => profile);
  },
);
