import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/repositories/reel_import_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/content_freshness.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

const _path = '/v1/social/accounts/instagram/content';

/// Answers GET with [body], or throws [error] when set.
class _ApiClient extends ApiClient {
  _ApiClient({this.body, this.error}) : super(dio: Dio());

  final Object? body;
  final DioException? error;
  int calls = 0;
  Map<String, dynamic>? query;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls++;
    query = queryParameters;
    final failure = error;
    if (failure != null) throw failure;
    return body;
  }
}

class _Network implements NetworkInfoConnectivity {
  _Network({this.online = true});

  final bool online;

  @override
  Future<bool> get isConnected async => online;
}

DioException _errorResponse(int status, Map<String, dynamic> body) {
  final request = RequestOptions(path: _path);
  return DioException(
    requestOptions: request,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: status,
      data: body,
    ),
    type: DioExceptionType.badResponse,
  );
}

ReelImportRepositoryImpl _repository(_ApiClient api, {bool online = true}) =>
    ReelImportRepositoryImpl(
      remoteDataSource: ReelImportRemoteDataSource(apiClient: api),
      networkInfo: _Network(online: online),
    );

Future<NetworkExceptions> _failureFor(int status, String errorCode) async {
  final api = _ApiClient(
    error: _errorResponse(status, {
      'type': 'about:blank',
      'title': 'Provider said no.',
      'status': status,
      'errorCode': errorCode,
    }),
  );
  final result = await _repository(api).getImportableReels(
    SocialPlatform.instagram,
  );
  return result.fold((failure) => failure, (_) => fail('expected a failure'));
}

Map<String, dynamic> _item(String id, {required int duration}) => {
  'externalId': id,
  'permalink': 'https://www.instagram.com/reel/$id/',
  'caption': '',
  'thumbnailUrl': '',
  'publishedUtc': '2026-09-10T08:00:00Z',
  'durationSeconds': duration,
};

void main() {
  group('content listing error codes', () {
    test('RATE_LIMITED keeps its code instead of a generic server error',
        () async {
      final failure = await _failureFor(400, 'RATE_LIMITED');

      expect(failure.validationCode, 'RATE_LIMITED');
      expect(NetworkExceptions.getMessage(failure), 'Provider said no.');
      expect(
        ContentProviderIssue.fromCode(failure.validationCode),
        ContentProviderIssue.rateLimited,
      );
    });

    const expectations = {
      'PROVIDER_UNAVAILABLE': ContentProviderIssue.unavailable,
      'TOKEN_INVALID': ContentProviderIssue.reconnect,
      'TOKEN_EXPIRED': ContentProviderIssue.reconnect,
      'INVALID_GRANT': ContentProviderIssue.reconnect,
      'SCOPE_NARROWED': ContentProviderIssue.reconnect,
      'PERMISSION_MISSING': ContentProviderIssue.permissionMissing,
    };
    for (final entry in expectations.entries) {
      test('${entry.key} maps to ${entry.value.name}', () async {
        final failure = await _failureFor(400, entry.key);

        expect(failure.validationCode, entry.key);
        expect(
          ContentProviderIssue.fromCode(failure.validationCode),
          entry.value,
        );
      });
    }

    test('404 resource.not_found is not connected', () async {
      final failure = await _failureFor(404, 'resource.not_found');

      expect(failure.isNotFound, isTrue);
    });

    test('resource.not_found is not connected whatever the status', () async {
      final failure = await _failureFor(400, 'resource.not_found');

      expect(failure.isNotFound, isTrue);
    });

    test('validation codes are kept but are not provider issues', () async {
      final failure = await _failureFor(400, 'validation.out_of_range');

      expect(failure.validationCode, 'validation.out_of_range');
      expect(ContentProviderIssue.fromCode(failure.validationCode), isNull);
    });

    test('a 5xx is a retryable unavailable error', () async {
      final api = _ApiClient(error: _errorResponse(503, const {}));

      final result = await _repository(api).getImportableReels(
        SocialPlatform.instagram,
      );

      expect(
        result.fold((f) => f.isServerUnavailable, (_) => false),
        isTrue,
      );
    });

    test('offline fails without calling the API', () async {
      final api = _ApiClient(body: const {'items': <dynamic>[]});

      final result = await _repository(api, online: false).getImportableReels(
        SocialPlatform.instagram,
      );

      expect(result.fold((f) => f.isNoInternet, (_) => false), isTrue);
      expect(api.calls, 0);
    });
  });

  group('content listing success', () {
    test('maps freshness, forwards refresh and hides zero-duration posts',
        () async {
      final api = _ApiClient(
        body: {
          'items': [
            _item('video', duration: 20),
            _item('photo', duration: 0),
          ],
          'nextCursor': 'sm1.next',
          'servedFromCache': true,
          'fetchedUtc': '2026-09-14T15:10:00Z',
          'staleSinceUtc': null,
          'providerStatus': {
            'code': 'PROVIDER_UNAVAILABLE',
            'message': 'Instagram could not be reached right now.',
            'retryAfterUtc': '2026-09-14T15:30:00Z',
          },
        },
      );

      final result = await _repository(api).getImportableReels(
        SocialPlatform.instagram,
        refresh: true,
      );
      final page = result.fold<ImportableReelsResult?>((_) => null, (p) => p)!;

      expect(api.query, containsPair('refresh', true));
      expect(page.reels.map((r) => r.platformPostId), ['video']);
      expect(page.nextCursor, 'sm1.next');
      expect(page.freshness.servedFromCache, isTrue);
      expect(page.freshness.fetchedUtc, DateTime.utc(2026, 9, 14, 15, 10));
      expect(
        page.freshness.providerStatus,
        ContentProviderStatus(
          code: 'PROVIDER_UNAVAILABLE',
          message: 'Instagram could not be reached right now.',
          retryAfterUtc: DateTime.utc(2026, 9, 14, 15, 30),
        ),
      );
    });
  });
}
