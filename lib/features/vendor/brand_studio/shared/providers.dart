import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/data/datasources/brand_studio_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/data/repositories/brand_studio_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/repositories/brand_studio_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/notifiers/brand_studio_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart'
    as partnerships;

final brandStudioRemoteDataSourceProvider =
    Provider<BrandStudioRemoteDataSource>(
      (ref) => BrandStudioRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final brandStudioRepositoryProvider = Provider<BrandStudioRepository>(
  (ref) => BrandStudioRepositoryImpl(
    remoteDataSource: ref.watch(brandStudioRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final brandStudioNotifierProvider =
    StateNotifierProvider<BrandStudioNotifier, BrandStudioState>(
      (ref) => BrandStudioNotifier(
        ref.watch(brandStudioRepositoryProvider),
      ),
    );

final vendorPartnershipsNotifierProvider =
    partnerships.vendorPartnershipsNotifierProvider;
