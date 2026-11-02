import 'package:dio/dio.dart' show Options;
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundle_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/domain/vendor_bundle.dart';
import 'package:uuid/uuid.dart';

/// The seller app's bundle calls (shop bundles contract §B5,
/// `/v1/bundles`). Answering only: the list of bundles this shop is in, one
/// bundle, accept / decline / withdraw. Every call 404s bare until the
/// backend is deployed; the screens then say "being set up".
abstract class VendorBundlesApi {
  /// `GET /v1/bundles/mine?as=shop`.
  Future<Either<BundleFailure, List<VendorBundle>>> list();

  /// `GET /v1/bundles/{id}`.
  Future<Either<BundleFailure, VendorBundle>> get(String bundleId);

  /// `POST /v1/bundles/{id}/accept {termsVersion}` — 409
  /// `bundle_terms_changed` when the terms moved since they were shown.
  Future<Either<BundleFailure, VendorBundle>> accept(
    String bundleId, {
    required int termsVersion,
  });

  /// `POST /v1/bundles/{id}/decline {reason?}`.
  Future<Either<BundleFailure, VendorBundle>> decline(
    String bundleId, {
    String? reason,
  });

  /// `POST /v1/bundles/{id}/withdraw {reason?}` — pauses a Live bundle.
  Future<Either<BundleFailure, VendorBundle>> withdraw(
    String bundleId, {
    String? reason,
  });
}

class VendorBundlesApiImpl implements VendorBundlesApi {
  VendorBundlesApiImpl(this._api);

  final ApiClient _api;

  static const _base = '/v1/bundles';

  static String _id(String id) => Uri.encodeComponent(id);

  /// One Idempotency-Key per user action: each call is one tap.
  Options _write() => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': const Uuid().v4(),
    },
  );

  /// A write answers with the bundle; an empty body is re-read.
  Future<Either<BundleFailure, VendorBundle>> _answer(
    String bundleId,
    Future<dynamic> Function() call,
  ) => guardedBundleCall(() async {
    final body = await call();
    if (body is Map && (body['id'] != null || body['bundleId'] != null)) {
      return readVendorBundle(readJsonObject(body));
    }
    return readVendorBundle(
      readJsonObject(await _api.get('$_base/${_id(bundleId)}')),
    );
  });

  @override
  Future<Either<BundleFailure, List<VendorBundle>>> list() => guardedBundleCall(
    () async => readBundleList(
      await _api.get(
        '$_base/mine',
        queryParameters: <String, dynamic>{'as': 'shop'},
      ),
      readVendorBundle,
    ),
  );

  @override
  Future<Either<BundleFailure, VendorBundle>> get(String bundleId) =>
      guardedBundleCall(
        () async => readVendorBundle(
          readJsonObject(await _api.get('$_base/${_id(bundleId)}')),
        ),
      );

  @override
  Future<Either<BundleFailure, VendorBundle>> accept(
    String bundleId, {
    required int termsVersion,
  }) => _answer(
    bundleId,
    () => _api.post(
      '$_base/${_id(bundleId)}/accept',
      data: <String, dynamic>{'termsVersion': termsVersion},
      options: _write(),
    ),
  );

  @override
  Future<Either<BundleFailure, VendorBundle>> decline(
    String bundleId, {
    String? reason,
  }) => _answer(
    bundleId,
    () => _api.post(
      '$_base/${_id(bundleId)}/decline',
      data: <String, dynamic>{'reason': ?_blankToNull(reason)},
      options: _write(),
    ),
  );

  @override
  Future<Either<BundleFailure, VendorBundle>> withdraw(
    String bundleId, {
    String? reason,
  }) => _answer(
    bundleId,
    () => _api.post(
      '$_base/${_id(bundleId)}/withdraw',
      data: <String, dynamic>{'reason': ?_blankToNull(reason)},
      options: _write(),
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

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;

/// `BundleManageDto` (also reads the list's `BundleSummaryDto`, which may
/// carry fewer fields).
VendorBundle readVendorBundle(Map<String, dynamic> json) {
  final id = readString(json['id'] ?? json['bundleId']);
  if (id.isEmpty) throw const FormatException('bundle without id');
  final totals = _map(json['totals']) ?? json;
  final currency =
      readOptionalString(totals['currency']) ??
      readOptionalString(json['currency']) ??
      'NPR';
  final items = <VendorBundleItem>[
    if (json['items'] is List)
      for (final row in json['items'] as List)
        if (_map(row) case final m?)
          if (readString(m['id']).isNotEmpty)
            VendorBundleItem(
              id: readString(m['id']),
              productId: readString(m['productId']),
              vendorAccountId: readString(m['vendorAccountId']),
              title: readOptionalString(m['title']) ?? 'Item',
              thumbnailUrl: _media(m['thumbnailUrl']),
              quantity: readInt(m['quantity']) < 1 ? 1 : readInt(m['quantity']),
              listUnitPrice: readBundleMoney(m['listUnitPrice'], currency),
              bundleUnitPrice: readBundleMoney(m['bundleUnitPrice'], currency),
              commissionRatePercent: readOptionalDouble(
                m['commissionRatePercent'],
              ),
              shopFunds: m['shopFunds'] == null
                  ? null
                  : readBundleMoney(m['shopFunds'], currency),
              available: m['available'] is bool ? m['available'] as bool : true,
            ),
  ];
  final shops = <VendorBundleShop>[
    if (json['shops'] is List)
      for (final row in json['shops'] as List)
        if (_map(row) case final m?)
          VendorBundleShop(
            vendorAccountId: readString(m['vendorAccountId']),
            name: readOptionalString(m['name']) ?? 'Shop',
            state: VendorBundleShopState.fromWire(m['state']),
            acceptedTermsVersion: m['acceptedTermsVersion'] is num
                ? (m['acceptedTermsVersion'] as num).toInt()
                : null,
          ),
  ];
  final role = readString(json['myRole']).toLowerCase();
  final myFunds = json['myShopFunds'] ?? json['shopFunds'];
  return VendorBundle(
    id: id,
    title: readOptionalString(json['title']) ?? 'Bundle',
    coverImageUrl: _media(json['coverImageUrl']),
    ownerKind: VendorBundleOwnerKind.fromWire(json['ownerKind']),
    ownerAccountId: readOptionalString(json['ownerAccountId']),
    ownerName: readOptionalString(json['ownerName']),
    discountPercent: readOptionalDouble(json['discountPercent']) ?? 0,
    state: VendorBundleState.fromWire(json['state']),
    termsVersion: readInt(json['termsVersion']),
    pausedReason: VendorBundlePausedReason.fromWire(json['pausedReason']),
    isOwner: role == 'owner' || role == '1',
    myShopState: VendorBundleShopState.fromWire(json['myShopState']),
    myVendorAccountId: readOptionalString(json['myVendorAccountId']),
    myFundsTotal: myFunds == null ? null : readBundleMoney(myFunds, currency),
    shops: List.unmodifiable(shops),
    items: List.unmodifiable(items),
    listTotal: readBundleMoney(totals['listTotal'], currency),
    bundleTotal: readBundleMoney(totals['bundleTotal'], currency),
    updatedUtc: readDate(json['updatedUtc']),
  );
}

