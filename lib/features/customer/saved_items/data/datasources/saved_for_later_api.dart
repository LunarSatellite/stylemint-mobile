import 'package:dio/dio.dart' show Options;
import 'package:flutter/foundation.dart' show immutable;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:uuid/uuid.dart';

/// One row of the viewer's saved-for-later list (backend
/// `SavedForLaterItemDto`: `{ id, productId, productVariantId, … }`).
@immutable
class SavedForLaterEntry {
  const SavedForLaterEntry({
    required this.savedItemId,
    required this.productId,
    required this.variantId,
  });

  factory SavedForLaterEntry.fromJson(Map<String, dynamic> json) =>
      SavedForLaterEntry(
        savedItemId: readString(json['id']),
        productId: readString(json['productId']),
        variantId: readString(json['productVariantId']),
      );

  /// The bare list `GET /v1/cart/saved-for-later` returns. Rows without a row
  /// id or product id are dropped.
  static List<SavedForLaterEntry> listFromJson(Object? raw) =>
      [
            if (raw is List)
              for (final item in raw)
                if (item is Map<String, dynamic>)
                  SavedForLaterEntry.fromJson(item),
          ]
          .where((e) => e.savedItemId.isNotEmpty && e.productId.isNotEmpty)
          .toList(
            growable: false,
          );

  /// Empty while the save request is still in flight.
  final String savedItemId;
  final String productId;
  final String variantId;

  @override
  bool operator ==(Object other) =>
      other is SavedForLaterEntry &&
      other.savedItemId == savedItemId &&
      other.productId == productId &&
      other.variantId == variantId;

  @override
  int get hashCode => Object.hash(savedItemId, productId, variantId);
}

/// The saved-for-later calls behind the save heart.
abstract interface class SavedForLaterApi {
  Future<List<SavedForLaterEntry>> list();

  Future<SavedForLaterEntry> save({
    required String productId,
    required String variantId,
  });

  Future<void> remove(String savedItemId);
}

/// `/v1/cart/saved-for-later` over HTTP.
///
/// Saving posts the variant straight to the list
/// (`POST /v1/cart/saved-for-later`). The cart is never touched, and saving a
/// variant that is already saved returns the existing row.
class SavedForLaterRemoteApi implements SavedForLaterApi {
  SavedForLaterRemoteApi(this._client);

  final ApiClient _client;

  static const _uuid = Uuid();

  @override
  Future<List<SavedForLaterEntry>> list() async =>
      SavedForLaterEntry.listFromJson(
        await _client.get('/v1/cart/saved-for-later'),
      );

  @override
  Future<SavedForLaterEntry> save({
    required String productId,
    required String variantId,
  }) async {
    final saved = await _client.post(
      '/v1/cart/saved-for-later',
      data: {'productVariantId': variantId, 'productId': productId},
      options: _idempotent(),
    );
    final row = saved is Map<String, dynamic>
        ? SavedForLaterEntry.fromJson(saved)
        : null;
    return SavedForLaterEntry(
      savedItemId: row?.savedItemId ?? '',
      productId: productId,
      variantId: row == null || row.variantId.isEmpty
          ? variantId
          : row.variantId,
    );
  }

  @override
  Future<void> remove(String savedItemId) async {
    await _client.authDelete(
      '/v1/cart/saved-for-later/$savedItemId',
      options: _idempotent(),
    );
  }

  Options _idempotent() => Options(
    headers: {'requiresToken': true, 'Idempotency-Key': _uuid.v4()},
  );
}
