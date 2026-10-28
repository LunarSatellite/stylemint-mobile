import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/navigation/payment_return_link.dart';

const _site = 'https://stylemint.voyageritnepal.com';

PaymentLinkKind _kind(String link) => classifyPaymentLink(Uri.parse(link));

void main() {
  group('classifyPaymentLink', () {
    test('eSewa returns to the site are provider returns', () {
      expect(
        _kind('$_site/payments/esewa/return/success?data=eyJ0cmFuc2FjdGlvbiJ9'),
        PaymentLinkKind.providerReturn,
      );
      expect(
        _kind('$_site/payments/esewa/return/failure'),
        PaymentLinkKind.providerReturn,
      );
    });

    test('connectIPS returns are provider returns too', () {
      expect(
        _kind('$_site/payments/connectips/return/success?TXNID=1'),
        PaymentLinkKind.providerReturn,
      );
    });

    test('other payment pages stay ignored', () {
      expect(
        _kind('$_site/payments/esewa/checkout?order=NK2026-1'),
        PaymentLinkKind.otherPaymentPage,
      );
      expect(
        _kind('$_site/payments/connectips/checkout'),
        PaymentLinkKind.otherPaymentPage,
      );
      // The bare prefix, without the trailing segment, is not a return.
      expect(
        _kind('$_site/payments/esewa/return'),
        PaymentLinkKind.otherPaymentPage,
      );
    });

    test('a return is only fetched from an https StyleMint URL', () {
      expect(
        _kind('http://stylemint.voyageritnepal.com/payments/esewa/return/success'),
        PaymentLinkKind.otherPaymentPage,
      );
      expect(
        _kind('https://evil.example/payments/esewa/return/success?data=x'),
        PaymentLinkKind.otherPaymentPage,
      );
      expect(
        _kind('stylemint://payments/esewa/return/success'),
        PaymentLinkKind.none,
      );
    });

    test('everything else is not a payment link', () {
      expect(_kind('$_site/?payment=success'), PaymentLinkKind.none);
      expect(_kind('$_site/product/abc'), PaymentLinkKind.none);
      expect(_kind('$_site/v1/payments/esewa'), PaymentLinkKind.none);
    });
  });

  group('confirmPaymentReturn', () {
    test('loads the exact URL once, unauthenticated, not following the '
        'redirect', () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(
                Response<String>(
                  requestOptions: options,
                  statusCode: 302,
                  headers: Headers.fromMap({
                    'location': ['/?payment=success'],
                  }),
                ),
              );
            },
          ),
        );
      final uri = Uri.parse(
        '$_site/payments/esewa/return/success?data=eyJ0cmFuc2FjdGlvbiJ9',
      );

      await confirmPaymentReturn(uri, dio: dio);

      expect(requests, hasLength(1));
      expect(requests.single.uri, uri);
      expect(requests.single.method, 'GET');
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
      expect(requests.single.followRedirects, isFalse);
    });

    test('a failed request is swallowed', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            ),
          ),
        );

      await expectLater(
        confirmPaymentReturn(
          Uri.parse('$_site/payments/esewa/return/failure'),
          dio: dio,
        ),
        completes,
      );
    });
  });
}
