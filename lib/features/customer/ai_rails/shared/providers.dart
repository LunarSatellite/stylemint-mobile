import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/data/datasources/ai_rails_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/data/repositories/ai_rails_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/entities/ai_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/repositories/ai_rails_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';

final aiRailsRemoteDataSourceProvider = Provider<AiRailsRemoteDataSource>((
  ref,
) {
  final reels = ref.watch(reelsRemoteDataSourceProvider);
  final discovery = ref.watch(discoveryRemoteDataSourceProvider);
  return AiRailsRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    readReel: reels.reelFromDetailJson,
    readProduct: discovery.relatedProductFromJson,
  );
});

final aiRailsRepositoryProvider = Provider<AiRailsRepository>(
  (ref) => AiRailsRepositoryImpl(
    remoteDataSource: ref.watch(aiRailsRemoteDataSourceProvider),
  ),
);

/// "Frequently bought together" for one product (contract v1.0 §3).
// The family's provider type is long and says nothing the right side doesn't.
// ignore: specify_nonobvious_property_types
final boughtTogetherProvider = FutureProvider.autoDispose
    .family<ProductRail, String>(
      (ref, productId) =>
          ref.watch(aiRailsRepositoryProvider).boughtTogether(productId),
    );

/// "People also viewed" for one product (contract v1.0 §3).
// ignore: specify_nonobvious_property_types
final alsoViewedProvider = FutureProvider.autoDispose
    .family<ProductRail, String>(
      (ref, productId) =>
          ref.watch(aiRailsRepositoryProvider).alsoViewed(productId),
    );

/// Reels featuring, then like, one product (contract v1.0 §4.2).
// ignore: specify_nonobvious_property_types
final productMatchedReelsProvider = FutureProvider.autoDispose
    .family<ReelMatches, String>(
      (ref, productId) =>
          ref.watch(aiRailsRepositoryProvider).reelsForProduct(productId),
    );
