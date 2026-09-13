import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';

abstract class SponsoredProductsRepository {
  /// Every sponsorship the signed-in vendor has, with fresh figures.
  Future<Either<NetworkExceptions, List<SponsoredListing>>>
  getSponsoredListings();

  /// Starts sponsoring a live product, or changes and restarts its
  /// sponsorship. Sends a fresh Idempotency-Key per call.
  Future<Either<NetworkExceptions, SponsoredListing>> sponsor({
    required String productId,
    required int dailyImpressionCap,
    DateTime? endsUtc,
  });

  /// Stops a sponsorship without losing its history.
  Future<Either<NetworkExceptions, SponsoredListing>> pause(String productId);
}
