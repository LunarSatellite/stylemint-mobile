import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/service_line_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/shared/data/option_label.dart';

/// The two calls services add to the cart and checkout (service cart
/// contract v1): adding a stay or trip with its options, and naming the
/// guests or travellers of each service line at checkout.
///
/// No request carries an amount: the server prices every line from the
/// listing, as it does for a Bookings quote.
class ServiceCartRemoteDataSource {
  ServiceCartRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static Options _idempotent(String key) =>
      Options(headers: {'requiresToken': true, 'Idempotency-Key': key});

  /// The `serviceOptions` body of §2.1.
  static Map<String, dynamic> optionsJson(ServiceOptions o) => {
    'listingId': o.listingId,
    if (o.kind == ListingKind.stay) ...{
      'roomTypeId': o.roomTypeId,
      'checkIn': searchWireDate(o.checkIn!),
      'checkOut': searchWireDate(o.checkOut!),
      'rooms': o.rooms,
    } else
      'departureId': o.departureId,
    'adults': o.adults,
    'children': o.children,
    if (o.paymentMode != null) 'paymentMode': o.paymentMode!.wire,
  };

  /// `POST v1/cart/lines` with `serviceOptions` (§2.1): quantity is always
  /// 1, and every add is a new line.
  Future<CartDto> addService({
    required String productId,
    required ServiceOptions options,
    required String idempotencyKey,
    String? variantId,
    String? reelTagContextId,
  }) async {
    final response = await apiClient.post(
      '/v1/cart/lines',
      data: {
        'productId': productId,
        'quantity': 1,
        'productVariantId': ?variantId,
        'reelTagContextId': ?reelTagContextId,
        'serviceOptions': optionsJson(options),
      },
      options: _idempotent(idempotencyKey),
    );
    return CartDto.fromJson(
      withOptionLabels(Map<String, dynamic>.from(response as Map)),
    );
  }

  /// `POST v1/checkout/sessions/{sessionId}/service-guests` (§3.3). Returns
  /// the session's service lines as the server now has them.
  Future<List<ServiceLine>> setGuests({
    required String sessionId,
    required List<ServiceGuests> lines,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/checkout/sessions/${Uri.encodeComponent(sessionId)}/service-guests',
      data: {
        'lines': [
          for (final l in lines)
            {
              'lineId': l.lineId,
              'guestName': l.guestName.trim(),
              'travellers': [
                for (final t in l.travellers)
                  {
                    'fullName': t.fullName.trim(),
                    'type': t.type.wire,
                    'age': t.age,
                  },
              ],
              if (l.specialRequests?.trim().isNotEmpty ?? false)
                'specialRequests': l.specialRequests!.trim(),
            },
        ],
      },
      options: _idempotent(idempotencyKey),
    );
    final json = response is Map ? response : const {};
    return readServiceLines(json['serviceLines']);
  }
}
