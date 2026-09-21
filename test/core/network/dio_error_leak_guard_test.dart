import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';

/// Dio's `DioException.message` is developer prose. For a 403 it reads:
///
///   "This exception was thrown because the response has a status code of 403
///    and RequestOptions.validateStatus was configured to throw for this
///    status code... Read more about status codes at
///    https://developer.mozilla.org/... In order to resolve this exception you
///    typically have either to verify and fix your request code or you have to
///    fix the server code."
///
/// `NetworkExceptions.server(msg)` renders `msg` straight to the user, so
/// `NetworkExceptions.server(e.message)` inside a repository puts that
/// paragraph — MDN link and all — on screen. It shipped that way in the
/// creator reel detail screen and was found by opening another creator's reel
/// on a device, not by any test.
///
/// 227 occurrences across 56 repositories were migrated to
/// `mapDioExceptionToNetworkException`. These tests keep it that way.
void main() {
  group('mapDioExceptionToNetworkException', () {
    DioException responseWith(int status, {Object? body}) => DioException(
      requestOptions: RequestOptions(path: '/v1/thing'),
      response: Response<Object?>(
        requestOptions: RequestOptions(path: '/v1/thing'),
        statusCode: status,
        data: body,
      ),
      // The real prose Dio attaches. If any mapping leaks `.message`, the
      // assertions below catch this string.
      message:
          'This exception was thrown because the response has a status code '
          'of $status and RequestOptions.validateStatus was configured to '
          'throw for this status code.',
    );

    test('403 becomes auth, not the raw message', () {
      final mapped = mapDioExceptionToNetworkException(responseWith(403));
      expect(mapped.isAuth, isTrue);
      expect(NetworkExceptions.getMessage(mapped), 'Authentication required.');
    });

    test('401 becomes auth', () {
      expect(mapDioExceptionToNetworkException(responseWith(401)).isAuth, isTrue);
    });

    test('404 becomes notFound', () {
      expect(
        mapDioExceptionToNetworkException(responseWith(404)).isNotFound,
        isTrue,
      );
    });

    test('a 409 satisfies isConflict', () {
      // The backend sends ErrorCodes.Conflict = 'state.conflict'. The mapper
      // turns a 409 into `.validation`, NOT `.conflict()`, so code that
      // pattern-matches the `conflict` union case alone never fires. Every
      // caller must use `isConflict`, which covers both shapes.
      final mapped = mapDioExceptionToNetworkException(
        responseWith(409, body: {'errorCode': 'state.conflict'}),
      );
      expect(mapped.isConflict, isTrue);
    });

    test('5xx becomes serverUnavailable and never echoes an HTML body', () {
      for (final status in [500, 502, 503, 504]) {
        final mapped = mapDioExceptionToNetworkException(
          responseWith(status, body: '<html><body>502 Bad Gateway</body></html>'),
        );
        expect(
          mapped.isServerUnavailable,
          isTrue,
          reason: '$status must be serverUnavailable',
        );
        expect(NetworkExceptions.getMessage(mapped), isNot(contains('html')));
      }
    });

    test('no mapped status leaks Dio prose to the user', () {
      for (final status in [400, 401, 403, 404, 409, 422, 429, 500, 503]) {
        final text = NetworkExceptions.getMessage(
          mapDioExceptionToNetworkException(responseWith(status)),
        );
        expect(
          text,
          isNot(contains('validateStatus')),
          reason: '$status leaked Dio internals',
        );
        expect(
          text,
          isNot(contains('developer.mozilla.org')),
          reason: '$status leaked an MDN link',
        );
        expect(
          text.toLowerCase(),
          isNot(contains('fix the server code')),
          reason: '$status told the user to fix the server',
        );
      }
    });

    test('a connection failure becomes noInternetConnection', () {
      final mapped = mapDioExceptionToNetworkException(
        DioException(
          requestOptions: RequestOptions(path: '/v1/thing'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(mapped.isNoInternet, isTrue);
    });
  });

  group('no repository rebuilds the leak by hand', () {
    /// Scans the source rather than behaviour, because the defect is a shape a
    /// developer reaches for by habit — there is no runtime seam that would
    /// catch it, and the 227 occurrences accumulated precisely because nothing
    /// objected.
    test('lib/ contains no NetworkExceptions.server(e.message ...)', () {
      final offenders = <String>[];
      final root = Directory('lib');

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File) continue;
        final path = entity.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart')) continue;
        if (path.endsWith('.freezed.dart') || path.endsWith('.g.dart')) {
          continue;
        }

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Skip comments — one file explains the rule in prose.
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
          if (line.contains('NetworkExceptions.server(e.message')) {
            offenders.add('$path:${i + 1}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'These put Dio\'s developer prose in front of the user. Use '
            'mapDioExceptionToNetworkException(e) instead:\n'
            '${offenders.join('\n')}',
      );
    });
  });
}
