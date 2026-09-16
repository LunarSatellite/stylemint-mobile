import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/product_reel_ref.dart';

/// Reads the nullable `reel` object off a public product payload.
///
/// The field does not exist on the server yet, so this has to be tolerant in
/// both directions: absent, null, a non-object, or an object missing every
/// field but the id all read as "no reel", and a product renders its type
/// tile. Nothing here throws — a malformed reel must never cost the page a
/// product card.
ProductReelRef? readProductReelRef(Object? raw) {
  if (raw is! Map) return null;
  final json = Map<String, dynamic>.from(raw);
  final id = _text(json['reelId']) ?? _text(json['id']);
  if (id == null) return null;
  final poster = absoluteMediaUrl(_text(json['posterUrl']));
  return ProductReelRef(
    reelId: id,
    posterUrl: poster.isEmpty ? null : poster,
    platform: SocialPlatform.tryParseWire(json['sourcePlatform']),
    externalId: _text(json['externalId']),
    hook: _text(json['hook']),
    isAiGenerated: json['isAiGenerated'] == true,
    durationSeconds: _seconds(json['durationSeconds']),
  );
}

/// A trimmed string, or null for anything blank or not string-shaped.
/// Numbers are read as their text so an id sent unquoted still works.
String? _text(Object? raw) {
  final value = switch (raw) {
    final String text => text.trim(),
    final num number => number.toString(),
    _ => '',
  };
  return value.isEmpty ? null : value;
}

/// Whole seconds, never negative. Anything else reads as "unknown" (0), and
/// the tile then shows no duration rather than a wrong one.
int _seconds(Object? raw) {
  final value = switch (raw) {
    final num number => number.isFinite ? number.round() : 0,
    final String text => int.tryParse(text.trim()) ?? 0,
    _ => 0,
  };
  return value > 0 ? value : 0;
}
