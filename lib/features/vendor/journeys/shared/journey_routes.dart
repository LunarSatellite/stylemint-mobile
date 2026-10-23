/// Seller-app routes for collaborative journeys. The detail path is exactly
/// the seller deep link the backend puts in every journey notification
/// (journey reels contract v1 §6: `/vendor/journeys/{journeyId}`).
abstract final class JourneyRoutes {
  static const list = '/vendor/journeys';
  static const create = '/vendor/journeys/new';
  static const detail = '/vendor/journeys/:journeyId';

  static String detailPath(String journeyId) =>
      '/vendor/journeys/${Uri.encodeComponent(journeyId)}';
}

final _guid = RegExp(
  r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Where a journey notice opens, or null when it is not one.
///
/// Journey notices carry `data.type = "journey"` (the inbox may name the
/// template instead: `journey.invite.received`, `journey.ended`, …),
/// `data.journeyId` and `data.deepLink`. The journey screen by id first;
/// else the server's link when it is a seller journey path; else the list.
String? journeyNotificationLocation(
  String? type,
  Map<String, dynamic> data, {
  String? link,
}) {
  if (type == null) return null;
  if (type != 'journey' && !type.startsWith('journey.')) return null;
  final journeyId = data['journeyId']?.toString().trim();
  if (journeyId != null && _guid.hasMatch(journeyId)) {
    return JourneyRoutes.detailPath(journeyId);
  }
  if (link != null && link.startsWith(JourneyRoutes.list)) return link;
  return JourneyRoutes.list;
}
