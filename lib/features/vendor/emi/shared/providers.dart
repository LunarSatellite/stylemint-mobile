import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/data/datasources/vendor_emi_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/data/repositories/vendor_emi_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi_plan.dart';
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

/// Today on the Kathmandu calendar — what "due soon" and "overdue" are
/// judged against. A provider so tests can fix the date.
final Provider<DateTime> vendorEmiTodayProvider = Provider<DateTime>(
  (ref) => kathmanduToday(),
);

/// The seller's EMI plans after approval (`v1/credit/vendor/plans`). A 404
/// (not deployed yet) arrives as an [EmiLoadException] whose failure
/// `isNotFound`; screens then say the feature is being set up.
final FutureProvider<List<VendorEmiPlan>> vendorEmiPlansProvider =
    FutureProvider.autoDispose<List<VendorEmiPlan>>((ref) async {
      final result = await ref.watch(vendorEmiRepositoryProvider).getPlans();
      return result.fold(
        (failure) => throw EmiLoadException(failure),
        (plans) => plans,
      );
    });

/// One of the seller's EMI plans, by agreement id.
final FutureProviderFamily<VendorEmiPlan, String> vendorEmiPlanProvider =
    FutureProvider.autoDispose.family<VendorEmiPlan, String>((
      ref,
      agreementId,
    ) async {
      final result = await ref
          .watch(vendorEmiRepositoryProvider)
          .getPlan(agreementId);
      return result.fold(
        (failure) => throw EmiLoadException(failure),
        (plan) => plan,
      );
    });
