import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';

/// Plain words for a failed seller action on a return — approve, reject or
/// "Mark received" (return fixes contract C). Keyed on the server's
/// `errorCode`, the same wording as Seller Center's `pickupErrorMessage`.
abstract final class VendorReturnErrorCopy {
  static const fallback = 'Could not update this return. Please try again.';

  static const pickupNotReceived =
      'The rider hasn’t handed this return to you yet. '
      'Scan the rider’s code first, then mark it received.';

  static const changed =
      'This return just changed. Pull down to refresh and try again.';

  static const offline = 'You’re offline. Check your connection and try again.';

  static const unavailable =
      'StyleMint is busy right now. Please try again in a moment.';

  static const byCode = <String, String>{
    'return.pickup_not_received': pickupNotReceived,
    'delivery_request.expired':
        'This request expired. Try again to notify riders.',
    'delivery_request.rider_not_interested':
        'That rider is no longer available. Choose another rider.',
    'delivery_request.already_assigned':
        'A rider is already assigned to this return.',
    'delivery_request.closed': 'This return is no longer waiting for a rider.',
    'delivery_proof.invalid':
        'That code doesn’t match. Check the code in the rider’s app.',
    'delivery_proof.expired':
        'That code has expired. Ask the rider to show a new one.',
    'delivery_proof.too_many_attempts':
        'Too many wrong codes. Try again in 15 minutes.',
    'delivery_proof.not_recipient': 'This code is not for your shop.',
    'delivery_proof.already_confirmed': 'This return was already handed over.',
    'state.invalid_transition': changed,
    'state.concurrency_conflict': changed,
    'state.conflict': changed,
  };

  /// The message for [failure]: its error code's wording, else a family
  /// default (`delivery_proof.*`, `delivery_request.*`), else [fallback].
  static String message(NetworkExceptions failure) {
    if (failure.isNoInternet) return offline;
    final code = failure.validationCode?.trim().toLowerCase();
    if (code != null) {
      if (byCode[code] case final text?) return text;
      if (code.startsWith('delivery_proof.')) {
        return 'The rider’s code could not be checked. Ask them to show it again.';
      }
      if (code.startsWith('delivery_request.')) {
        return 'The rider request changed. Pull down to refresh and try again.';
      }
    }
    return failure.maybeWhen(
      conflict: () => changed,
      notFound: () => 'This return is no longer available. Pull down to refresh.',
      serverUnavailable: () => unavailable,
      orElse: () => fallback,
    );
  }
}
