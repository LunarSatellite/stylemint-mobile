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
  // Stays and travel (bookings contract v1 §6).
  'service_listing.not_found': 'This listing is no longer available.',
  'service_listing.not_bookable': 'This listing is not taking bookings now.',
  'room_type.not_found': 'That room is no longer offered. Pick another.',
  'departure.not_found': 'That departure is no longer offered. Pick another.',
  'booking.not_found': 'We could not find this booking.',
  'booking.unavailable':
      'Those rooms or seats were just taken. Check the dates and get a '
      'fresh price.',
  'booking.busy': 'Lots of people are booking this right now. Try again.',
  'booking.hold_expired':
      'The booking was held while you paid, but the hold has run out. Start a new '
      'booking to pay.',
  'booking.nothing_to_pay': 'There is nothing left to pay online.',
  'booking.payment_mode_not_allowed':
      'This listing does not take that way to pay. Choose another.',
  'booking.payment_unavailable':
      'We could not start the payment. Nothing was charged. Try again.',
  'booking.not_cancellable': 'This booking can no longer be cancelled here.',
  'booking.invalid_transition': 'This booking has already changed. Refresh.',
  // Stays and trips in the cart and at checkout (service cart contract v1 §6).
  'cart.service_options_required':
      'Choose your dates, room and guests, then add to cart.',
  'cart.service_options_invalid':
      'Those dates or guests are not allowed here. Check them and try again.',
  'cart.service_not_found':
      'That room or departure is no longer offered. Pick another.',
  'cart.service_not_purchasable': 'This cannot be booked through the cart.',
  'cart.service_unavailable':
      'Not available for that choice any more. Try other dates or another '
      'option.',
  'cart.service_quantity_fixed':
      'A booking cannot change quantity. Remove it and add your new choice.',
  'checkout.service_unavailable':
      'Some rooms or seats in your cart were just taken. Remove them and try '
      'again.',
  'checkout.service_line_not_found':
      'That booking is no longer in your checkout. Start checkout again.',
  'checkout.service_guests_required':
      'Add the guest name for every stay and trip before you pay.',
  'checkout.service_requires_online_payment':
      'Stays and trips with something to pay now need an online payment, not '
      'cash on delivery.',
  'booking.invalid': 'Check the guest and traveller names and try again.',
  'booking.paid_through_order':
      'This booking is paid through its order. Open the order to pay.',
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

/// Why a quote came back `available: false` (bookings contract v1 §2).
String quoteUnavailableMessage(String? reason) => switch (reason) {
  'sold_out' => 'Sold out for these dates. Try other dates or another room.',
  'closed' => 'Not taking bookings for these dates.',
  'capacity' => 'Too many guests for this choice. Add a room or pick fewer.',
  'min_nights' => 'This stay needs more nights. Change your dates.',
  'max_nights' => 'This stay allows fewer nights. Change your dates.',
  'departure_closed' => 'This departure is no longer taking bookings.',
  _ => 'Not available for this choice. Try another.',
};
