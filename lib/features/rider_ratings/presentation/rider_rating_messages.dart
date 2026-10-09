import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';

/// What to tell someone when rating a rider, or reading a rider's details,
/// fails — what happened and what to do, never an error code.
///
/// Keyed on the contract's `rider_rating.*` / `rider_profile.*` codes; an
/// unknown code in either family still gets a sentence of its own family
/// rather than the generic "request rejected".
String riderRatingErrorMessage(NetworkExceptions failure) {
  final code = failure.validationCode?.toLowerCase();
  switch (code) {
    case 'rider_rating.not_eligible':
      return "This order can't be rated. Only parcels a StyleMint rider "
          'delivered — or, for sellers, picked up — can be rated, and only '
          'by the buyer or the seller of that order.';
    case 'rider_rating.window_closed':
      return 'Ratings can be given or changed for 7 days after delivery, and '
          'that time has passed.';
    case 'rider_rating.invalid':
      return "That rating wasn't accepted. Pick 1 to 5 stars, up to 4 tags, "
          'and keep the comment under 300 characters.';
    case 'rider_profile.not_available':
      return 'This rider is no longer available for this parcel.';
  }
  if (code != null && code.startsWith('rider_rating.')) {
    return "Couldn't save your rating. Please try again.";
  }
  if (code != null && code.startsWith('rider_profile.')) {
    return "Couldn't load this rider's details. Please try again.";
  }
  if (failure.isNoInternet) {
    return "You're offline. Connect to the internet and try again.";
  }
  return NetworkExceptions.getMessage(failure);
}

/// True for the "that rider is not on this request any more" answer.
bool isRiderNotAvailable(NetworkExceptions failure) =>
    failure.validationCode?.toLowerCase() == 'rider_profile.not_available';
