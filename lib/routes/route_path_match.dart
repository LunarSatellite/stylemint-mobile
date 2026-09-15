/// Whether the location [path] falls under the route [pattern] from
/// `RouteNames`.
///
/// A pattern without parameters matches as a plain prefix, as the router has
/// always done (`/settings` covers `/settings/privacy`). A pattern with
/// `:parameters` (`/product/:productId`) matches segment by segment: each
/// parameter stands for any one non-empty segment, and [path] may continue
/// below the pattern (`/product/p1/reviews`). Query strings and fragments on
/// [path] are ignored.
bool routePathMatches(String path, String pattern) {
  final location = path.split(RegExp('[?#]')).first;
  if (!pattern.contains(':')) return location.startsWith(pattern);

  final locationSegments = _segments(location);
  final patternSegments = _segments(pattern);
  if (locationSegments.length < patternSegments.length) return false;

  for (var i = 0; i < patternSegments.length; i++) {
    final expected = patternSegments[i];
    final actual = locationSegments[i];
    if (expected.startsWith(':')) {
      if (actual.isEmpty) return false;
    } else if (expected != actual) {
      return false;
    }
  }
  return true;
}

List<String> _segments(String value) =>
    value.split('/').where((segment) => segment.isNotEmpty).toList();
