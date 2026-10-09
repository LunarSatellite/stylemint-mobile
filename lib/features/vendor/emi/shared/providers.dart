import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/data/datasources/vendor_emi_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/data/repositories/vendor_emi_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/repositories/vendor_emi_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/notifiers/vendor_emi_terms_notifier.dart';

final vendorEmiRemoteDataSourceProvider = Provider<VendorEmiRemoteDataSource>(
  (ref) => VendorEmiRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final vendorEmiRepositoryProvider = Provider<VendorEmiRepository>(
  (ref) => VendorEmiRepositoryImpl(
    remoteDataSource: ref.watch(vendorEmiRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// One listing's "Offer EMI" section, keyed by product id.
final vendorEmiTermsNotifierProvider = StateNotifierProvider.autoDispose
    .family<VendorEmiTermsNotifier, VendorEmiTermsState, String>((
      ref,
      productId,
    ) {
      final notifier = VendorEmiTermsNotifier(
        ref.watch(vendorEmiRepositoryProvider),
        productId,
      );
      unawaited(notifier.load());
      return notifier;
    });

/// The vendor's exposure limit and StyleMint's ceiling for it.
final FutureProvider<VendorEmiSettings> vendorEmiSettingsProvider =
    FutureProvider.autoDispose<VendorEmiSettings>((ref) async {
      final result = await ref.watch(vendorEmiRepositoryProvider).getSettings();
      return result.fold(
        (failure) => throw EmiLoadException(failure),
        (settings) => settings,
      );
    });

/// The vendor's listings with EMI switched on.
final FutureProvider<List<VendorEmiTerms>> vendorEmiProductsProvider =
    FutureProvider.autoDispose<List<VendorEmiTerms>>((ref) async {
      final result = await ref
          .watch(vendorEmiRepositoryProvider)
          .getEmiProducts();
      return result.fold(
        (failure) => throw EmiLoadException(failure),
        (products) => products,
      );
    });
