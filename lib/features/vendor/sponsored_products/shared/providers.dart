import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/data/datasources/sponsored_products_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/data/repositories/sponsored_products_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/repositories/sponsored_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/presentation/notifiers/sponsored_products_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/presentation/notifiers/sponsored_products_notifier.dart';

final sponsoredProductsRemoteDataSourceProvider =
    Provider<SponsoredProductsRemoteDataSource>(
      (ref) => SponsoredProductsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final sponsoredProductsRepositoryProvider =
    Provider<SponsoredProductsRepository>(
      (ref) => SponsoredProductsRepositoryImpl(
        remoteDataSource: ref.watch(sponsoredProductsRemoteDataSourceProvider),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

/// autoDispose so reopening the screen fetches fresh figures.
final sponsoredProductsNotifierProvider =
    StateNotifierProvider.autoDispose<
      SponsoredProductsNotifier,
      SponsoredProductsState
    >(
      (ref) => SponsoredProductsNotifier(
        ref.watch(sponsoredProductsRepositoryProvider),
      ),
    );

/// Page size and page limit for the sponsor form's product picker.
const _pickerPageSize = 50;
const _pickerMaxPages = 10;

/// The vendor's live products for the sponsor form's picker, from the same
/// `GET /v1/vendor/products?state=2` call the Products screen uses. Failures
/// come back as a Left rather than a thrown error, so Riverpod never retries
/// on its own; the picker offers "Try again" instead.
final sponsorableProductsProvider =
    FutureProvider.autoDispose<
      Either<NetworkExceptions, List<SponsorProductTarget>>
    >((ref) async {
      final repository = ref.watch(vendorProductsRepositoryProvider);
      final products = <SponsorProductTarget>[];
      String? cursor;
      for (var page = 0; page < _pickerMaxPages; page++) {
        final result = await repository.getProducts(
          limit: _pickerPageSize,
          cursor: cursor,
          status: 'active',
        );
        if (result.isLeft()) {
          return left(
            result.getLeft().getOrElse(
              () => const NetworkExceptions.unexpectedError(),
            ),
          );
        }
        final paged = result.getRight().toNullable()!;
        products.addAll(
          paged.items
              .where(
                (p) =>
                    p.status == VendorProductStatus.active && p.id.isNotEmpty,
              )
              .map(
                (p) => SponsorProductTarget(
                  productId: p.id,
                  productName: p.name,
                ),
              ),
        );
        final next = paged.nextCursor;
        if (!paged.hasMore || next == null) break;
        cursor = next;
      }
      return right(products);
    });
