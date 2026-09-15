import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';

/// One call an [ApiClient] received.
class RecordedCall {
  RecordedCall(this.method, this.uri, {this.data, this.query, this.options});

  final String method;
  final String uri;
  final Object? data;
  final Map<String, dynamic>? query;
  final Options? options;

  Object? header(String name) => options?.headers?[name];
}

/// Network-free [ApiClient] that records calls and answers each from
/// [respond]. An [Exception] answer is thrown, like a failed request.
class RecordingApiClient extends ApiClient {
  RecordingApiClient(this.respond) : super(dio: Dio());

  final Object? Function(RecordedCall call) respond;
  final List<RecordedCall> calls = [];

  RecordedCall get last => calls.last;

  Future<dynamic> _record(RecordedCall call) async {
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
  }) => _record(
    RecordedCall('GET', uri, query: queryParameters, options: options),
  );

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _record(
    RecordedCall(
      'POST',
      uri,
      data: data,
      query: queryParameters,
      options: options,
    ),
  );

  @override
  Future<dynamic> put(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _record(
    RecordedCall(
      'PUT',
      uri,
      data: data,
      query: queryParameters,
      options: options,
    ),
  );
}

class FakeNetworkInfo implements NetworkInfoConnectivity {
  FakeNetworkInfo({this.connected = true});

  final bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

/// A failed request with [status] (null for no response at all).
DioException dioError(int? status, {Object? body, String path = '/'}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: status == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: body,
          ),
  );
}
