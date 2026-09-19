import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/regret_check.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/related_products_notifier.dart';

final discoveryRemoteDataSourceProvider = Provider<DiscoveryRemoteDataSource>(
  (ref) => DiscoveryRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => DiscoveryRepositoryImpl(
    remoteDataSource: ref.watch(discoveryRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final discoverNotifierProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>(
      (ref) => DiscoverNotifier(ref.watch(discoveryRepositoryProvider)),
    );

/// Category pages use the category landing API, not locally fabricated items.
final categoryProductsProvider = FutureProvider.autoDispose
    .family<List<TrendingProduct>, String>((ref, categoryId) async {
      final result = await ref
          .watch(discoveryRepositoryProvider)
          .getCategoryProducts(categoryId);
      return result.fold(
        (failure) => throw Exception(failure.toString()),
        (products) => products,
      );
    });

final productDetailNotifierProvider =
    StateNotifierProvider.family<
      ProductDetailNotifier,
      ProductDetailState,
      String
    >(
      (ref, productId) =>
          ProductDetailNotifier(ref.watch(discoveryRepositoryProvider)),
    );

/// Best-effort PDP stock / flash-sale / viewer signals. A failure here
/// should never block the product screen — callers read this via
/// `.asData?.value`, not by surfacing the error state. Every field on the
/// result is nullable and a null one draws nothing.
final productUrgencyProvider = FutureProvider.autoDispose
    .family<ProductUrgency?, String>((ref, productId) async {
      final result = await ref
          .watch(discoveryRepositoryProvider)
          .getProductUrgency(productId);
      return result.fold((_) => null, (urgency) => urgency);
    });

/// Best-effort measured social proof for one product (units sold in the last
/// 30 days, reviews, live viewers). Null when the call failed or the backend
/// recorded nothing for the product — either way, nothing is drawn.
final FutureProviderFamily<ProductSocialProof?, String>
productSocialProofProvider = FutureProvider.autoDispose
    .family<ProductSocialProof?, String>((ref, productId) async {
      final result = await ref
          .watch(discoveryRepositoryProvider)
          .getSocialProof([productId]);
      return result.fold((_) => null, (proof) => proof[productId]);
    });

/// Best-effort product FAQ ("Frequently Asked Questions" section). A
/// failure here should never block the product screen.
final productFaqProvider = FutureProvider.autoDispose
    .family<List<ProductFaqEntry>, String>((ref, productId) async {
      final result = await ref
          .watch(discoveryRepositoryProvider)
          .getProductFaq(productId);
      return result.fold((_) => const <ProductFaqEntry>[], (faq) => faq);
    });

/// Best-effort "which one should I buy" comparison card. A failure here
/// should never block the product screen.
/// Best-effort listing-provenance/authenticity card. A failure here should
/// never block the product screen.
final productPassportProvider = FutureProvider.autoDispose
    .family<ProductPassport?, String>((ref, productId) async {
      final result = await ref
          .watch(discoveryRepositoryProvider)
          .getProductPassport(productId);
      return result.fold((_) => null, (passport) => passport);
    });

final productComparisonProvider = FutureProvider.autoDispose
    .family<ProductComparison?, String>((ref, productId) async {
      final result = await ref
          .watch(discoveryRepositoryProvider)
          .getProductComparison(productId);
      return result.fold((_) => null, (comparison) => comparison);
    });

/// Best-effort "Check before you buy" card. Null (card hidden) on any
/// failure, or when the viewed product has no alternatives to weigh against.
final regretCheckProvider = FutureProvider.autoDispose
    .family<RegretCheck?, String>((ref, productId) async {
      try {
        final result = await ref
            .watch(discoveryRepositoryProvider)
            .getRegretCheck(productId);
        return result.fold(
          (_) => null,
          (check) => check.hasAlternatives ? check : null,
        );
      } on Object catch (_) {
        return null;
      }
    });

final relatedProductsProvider =
    StateNotifierProvider.family<
      RelatedProductsNotifier,
      RelatedProductsState,
      String
    >(
      (ref, productId) => RelatedProductsNotifier(
        ref.watch(discoveryRepositoryProvider),
        productId: productId,
      ),
    );

final customerSearchRemoteDataSourceProvider =
    Provider<CustomerSearchRemoteDataSource>(
      (ref) => CustomerSearchRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

/// Real search results for the given query, keyed so each distinct query
/// string gets its own cached fetch.
final customerSearchResultsProvider = FutureProvider.autoDispose
    .family<CustomerSearchResults, String>((ref, query) {
      return ref.watch(customerSearchRemoteDataSourceProvider).search(query);
    });

/// Hides the photo entry point unless the server has a genuine vision adapter.
final visualSearchCapabilityProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref
      .watch(customerSearchRemoteDataSourceProvider)
      .isVisualSearchAvailable();
});
