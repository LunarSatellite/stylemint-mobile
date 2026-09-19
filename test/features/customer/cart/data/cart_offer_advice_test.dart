import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/datasources/cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart_offer.dart';

class _OfferApiClient extends ApiClient {
  _OfferApiClient(this.body) : super(dio: Dio());
  final Map<String, dynamic> body;
  String? uri;

  @override
  Future<dynamic> get(
    String value, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    uri = value;
    return body;
  }
}

void main() {
  const payload = <String, dynamic>{
    'inControlGroup': false,
    'headline': 'Use SAVE10 to save Rs 100.',
    'fairnessNote': 'Same cart, same offers.',
    'note': null,
    'offers': [
      {
        'kind': 1,
        'title': 'Use SAVE10',
        'detail': 'Saves Rs 100 on this order.',
        'valueAmount': 100,
        'currency': 'NPR',
        'code': 'SAVE10',
        'spendMoreAmount': null,
        'expiresUtc': '2026-10-01T00:00:00Z',
        'recommended': true,
      },
    ],
  };

  test('offer advice maps the authoritative wire contract', () {
    final advice = CartOfferAdvice.fromJson(payload);
    expect(advice.headline, contains('SAVE10'));
    expect(advice.hasContent, isTrue);
    expect(advice.offers.single.kind, CartOfferKind.applyCode);
    expect(advice.offers.single.code, 'SAVE10');
    expect(advice.offers.single.recommended, isTrue);
    expect(advice.offers.single.expiresUtc?.isUtc, isTrue);
  });

  test('remote source calls the cart offers endpoint', () async {
    final api = _OfferApiClient(payload);
    final json = await CartRemoteDataSource(apiClient: api).getOfferAdvice();
    expect(api.uri, '/v1/cart/offers');
    expect(CartOfferAdvice.fromJson(json).offers, hasLength(1));
  });

  test('unknown offer kind is safe and empty payload stays hidden', () {
    final unknown = CartOffer.fromJson(const {'kind': 99});
    expect(unknown.kind, CartOfferKind.unknown);
    expect(CartOfferAdvice.fromJson(const {}).hasContent, isFalse);
  });
}
