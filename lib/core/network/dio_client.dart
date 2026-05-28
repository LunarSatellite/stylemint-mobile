import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5020',
  );

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  ));

  dio.interceptors.addAll([
    _IdempotencyInterceptor(),
    _CorrelationInterceptor(),
  ]);

  return dio;
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
