import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/datasources/reel_bundle_tags_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';

final Provider<ReelBundleTagsApi> reelBundleTagsApiProvider =
    Provider<ReelBundleTagsApi>(
      (ref) => ReelBundleTagsApiImpl(ref.watch(apiClientProvider)),
    );

/// The creator's Live bundles, for "Tag a bundle". An error (a bare 404
/// before the backend has bundles) hides the option.
final FutureProvider<List<BundleCard>> creatorTaggableBundlesProvider =
    FutureProvider.autoDispose<List<BundleCard>>((ref) async {
      final result = await ref.watch(reelBundleTagsApiProvider).myLiveBundles();
      return result.fold((f) => throw BundleLoadException(f), (b) => b);
    }, retry: (_, _) => null);
