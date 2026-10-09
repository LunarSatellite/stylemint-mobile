import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';

/// The sentence for the failures every EMI surface shares — offline, signed
/// out, server down — or null when [failure] needs a screen-specific one.
String? emiCommonMessage(EmiFailure failure) => switch (failure.kind) {
  EmiFailureKind.offline =>
    'You appear to be offline. Check your connection and try again.',
  EmiFailureKind.auth => 'Your session has expired. Sign in again.',
  EmiFailureKind.server =>
    'StyleMint is temporarily unavailable. Please try again in a moment.',
  EmiFailureKind.notFound =>
    'EMI is not available yet. Please check back soon.',
  EmiFailureKind.tooLarge => 'That file is too large to upload.',
  EmiFailureKind.rejected || EmiFailureKind.unknown => null,
};

/// The server's own sentence when it sent one, else [fallback].
String serverMessageOr(EmiFailure failure, String fallback) {
  final message = failure.message?.trim();
  return message == null || message.isEmpty ? fallback : message;
}

/// What the calculator says when `GET /v1/emi/quote` refuses.
String emiQuoteMessage(EmiFailure failure) {
  switch (failure.code) {
    case 'emi_quote.not_available':
      return 'EMI is not offered on this option any more.';
    case 'emi_quote.down_payment_out_of_range':
      return 'That down payment is outside what the seller allows.';
    case 'emi_quote.invalid_tenure':
      return 'The seller does not offer that number of months.';
  }
  if (failure.isNotFound) return 'EMI is not offered on this option any more.';
  return emiCommonMessage(failure) ??
      serverMessageOr(failure, 'We could not confirm this plan right now.');
}
