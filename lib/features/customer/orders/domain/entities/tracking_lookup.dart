/// The answer to "which of my orders is this parcel from?", as the client
/// needs to act on it.
///
/// `GET /v1/orders/by-tracking/{trackingNumber}` answers in one call. Its 404
/// is deliberately ambiguous — an invented tracking number, one belonging to
/// another customer, and one whose order is unreadable are the same response —
/// so there is exactly one [TrackingLookupNotFound] and no way (and no
/// intention) to tell those apart. Its 429 is a separate case: the answer
/// exists, we are simply asking too often.
sealed class TrackingLookup {
  const TrackingLookup();
}

/// The parcel is the caller's, and belongs to [orderNumber].
final class TrackingLookupResolved extends TrackingLookup {
  const TrackingLookupResolved(this.orderNumber);

  final String orderNumber;
}

/// The backend will not name an order for this tracking number. Unknown,
/// someone else's, or unreadable — indistinguishable by design.
final class TrackingLookupNotFound extends TrackingLookup {
  const TrackingLookupNotFound();
}

/// The lookup is rate limited (20/min per caller). Not an answer of "no" —
/// ask again shortly.
final class TrackingLookupRateLimited extends TrackingLookup {
  const TrackingLookupRateLimited();
}
