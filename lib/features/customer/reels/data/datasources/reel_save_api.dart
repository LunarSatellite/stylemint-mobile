import 'package:dio/dio.dart' show Options;
import 'package:flutter/foundation.dart' show immutable;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:uuid/uuid.dart';

/// `{ reelId, saved, saveCount }` from the reel save routes.
@immutable
class ReelSaveResult {
  const ReelSaveResult({
    required this.reelId,
    required this.saved,
    this.saveCount,
  });

  /// [requestedSaved] stands in when the body has no `saved` flag.
  factory ReelSaveResult.fromJson(
    Object? raw, {
    required String reelId,
    required bool requestedSaved,
  }) {
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final saved = json['saved'];
    final count = json['saveCount'];
    final id = readString(json['reelId']);
    return ReelSaveResult(
      reelId: id.isEmpty ? reelId : id,
      saved: saved is bool ? saved : requestedSaved,
      saveCount: count is num ? count.toInt() : null,
    );
  }

  final String reelId;
  final bool saved;
  final int? saveCount;
}

/// StyleMint reel saves (reels-contract.md §3). A save lives on StyleMint
/// only; nothing is sent to the reel's source platform.
abstract interface class ReelSaveApi {
  Future<ReelSaveResult> save(String reelId);

  Future<ReelSaveResult> unsave(String reelId);
}

class ReelSaveRemoteApi implements ReelSaveApi {
  ReelSaveRemoteApi(this._client);

  final ApiClient _client;

  static const _uuid = Uuid();

  /// POST `/v1/customer/reels/{reelId}/save` — idempotent.
  @override
  Future<ReelSaveResult> save(String reelId) async => ReelSaveResult.fromJson(
    await _client.post(
      '/v1/customer/reels/$reelId/save',
      options: _idempotent(),
    ),
    reelId: reelId,
    requestedSaved: true,
  );

  /// DELETE `/v1/customer/reels/{reelId}/save` — idempotent.
  @override
  Future<ReelSaveResult> unsave(String reelId) async => ReelSaveResult.fromJson(
    await _client.authDelete(
      '/v1/customer/reels/$reelId/save',
      options: _idempotent(),
    ),
    reelId: reelId,
    requestedSaved: false,
  );

  Options _idempotent() => Options(
    headers: {'requiresToken': true, 'Idempotency-Key': _uuid.v4()},
  );
}
