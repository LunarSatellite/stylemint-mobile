import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/domain/vendor_journey.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_page.dart';
import 'package:uuid/uuid.dart';

/// The seller app's journey calls (journey reels contract v1 §4,
/// `/v1/vendor/journeys`). Every call 404s until the backend is deployed;
/// the screens say "being set up" for that.
abstract class VendorJourneysApi {
  Future<Either<ServiceFailure, List<VendorJourney>>> list({
    JourneyRole? role,
    JourneyState? state,
  });

  Future<Either<ServiceFailure, VendorJourney>> get(String journeyId);

  Future<Either<ServiceFailure, VendorJourney>> create({
    required String reelId,
    String? title,
    String? city,
  });

  Future<Either<ServiceFailure, VendorJourney>> update(
    String journeyId, {
    String? title,
    String? city,
  });

  Future<Either<ServiceFailure, VendorJourney>> invite(
    String journeyId, {
    required String vendorAccountId,
    String? note,
  });

  Future<Either<ServiceFailure, VendorJourney>> accept(
    String journeyId,
    String stepId, {
    required String reelId,
  });

  Future<Either<ServiceFailure, Unit>> decline(String journeyId, String stepId);

  Future<Either<ServiceFailure, VendorJourney>> replaceReel(
    String journeyId,
    String stepId, {
    required String reelId,
  });

  Future<Either<ServiceFailure, Unit>> leave(String journeyId);

  Future<Either<ServiceFailure, VendorJourney>> reorder(
    String journeyId,
    List<String> stepIds,
  );

  Future<Either<ServiceFailure, VendorJourney>> removeStep(
    String journeyId,
    String stepId,
  );

  Future<Either<ServiceFailure, VendorJourney>> end(String journeyId);

  Future<Either<ServiceFailure, List<JourneyVendor>>> searchVendors(
    String query, {
    int limit = 20,
  });

  Future<Either<ServiceFailure, List<JourneyReelOption>>> myReels({
    String? journeyId,
    int limit = 30,
  });
}

class VendorJourneysApiImpl implements VendorJourneysApi {
  VendorJourneysApiImpl(this._api);

  final ApiClient _api;

  static const _base = '/v1/vendor/journeys';

  static String _id(String id) => Uri.encodeComponent(id);

  /// One Idempotency-Key per user action: each call is one tap.
  Options _write() => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': const Uuid().v4(),
    },
  );

  Future<Either<ServiceFailure, VendorJourney>> _journey(
    Future<dynamic> Function() call,
  ) => guardedServiceCall(
    () async => readVendorJourney(readJsonObject(await call())),
  );

  @override
  Future<Either<ServiceFailure, List<VendorJourney>>> list({
    JourneyRole? role,
    JourneyState? state,
  }) => guardedServiceCall(
    () async => readServiceList(
      await _api.get(
        _base,
        queryParameters: <String, dynamic>{
          'role': ?role?.wire,
          'state': ?state?.wire,
        },
      ),
      readVendorJourney,
    ),
  );

  @override
  Future<Either<ServiceFailure, VendorJourney>> get(String journeyId) =>
      _journey(() => _api.get('$_base/${_id(journeyId)}'));

  @override
  Future<Either<ServiceFailure, VendorJourney>> create({
    required String reelId,
    String? title,
    String? city,
  }) => _journey(
    () => _api.post(
      _base,
      data: <String, dynamic>{
        'title': _blankToNull(title),
        'city': _blankToNull(city),
        'reelId': reelId,
      },
      options: _write(),
    ),
  );

  @override
  Future<Either<ServiceFailure, VendorJourney>> update(
    String journeyId, {
    String? title,
    String? city,
  }) => _journey(
    () => _api.put(
      '$_base/${_id(journeyId)}',
      data: <String, dynamic>{
        'title': _blankToNull(title),
        'city': _blankToNull(city),
      },
      options: _write(),
    ),
  );

  @override
  Future<Either<ServiceFailure, VendorJourney>> invite(
    String journeyId, {
    required String vendorAccountId,
    String? note,
  }) => _journey(
    () => _api.post(
      '$_base/${_id(journeyId)}/invites',
      data: <String, dynamic>{
        'vendorAccountId': vendorAccountId,
        'note': ?_blankToNull(note),
      },
      options: _write(),
    ),
  );

  @override
  Future<Either<ServiceFailure, VendorJourney>> accept(
    String journeyId,
    String stepId, {
    required String reelId,
  }) => _journey(
    () => _api.post(
      '$_base/${_id(journeyId)}/steps/${_id(stepId)}/accept',
      data: <String, dynamic>{'reelId': reelId},
      options: _write(),
    ),
  );

  @override
  Future<Either<ServiceFailure, Unit>> decline(
    String journeyId,
    String stepId,
  ) => guardedServiceCall(() async {
    await _api.post(
      '$_base/${_id(journeyId)}/steps/${_id(stepId)}/decline',
      options: _write(),
    );
    return unit;
  });

  @override
  Future<Either<ServiceFailure, VendorJourney>> replaceReel(
    String journeyId,
    String stepId, {
    required String reelId,
  }) => _journey(
    () => _api.put(
      '$_base/${_id(journeyId)}/steps/${_id(stepId)}/reel',
      data: <String, dynamic>{'reelId': reelId},
      options: _write(),
    ),
  );

  @override
  Future<Either<ServiceFailure, Unit>> leave(String journeyId) =>
      guardedServiceCall(() async {
        await _api.post('$_base/${_id(journeyId)}/leave', options: _write());
        return unit;
      });

  @override
  Future<Either<ServiceFailure, VendorJourney>> reorder(
    String journeyId,
    List<String> stepIds,
  ) => _journey(
    () => _api.put(
      '$_base/${_id(journeyId)}/order',
      data: <String, dynamic>{'stepIds': stepIds},
      options: _write(),
    ),
  );

  @override
  Future<Either<ServiceFailure, VendorJourney>> removeStep(
    String journeyId,
    String stepId,
  ) => _journey(
    () => _api.authDelete(
      '$_base/${_id(journeyId)}/steps/${_id(stepId)}',
      options: _write(),
    ),
  );

  @override
  Future<Either<ServiceFailure, VendorJourney>> end(String journeyId) =>
      _journey(
        () => _api.post('$_base/${_id(journeyId)}/end', options: _write()),
      );

  @override
  Future<Either<ServiceFailure, List<JourneyVendor>>> searchVendors(
    String query, {
    int limit = 20,
  }) => guardedServiceCall(
    () async => readServiceList(
      await _api.get(
        '$_base/vendors',
        queryParameters: <String, dynamic>{'q': query.trim(), 'limit': limit},
      ),
      readJourneyVendor,
    ),
  );

  @override
  Future<Either<ServiceFailure, List<JourneyReelOption>>> myReels({
    String? journeyId,
    int limit = 30,
  }) => guardedServiceCall(
    () async => readServiceList(
      await _api.get(
        '$_base/my-reels',
        queryParameters: <String, dynamic>{
          'journeyId': ?journeyId,
          'limit': limit,
        },
      ),
      readJourneyReelOption,
    ),
  );
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _media(Object? raw) {
  final url = readOptionalString(raw);
  return url == null ? null : absoluteMediaUrl(url);
}

/// `VendorJourneyDto`.
VendorJourney readVendorJourney(Map<String, dynamic> json) {
  final id = readString(json['id']);
  if (id.isEmpty) throw const FormatException('journey without id');
  final rows = json['steps'];
  final steps = <VendorJourneyStep>[
    if (rows is List)
      for (final row in rows)
        if (row is Map) readVendorJourneyStep(Map<String, dynamic>.from(row)),
  ]..sort((a, b) => a.index.compareTo(b.index));
  return VendorJourney(
    id: id,
    title: readOptionalString(json['title']),
    city: readOptionalString(json['city']),
    state: JourneyState.fromWire(normalizeWireEnum(json['state'])),
    ownerVendorAccountId: readString(json['ownerVendorAccountId']),
    ownerName: readString(json['ownerName']),
    ownerLogoUrl: _media(json['ownerLogoUrl']),
    myRole: JourneyRole.fromWire(normalizeWireEnum(json['myRole'])),
    myStepId: readOptionalString(json['myStepId']),
    isLive: readBool(json['isLive']),
    visibleStepCount: readInt(json['visibleStepCount']),
    maxSteps: json['maxSteps'] is num ? readInt(json['maxSteps']) : 8,
    endedUtc: readDate(json['endedUtc']),
    endedByAdmin: readInt(json['endedBy']) == 2,
    endReason: readOptionalString(json['endReason']),
    updatedUtc: readDate(json['updatedUtc']),
    steps: List.unmodifiable(steps),
  );
}

VendorJourneyStep readVendorJourneyStep(Map<String, dynamic> json) =>
    VendorJourneyStep(
      id: readString(json['id'] ?? json['stepId']),
      index: readInt(json['index']),
      state: JourneyStepState.fromWire(normalizeWireEnum(json['state'])),
      vendorAccountId: readString(json['vendorAccountId']),
      vendorName: readString(json['vendorName']),
      vendorLogoUrl: _media(json['vendorLogoUrl']),
      reelId: readOptionalString(json['reelId']),
      thumbnailUrl: _media(json['thumbnailUrl']),
      caption: readOptionalString(json['caption']),
      isVisible: readBool(json['isVisible']),
      hiddenReason: JourneyStepHiddenReason.fromWire(
        normalizeWireEnum(json['hiddenReason']),
      ),
      inviteNote: readOptionalString(json['inviteNote']),
      invitedUtc: readDate(json['invitedUtc']),
      acceptedUtc: readDate(json['acceptedUtc']),
    );

JourneyVendor readJourneyVendor(Map<String, dynamic> json) {
  final id = readString(json['vendorAccountId']);
  if (id.isEmpty) throw const FormatException('vendor without id');
  return JourneyVendor(
    vendorAccountId: id,
    businessName: readString(json['businessName']),
    logoUrl: _media(json['logoUrl']),
    city: readOptionalString(json['city']),
    category: readInt(json['category']),
    isVerified: readBool(json['isVerified']),
  );
}

JourneyReelOption readJourneyReelOption(Map<String, dynamic> json) {
  final id = readString(json['reelId']);
  if (id.isEmpty) throw const FormatException('reel without id');
  return JourneyReelOption(
    reelId: id,
    thumbnailUrl: _media(json['thumbnailUrl']),
    caption: readOptionalString(json['caption']),
    publishedAtUtc: readDate(json['publishedAtUtc']),
    journeyCount: readInt(json['journeyCount']),
    canUse: json['canUse'] is bool ? json['canUse'] as bool : true,
    reason: readOptionalString(json['reason']),
  );
}

/// Sentences for the journey error codes (contract §4 "Errors").
String? journeyErrorMessage(String code) => switch (code) {
  'journey.not_found' => 'This journey is not available any more.',
  'journey.step_not_found' => 'That step is not part of this journey any more.',
  'journey.ended' => 'This journey has ended, so it cannot be changed.',
  'journey.reel_not_eligible' =>
    'Pick one of your own published reels.',
  'journey.reel_limit' =>
    'That reel is already in 3 journeys. Pick another reel.',
  'journey.step_limit' => 'This journey already has the most steps allowed.',
  'journey.owned_limit' =>
    'You already run 20 active journeys. End one to start another.',
  'journey.vendor_not_eligible' => 'That business cannot be invited.',
  'journey.already_member' => 'That business is already in this journey.',
  'journey.invalid_step_state' =>
    'That step changed in the meantime. Pull to refresh.',
  'journey.owner_step_locked' =>
    'Your own step stays while the journey runs. End the journey instead.',
  'journey.order_mismatch' =>
    'The steps changed in the meantime. Pull to refresh and try again.',
  'state.concurrency_conflict' =>
    'Someone changed this journey at the same moment. Pull to refresh.',
  _ => null,
};
