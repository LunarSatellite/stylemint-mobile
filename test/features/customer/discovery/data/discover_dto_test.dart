import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discover_feed_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/discover_feed_dtos.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/search_suggestions_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discover_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/search_suggestions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(
          File(
            'test/features/customer/discovery/fixtures/$name',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

class _Online implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

typedef _Call = ({String method, String uri, Object? query, Object? data});

/// Records requests; answers with [respond], throwing it when it's an
/// exception.
class _RecordingApiClient extends ApiClient {
  _RecordingApiClient(this.respond) : super(dio: Dio());

  final Object? Function(_Call call) respond;
  final List<_Call> calls = [];

  Future<dynamic> _answer(_Call call) async {
    calls.add(call);
    final answer = respond(call);
    if (answer is Exception) throw answer;
    return answer;
  }

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _answer((method: 'GET', uri: uri, query: queryParameters, data: null));

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _answer((method: 'POST', uri: uri, query: queryParameters, data: data));

  @override
  Future<dynamic> authDelete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _answer((method: 'DELETE', uri: uri, query: queryParameters, data: data));
}

DioException _badRequest(String code) {
  final options = RequestOptions(path: '/api/v1/public/search/suggest');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: 400,
      data: {'errorCode': code, 'field': 'q', 'title': 'Query is too short'},
    ),
  );
}

(DiscoverRepositoryImpl, _RecordingApiClient) _repository(
  Object? Function(_Call call) respond,
) {
  final client = _RecordingApiClient(respond);
  return (
    DiscoverRepositoryImpl(
      remoteDataSource: DiscoverFeedRemoteDataSource(apiClient: client),
      networkInfo: _Online(),
    ),
    client,
  );
}

void main() {
  group('SearchSuggestionsDto', () {
    test('parses every group of the suggest contract', () {
      final suggestions = SearchSuggestionsDto.fromJson(
        _fixture('suggest_glow.json'),
      ).toDomain();

      expect(suggestions.query, 'glow');
      expect(suggestions.isEmpty, isFalse);
      // The row without an id is dropped.
      expect(suggestions.products.map((p) => p.name), [
        'GlowBloom Natural Face Oil',
        'Glow Serum',
      ]);
      expect(
        suggestions.products.first.imageUrl,
        'https://cdn.stylemint.test/p1.jpg',
      );
      expect(suggestions.products.first.price, isNull);
      expect(suggestions.products.last.price?.amount, 2400);
      expect(suggestions.brands.single.vendorAccountId, 'v-1');
      expect(suggestions.brands.single.isVerified, isTrue);
      expect(suggestions.creators.single.handle, 'glowwithasha');
      expect(suggestions.categories.single.slug, 'glow-skincare');
      expect(suggestions.hashtags.single.tag, 'glowup');
      expect(suggestions.hashtags.single.usageCount, 42);
    });

    test('missing groups read as empty', () {
      final suggestions = SearchSuggestionsDto.fromJson(const {
        'query': 'zz',
      }).toDomain();

      expect(suggestions.isEmpty, isTrue);
      expect(suggestions.hashtags, isEmpty);
    });

    test('the query is normalized like the server does', () {
      expect(normalizeSuggestQuery('  #Glow   Up '), 'glow up');
      expect(normalizeSuggestQuery('#g'), 'g');
    });
  });

  group('DiscoverRepositoryImpl', () {
    test('suggest sends the query and limit', () async {
      final (repository, client) = _repository(
        (_) => _fixture('suggest_glow.json'),
      );

      final result = await repository.suggest('glow');

      expect(result.isRight(), isTrue);
      expect(client.calls.single.uri, '/api/v1/public/search/suggest');
      expect(client.calls.single.query, {'q': 'glow', 'limit': 8});
    });

    test('a query under two characters is 400 validation.too_short', () async {
      final (repository, _) = _repository(
        (_) => _badRequest('validation.too_short'),
      );

      final result = await repository.suggest('g');

      expect(
        result.getLeft().toNullable()?.validationCode,
        'validation.too_short',
      );
    });

    test('not interested posts the kind name and undoes by path', () async {
      final (repository, client) = _repository((_) => null);
      const target = NotInterestedTarget(NotInterestedKind.creator, 'a 1');

      expect((await repository.markNotInterested(target)).isRight(), isTrue);
      expect((await repository.undoNotInterested(target)).isRight(), isTrue);

      expect(client.calls.first.method, 'POST');
      expect(client.calls.first.uri, '/api/v1/customer/feed/not-interested');
      expect(client.calls.first.data, {
        'targetKind': 'Creator',
        'targetId': 'a 1',
      });
      expect(client.calls.last.method, 'DELETE');
      expect(
        client.calls.last.uri,
        '/api/v1/customer/feed/not-interested/Creator/a%201',
      );
    });

    test('reads the not-interested list, dropping unknown kinds', () async {
      final (repository, _) = _repository(
        (_) => {
          'items': [
            {
              'targetKind': 'brand',
              'targetId': 'v-1',
              'reason': 'Too many posts like this',
              'createdUtc': '2026-09-15T12:00:00+00:00',
            },
            {'targetKind': 'Group', 'targetId': 'g-1'},
            {'targetKind': 'Reel', 'targetId': ''},
          ],
        },
      );

      final signals = (await repository.getNotInterested()).getOrElse(
        (_) => const [],
      );

      expect(
        signals.single.target,
        const NotInterestedTarget(
          NotInterestedKind.brand,
          'v-1',
        ),
      );
      expect(signals.single.reason, 'Too many posts like this');
      expect(signals.single.createdUtc, isNotNull);
    });

    test('reads a collections page and reports a reel', () async {
      final (repository, client) = _repository(
        (call) => call.method == 'GET'
            ? {
                'items': [
                  {
                    'slug': 'look-1',
                    'title': 'Weekend look',
                    'kind': 'Look',
                    'itemCount': 3,
                    'previewImageUrls': ['https://cdn.stylemint.test/a.jpg'],
                  },
                  {'slug': '', 'title': 'No slug'},
                ],
                'nextCursor': 'next',
              }
            : null,
      );

      final page = (await repository.getCollections()).getRight().toNullable();
      await repository.reportReel('r-1', ReelReportReason.counterfeit);

      expect(page?.nextCursor, 'next');
      expect(page?.items.single.kind, CollectionKind.look);
      expect(page?.items.single.previewImageUrls, hasLength(1));
      expect(client.calls.last.uri, '/v1/customer/reels/r-1/report');
      expect(client.calls.last.data, {'reasonCode': 'COUNTERFEIT_PRODUCT'});
    });
  });

  test('NotInterestedListDto ignores a body without items', () {
    expect(NotInterestedListDto.fromJson(const {}).toDomain(), isEmpty);
  });
}
