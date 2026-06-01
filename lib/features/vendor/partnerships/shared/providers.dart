import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/data/datasources/vendor_partnerships_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/data/repositories/vendor_partnerships_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/repositories/vendor_partnerships_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';

final vendorPartnershipsRemoteDataSourceProvider =
    Provider<VendorPartnershipsRemoteDataSource>(
      (ref) => VendorPartnershipsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final vendorPartnershipsRepositoryProvider =
    Provider<VendorPartnershipsRepository>(
      (ref) => VendorPartnershipsRepositoryImpl(
        remoteDataSource: ref.watch(
          vendorPartnershipsRemoteDataSourceProvider,
        ),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

final vendorPartnershipsNotifierProvider =
    StateNotifierProvider<VendorPartnershipsNotifier, CampaignsState>(
      (ref) => VendorPartnershipsNotifier(
        ref.watch(vendorPartnershipsRepositoryProvider),
      ),
    );

final creatorSearchNotifierProvider =
    StateNotifierProvider<CreatorSearchNotifier, CreatorSearchState>(
      (ref) => CreatorSearchNotifier(
        ref.watch(vendorPartnershipsRepositoryProvider),
      ),
    );

final inviteCreatorNotifierProvider =
    StateNotifierProvider<InviteCreatorNotifier, InviteState>(
      (ref) => InviteCreatorNotifier(
        ref.watch(vendorPartnershipsRepositoryProvider),
      ),
    );
