import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundles_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';

final Provider<BundlesApi> bundlesApiProvider = Provider<BundlesApi>(
  (ref) => BundlesApiImpl(ref.watch(apiClientProvider)),
);

/// One bundle's page. No automatic retry: a bare 404 must read as "not
/// here" at once.
final FutureProviderFamily<BundleDetail, String> bundleDetailProvider =
    FutureProvider.autoDispose.family<BundleDetail, String>((
      ref,
      bundleId,
    ) async {
      final result = await ref.watch(bundlesApiProvider).getBundle(bundleId);
      return result.fold((f) => throw BundleLoadException(f), (b) => b);
    }, retry: (_, _) => null);

/// The Live bundles a shop takes part in, or a creator made or tagged.
final FutureProviderFamily<List<BundleCard>, BundleListKey>
bundleListProvider = FutureProvider.autoDispose
    .family<List<BundleCard>, BundleListKey>((ref, key) async {
      final result = await ref.watch(bundlesApiProvider).list(key);
      return result.fold((f) => throw BundleLoadException(f), (b) => b);
    }, retry: (_, _) => null);

/// The bundles tagged on one reel.
final FutureProviderFamily<List<ReelTaggedBundle>, String> reelBundlesProvider =
    FutureProvider.autoDispose.family<List<ReelTaggedBundle>, String>((
      ref,
      reelId,
    ) async {
      final result = await ref.watch(bundlesApiProvider).reelBundles(reelId);
      return result.fold((f) => throw BundleLoadException(f), (b) => b);
    }, retry: (_, _) => null);
