import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/data/composed_screen_parser.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/domain/composed_screen.dart';

/// One composer call's inputs.
@immutable
class ComposedScreenRequest {
  const ComposedScreenRequest(
    this.screen, {
    this.productIds = const [],
    this.context,
    this.limit,
    this.cursor,
  });

  final ComposedScreenName screen;
  final List<String> productIds;
  final String? context;
  final int? limit;
  final String? cursor;

  String get _identity =>
      '${screen.wire}|${productIds.join(',')}|$context|$limit|$cursor';

  @override
  bool operator ==(Object other) =>
      other is ComposedScreenRequest && other._identity == _identity;

  @override
  int get hashCode => _identity.hashCode;
}

/// The screen composer (`GET v1/customer/screens/{screen}` signed in,
/// `GET v1/public/screens/{screen}` for a guest).
///
/// The composer is optional: it ships disabled (`404`) and every caller
/// keeps its own screen. [load] therefore never throws — any failure is
/// null, and after a `404` the composer is not asked again this run.
class ComposedScreenRepository {
  ComposedScreenRepository({required this.apiClient});

  final ApiClient apiClient;
  bool _notDeployed = false;

  bool get notDeployed => _notDeployed;

  Future<ComposedScreen?> load(
    ComposedScreenRequest request, {
    required bool signedIn,
  }) async {
    if (_notDeployed) return null;
    final path = signedIn
        ? '/v1/customer/screens/${request.screen.wire}'
        : '/v1/public/screens/${request.screen.wire}';
    final query = <String, dynamic>{
      if (request.productIds.isNotEmpty) 'productId': request.productIds,
      'context': ?request.context,
      'limit': ?request.limit,
      'cursor': ?request.cursor,
    };
    try {
      final raw = signedIn
          ? await apiClient.get(path, queryParameters: query)
          : await apiClient.authGet(path, queryParameters: query);
      final json = readJsonObject(raw);
      final screen = parseComposedScreen(
        json,
        cards: await _hydrate(missingComposedCards(json)),
      );
      return screen.isEmpty ? null : screen;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) _notDeployed = true;
      return null;
    } on Object catch (_) {
      return null;
    }
  }

  /// The most ids `GET v1/public/cards` takes in one call.
  static const int maxCardsPerCall = 50;

  /// Fetches the cards the composer did not embed, [maxCardsPerCall] ids a
  /// call. A failed call hydrates nothing for its ids: those items are then
  /// dropped, as before.
  Future<ComposedCardLookup> _hydrate(
    List<(ComposedSectionKind, String)> missing,
  ) async {
    final out = <String, Map<String, Map<String, dynamic>>>{};
    for (var start = 0; start < missing.length; start += maxCardsPerCall) {
      final end = start + maxCardsPerCall < missing.length
          ? start + maxCardsPerCall
          : missing.length;
      final byKind = <String, List<String>>{};
      for (final (kind, id) in missing.sublist(start, end)) {
        (byKind[composedCardsKey(kind)] ??= []).add(id);
      }
      try {
        final raw = await apiClient.authGet(
          '/v1/public/cards',
          queryParameters: {
            for (final MapEntry(:key, :value) in byKind.entries)
              key: value.join(','),
          },
        );
        for (final MapEntry(:key, :value) in readComposedCards(raw).entries) {
          (out[key] ??= {}).addAll(value);
        }
      } on Object catch (_) {
        // Tolerated: these items stay without a card and are dropped.
      }
    }
    return out;
  }
}
