/// Resolves the destination a tapped notification should open.
///
/// Kept apart from the widget that uses it so it can be tested: the tap
/// handling itself lives on the app's State, next to the deep-link path it
/// reuses, and is not reachable from a unit test.
///
/// **The server's FCM data keys are not pinned by any contract in this repo.**
/// The notifications documentation covers the inbox API
/// (`GET /api/v1/notifications/inbox`, `NotificationDispatchDto`) and says
/// nothing about the push payload, so this accepts the spellings a backend
/// plausibly sends and returns null for anything else. Returning null is not a
/// failure: a notification that only tells the user something has no
/// destination, and opening the app is the right outcome.
///
/// When the contract is confirmed, narrow [_keys] to what the server actually
/// sends rather than leaving the guesses in place.
library;

const List<String> _keys = ['deepLink', 'deep_link', 'link', 'url', 'route'];

Uri? pushDestinationUri(Map<String, dynamic> data) {
  for (final key in _keys) {
    final raw = data[key]?.toString().trim();
    if (raw == null || raw.isEmpty) continue;

    // A bare path ("/orders/123") is not something the deep-link path can
    // read, so it is given the app's own scheme. `stylemint://orders/123`
    // rather than `stylemint:///orders/123`: the first segment lands in the
    // URI's host, which _navigate rebuilds back into the path.
    final candidate = raw.startsWith('/')
        ? 'stylemint://${raw.substring(1)}'
        : raw;
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.scheme.isEmpty) continue;
    return uri;
  }
  return null;
}
