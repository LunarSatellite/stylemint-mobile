import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/data/vendor_bundles_api.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/domain/vendor_bundle.dart';

final Provider<VendorBundlesApi> vendorBundlesApiProvider =
    Provider<VendorBundlesApi>(
      (ref) => VendorBundlesApiImpl(ref.watch(apiClientProvider)),
    );

/// Every bundle this shop is in or invited to. No automatic retry: a bare
/// 404 has to read as "being set up" at once.
final FutureProvider<List<VendorBundle>> vendorBundlesProvider =
    FutureProvider.autoDispose<List<VendorBundle>>((ref) async {
      final result = await ref.watch(vendorBundlesApiProvider).list();
      return result.fold((f) => throw BundleLoadException(f), (b) => b);
    }, retry: (_, _) => null);

/// One bundle, by id.
final FutureProviderFamily<VendorBundle, String> vendorBundleProvider =
    FutureProvider.autoDispose.family<VendorBundle, String>((
      ref,
      bundleId,
    ) async {
      final result = await ref.watch(vendorBundlesApiProvider).get(bundleId);
      return result.fold((f) => throw BundleLoadException(f), (b) => b);
    }, retry: (_, _) => null);
