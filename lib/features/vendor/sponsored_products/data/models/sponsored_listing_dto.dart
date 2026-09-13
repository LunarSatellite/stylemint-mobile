import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';

/// Wire shape of backend `SponsoredListingDto`, serialized camelCase:
/// `{ id, productId, productName, state, isLive, dailyImpressionCap,
/// endsUtc?, impressionsToday, impressionsLast7Days, unitsSoldLast7Days,
/// unitsSoldPrevious7Days, disclosure, salesComparisonNote, createdUtc,
/// updatedUtc }`. The backend registers no JsonStringEnumConverter, so
/// `state` arrives as an int; string names are accepted too.
class SponsoredListingDto {
  const SponsoredListingDto({
    required this.id,
    required this.productId,
    required this.productName,
    required this.state,
    required this.isLive,
    required this.dailyImpressionCap,
    required this.impressionsToday,
    required this.impressionsLast7Days,
    required this.unitsSoldLast7Days,
    required this.unitsSoldPrevious7Days,
    required this.disclosure,
    required this.salesComparisonNote,
    this.endsUtc,
    this.createdUtc,
    this.updatedUtc,
  });

  factory SponsoredListingDto.fromJson(Map<String, dynamic> json) =>
      SponsoredListingDto(
        id: _string(json['id']),
        productId: _string(json['productId']),
        productName: _string(json['productName']),
        state: parseSponsoredListingState(json['state']),
        isLive: _bool(json['isLive']),
        dailyImpressionCap: _int(json['dailyImpressionCap']),
        endsUtc: _date(json['endsUtc']),
        impressionsToday: _int(json['impressionsToday']),
        impressionsLast7Days: _int(json['impressionsLast7Days']),
        unitsSoldLast7Days: _int(json['unitsSoldLast7Days']),
        unitsSoldPrevious7Days: _int(json['unitsSoldPrevious7Days']),
        disclosure: _string(json['disclosure']),
        salesComparisonNote: _string(json['salesComparisonNote']),
        createdUtc: _date(json['createdUtc']),
        updatedUtc: _date(json['updatedUtc']),
      );

  /// The `GET /v1/vendor/store/sponsored` array. Entries without a product
  /// id can't be paused or changed, so they are dropped; anything that
  /// isn't a list reads as no sponsorships.
  static List<SponsoredListingDto> listFromJson(Object? raw) {
    if (raw is! List) return const <SponsoredListingDto>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SponsoredListingDto.fromJson)
        .where((l) => l.productId.isNotEmpty)
        .toList(growable: false);
  }

  final String id;
  final String productId;
  final String productName;
  final SponsoredListingState state;
  final bool isLive;
  final int dailyImpressionCap;
  final DateTime? endsUtc;
  final int impressionsToday;
  final int impressionsLast7Days;
  final int unitsSoldLast7Days;
  final int unitsSoldPrevious7Days;
  final String disclosure;
  final String salesComparisonNote;
  final DateTime? createdUtc;
  final DateTime? updatedUtc;

  SponsoredListing toDomain() => SponsoredListing(
    id: id,
    productId: productId,
    productName: productName,
    state: state,
    isLive: isLive,
    dailyImpressionCap: dailyImpressionCap,
    endsUtc: endsUtc,
    impressionsToday: impressionsToday,
    impressionsLast7Days: impressionsLast7Days,
    unitsSoldLast7Days: unitsSoldLast7Days,
    unitsSoldPrevious7Days: unitsSoldPrevious7Days,
    disclosure: disclosure,
    salesComparisonNote: salesComparisonNote,
    createdUtc: createdUtc,
    updatedUtc: updatedUtc,
  );
}

/// Backend `SponsoredListingState`: Active=1, Paused=2. Accepts the int, a
/// numeric string, or the name in any casing; anything else is
/// [SponsoredListingState.unknown].
SponsoredListingState parseSponsoredListingState(Object? raw) =>
    switch (_normalizeEnum(raw)) {
      1 || 'active' => SponsoredListingState.active,
      2 || 'paused' => SponsoredListingState.paused,
      _ => SponsoredListingState.unknown,
    };

/// An int for int / whole-number / numeric-string input, a lowercase name
/// with `_`, `-` and spaces removed for other strings, else null.
Object? _normalizeEnum(Object? raw) {
  if (raw is int) return raw;
  if (raw is num && raw == raw.roundToDouble()) return raw.toInt();
  if (raw is String) {
    final trimmed = raw.trim();
    return int.tryParse(trimmed) ??
        trimmed.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }
  return null;
}

String _string(Object? raw) => raw is String ? raw.trim() : '';

/// Counts arrive as JSON numbers (`long` on the backend); tolerate numeric
/// strings, and read anything else as 0.
int _int(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? 0;
  return 0;
}

bool _bool(Object? raw) {
  if (raw is bool) return raw;
  if (raw is String) return raw.trim().toLowerCase() == 'true';
  return false;
}

DateTime? _date(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? DateTime.tryParse(raw) : null;
