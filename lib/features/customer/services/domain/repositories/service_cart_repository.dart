import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';

/// Stays and trips in the cart and at checkout (service cart contract v1).
///
/// Its own repository, beside the cart's and checkout's, because these
/// calls need what [ServiceFailure] keeps — the `errorCode` of a 409
/// (`cart.service_unavailable`) and the per-line `errors[]`.
abstract interface class ServiceCartRepository {
  /// Adds a stay or trip with the options chosen on its item page. Nothing
  /// is held yet: rooms and seats are held when checkout starts.
  Future<Either<ServiceFailure, Cart>> addToCart({
    required String productId,
    required ServiceOptions options,
    required String idempotencyKey,
    String? variantId,
    String? reelTagContextId,
  });

  /// Names the guests or travellers of service lines on checkout session
  /// [sessionId]; returns the session's service lines as now saved.
  Future<Either<ServiceFailure, List<ServiceLine>>> setGuests({
    required String sessionId,
    required List<ServiceGuests> lines,
    required String idempotencyKey,
  });
}
