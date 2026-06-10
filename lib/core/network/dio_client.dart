import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:stylemint_mobile_frontend/core/busy/busy_controller.dart';
import 'package:stylemint_mobile_frontend/core/config/api_config.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final busy = ref.read(busyControllerProvider.notifier);

  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
    headers: ApiConfig.defaultHeaders,
  ));

  dio.interceptors.addAll([
    // Outermost: drives the global busy indicator. begin() on request, end()
    // on the single terminal (response OR error) — balanced even through the
    // auth 401-refresh-retry path (which resolves via the response chain).
    _BusyInterceptor(onBegin: busy.begin, onEnd: busy.end),
    _IdempotencyInterceptor(),
    _CorrelationInterceptor(),
    _AuthInterceptor(tokenStorage: tokenStorage, baseUrl: ApiConfig.baseUrl),
  ]);

  // Pretty-print requests/responses in debug builds only; kept last so it
  // logs the final headers (auth token, idempotency/correlation ids).
  if (kDebugMode) {
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      maxWidth: 120,
      // Route through dart:developer so long JSON bodies aren't truncated or
      // dropped the way raw print() lines are on Android/iOS.
      logPrint: (obj) => developer.log(obj.toString(),name: ''),
    ));
  }

  return dio;
}

/// The single, app-wide [ApiClient] instance. Every feature's data source
/// depends on this provider so there is exactly one client (and one [Dio])
/// for the whole app.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(dio: ref.watch(dioClientProvider)),
);

/// Increments/decrements the global busy count around every request so the
/// app shows a "please wait" indicator while the network is in flight.
class _BusyInterceptor extends Interceptor {
  _BusyInterceptor({required this.onBegin, required this.onEnd});

  final void Function() onBegin;
  final void Function() onEnd;

  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    onBegin();
    handler.next(opts);
  }

  @override
  void onResponse(Response<dynamic> res, ResponseInterceptorHandler handler) {
    onEnd();
    handler.next(res);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    onEnd();
    handler.next(err);
  }
}

/// Attaches Idempotency-Key to every non-safe mutation.
/// NOTE: The key is set here only as a fallback; callers should pass it
/// via params so one key is generated per user tap, not per retry.
class _IdempotencyInterceptor extends Interceptor {
  static const _safeMethods = {'GET', 'HEAD', 'OPTIONS'};
  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    if (!_safeMethods.contains(opts.method.toUpperCase())) {
      opts.headers['Idempotency-Key'] ??= _uuid.v4();
    }
    handler.next(opts);
  }
}

/// Attaches X-Correlation-Id to every request for distributed tracing.
class _CorrelationInterceptor extends Interceptor {
  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    opts.headers['X-Correlation-Id'] ??= _uuid.v4();
    handler.next(opts);
  }
}

/// Attaches the access token to authenticated requests and transparently
/// refreshes it on a 401 using the stored refresh token (single-flight),
/// then replays the failed request once.
///
/// Requests opt out by setting the `requiresToken: false` header (used by the
/// login/refresh endpoints themselves).
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({required this.tokenStorage, required this.baseUrl});

  final TokenStorage tokenStorage;
  final String baseUrl;

  /// Bare client used only for the refresh call — never carries this
  /// interceptor, so a failed refresh can't recurse.
  late final Dio _refreshDio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Accept': 'application/json'},
  ));

  static const _retriedKey = 'auth_retried';
  Completer<String?>? _refreshing;

  bool _requiresToken(RequestOptions opts) => opts.headers['requiresToken'] != false;

  @override
  Future<void> onRequest(
    RequestOptions opts,
    RequestInterceptorHandler handler,
  ) async {
    final needsToken = _requiresToken(opts);
    opts.headers.remove('requiresToken');

    if (needsToken) {
      final token = await tokenStorage.accessToken;
      if (token != null && token.isNotEmpty) {
        opts.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(opts);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final opts = err.requestOptions;
    final alreadyRetried = opts.extra[_retriedKey] == true;

    if (response?.statusCode != 401 || alreadyRetried) {
      return handler.next(err);
    }
    if (!await tokenStorage.hasValidRefreshToken) {
      await tokenStorage.clear();
      return handler.next(err);
    }

    final newToken = await _refreshToken();
    if (newToken == null) {
      await tokenStorage.clear();
      return handler.next(err);
    }

    try {
      opts
        ..extra[_retriedKey] = true
        ..headers['Authorization'] = 'Bearer $newToken';
      final retried = await _refreshDio.fetch<dynamic>(opts);
      return handler.resolve(retried);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Single-flight refresh: concurrent 401s share one network call.
  Future<String?> _refreshToken() {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String?>();
    _refreshing = completer;
    _performRefresh().then(completer.complete).catchError((_) {
      completer.complete(null);
    }).whenComplete(() => _refreshing = null);
    return completer.future;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await tokenStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final res = await _refreshDio.post<dynamic>(
      '/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;

    final accessToken = data['accessToken'] as String?;
    await tokenStorage.saveSession(
      accessToken: accessToken,
      refreshToken: data['refreshToken'] as String?,
      accessExpiresUtc:
          DateTime.tryParse(data['accessExpiresUtc'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      refreshExpiresUtc:
          DateTime.tryParse(data['refreshExpiresUtc'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      accountId: data['accountId'] as String? ?? '',
      sessionId: data['sessionId'] as String? ?? '',
    );
    return accessToken;
  }
}
