import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';

/// The sentence a Services screen shows for [failure]. [what] names what
/// failed to load ("this stay", "your bookings").
///
/// Known `errorCode`s get their own words; otherwise the server's own
/// sentence, when it sent one, beats a generic one.
String serviceFailureMessage(ServiceFailure failure, {String what = 'this'}) {
  final byCode = _codeMessages[failure.code];
  if (byCode != null) return byCode;
  switch (failure.kind) {
    case ServiceFailureKind.offline:
      return 'You are offline. Check your connection and try again.';
    case ServiceFailureKind.auth:
      return 'Your session has ended. Sign in again to continue.';
    case ServiceFailureKind.notFound:
      return failure.isComingSoon
          ? 'Services are coming soon.'
          : 'We could not find $what. It may have been removed.';
    case ServiceFailureKind.conflict:
      return failure.message ??
          'That was just taken by someone else. Pick another and try again.';
    case ServiceFailureKind.rejected:
      return failure.message ?? 'That did not go through. Check and try again.';
    case ServiceFailureKind.server:
      return 'Something went wrong on our side. Try again in a moment.';
    case ServiceFailureKind.unknown:
      return 'We could not load $what. Try again.';
  }
}

/// Words for the error codes the Services contracts name. Codes this build
/// does not know fall back to the server's sentence.
const _codeMessages = <String, String>{
  // Stays and travel.
  'booking.sold_out':
      'Those dates just sold out. Pick other dates or another room.',
  'booking.unavailable':
      'Those dates just sold out. Pick other dates or another room.',
  'booking.seats_unavailable':
      'Not enough seats are left on that departure. Pick fewer travellers '
      'or another date.',
  'booking.hold_expired':
      'We held your booking for a while, but the hold has expired. Get a '
      'fresh price and try again.',
  'quote.expired': 'That price has expired. Get a fresh price and try again.',
  'booking.quote_expired':
      'That price has expired. Get a fresh price and try again.',
  'booking.payment_mode_not_allowed':
      'This listing does not take that way to pay. Choose another.',
  'booking.min_nights': 'This stay needs more nights. Change your dates.',
  'booking.max_nights': 'This stay allows fewer nights. Change your dates.',
  'booking.invalid_dates': 'Check-out must be after check-in.',
  'booking.too_many_guests': 'Too many guests for that room. Add a room.',
  'booking.not_cancellable': 'This booking can no longer be cancelled here.',
  'booking.already_cancelled': 'This booking is already cancelled.',
  // Banks (banks contract v1 §6).
  'service_vendor.not_found': 'This bank is not on StyleMint any more.',
  'bank_product.not_found': 'This product is no longer offered.',
  'bank_branch.not_found': 'This branch is no longer listed.',
  'bank_branch.inactive': 'This branch is not taking appointments right now.',
  'service_enquiry.consent_required':
      'Tick the box to let the bank contact you, then send again.',
  'service_enquiry.consent_outdated':
      'The bank\'s consent wording has changed. Read it again and tick the '
      'box to send.',
  'service_enquiry.duplicate':
      'You already sent this bank an enquiry about this product today. '
      'They will be in touch.',
  'service_enquiry.too_many_open':
      'You have several open enquiries with this bank. Wait for them to '
      'reply, or withdraw one first.',
  'service_lead.not_found': 'We could not find this enquiry.',
  'service_appointment.not_found': 'We could not find this appointment.',
  'service_appointment.slot_full':
      'That time just filled up. Pick another slot.',
  'service_appointment.slot_unavailable':
      'That time is no longer available. Pick another slot.',
  'service_appointment.already_booked':
      'You already have an appointment in that slot.',
  'service_appointment.too_many':
      'You already have three upcoming appointments with this bank.',
  'service_appointment.busy':
      'Lots of people are booking right now. Try again in a moment.',
  'service_appointment.not_cancellable':
      'This appointment can no longer be cancelled here.',
};
