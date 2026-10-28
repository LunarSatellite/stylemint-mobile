import 'dart:async';

import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/navigation/in_app_link.dart';

/// What a `/payments/...` link reaching the app's link handler is.
enum PaymentLinkKind {
  /// Not a payment page at all: the handler carries on as usual.
  none,

  /// A payment provider sending the buyer back to the site
  /// (`/payments/esewa/return/success?data=…`, `/payments/esewa/return/failure`,
  /// and the connectIPS equivalents). The server confirms the payment when
  /// this URL is loaded, so it must still be fetched.
  providerReturn,

  /// Any other payment page (the eSewa or connectIPS hand-off pages): a web
  /// page for the in-app browser, never an app route. Ignored.
  otherPaymentPage,
}

/// Path prefixes of the provider return URLs the server confirms on.
const paymentReturnPathPrefixes = [
  '/payments/esewa/return/',
  '/payments/connectips/return/',
];

/// Classifies [uri] for the link handler.
///
/// On iOS the domain's universal links can hand every path to the app,
/// including eSewa's redirect back to `/payments/esewa/return/success`. Left
/// alone, that request never reaches the server, which then learns of the
/// payment only later. Only an https StyleMint web URL
/// counts as a provider return: that is the only URL the app will fetch.
PaymentLinkKind classifyPaymentLink(Uri uri) {
  final path = uri.path;
  if (!path.startsWith('/payments/')) return PaymentLinkKind.none;
  final isReturn = paymentReturnPathPrefixes.any(path.startsWith);
  if (isReturn &&
      uri.scheme.toLowerCase() == 'https' &&
      isStyleMintWebHost(uri.host)) {
    return PaymentLinkKind.providerReturn;
  }
  return PaymentLinkKind.otherPaymentPage;
}

/// Loads a provider return URL so the server confirms the payment at once.
///
/// A plain, unauthenticated GET: the server verifies the payment with the
/// provider itself, so no token is sent (and the app's API client, which
/// attaches one, is deliberately not used). The server answers with a 302 to
/// `/?payment=…`, which is not followed. Every error is swallowed: if this
/// request is lost, the order screen keeps polling until the server has
/// learned of the payment some other way.
Future<void> confirmPaymentReturn(Uri uri, {Dio? dio}) async {
  final client =
      dio ??
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
  try {
    await client.getUri<String>(
      uri,
      options: Options(
        followRedirects: false,
        responseType: ResponseType.plain,
        // A 302 is the expected answer, not a failure.
        validateStatus: (_) => true,
      ),
    );
  } catch (_) {
    // Best effort, see above.
  } finally {
    if (dio == null) client.close();
  }
}
