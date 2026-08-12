import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

/// Thin wrapper around a fully-configured [Dio] (base URL, timeouts,
/// interceptors all come from `dioClient`). Construct it through
/// `apiClientProvider` so the whole app shares one instance.
class ApiClient {
  ApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// GET request with token required
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        uri,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {'requiresToken': true}),
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// GET request without token
  Future<dynamic> authGet(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        uri,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {"requiresToken": false}),
        data: data,
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// POST request with token required
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {"requiresToken": true}),
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// POST request without token
  Future<dynamic> authPost(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {"requiresToken": false}),
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request with token required
  Future<dynamic> put(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {"requiresToken": true}),
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request without token
  Future<dynamic> authPut(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {"requiresToken": false}),
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// POST request with validation
  Future<dynamic> validatedPost(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      log(jsonEncode(data));
      final response = await _dio.post<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request with validation
  Future<dynamic> validatedPut(
    String uri, {
    dynamic data,
    String? token,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options ??
            Options(headers: {
              "requiresToken": false,
              if (token != null) 'Authorization': 'Bearer $token',
            }),
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH request with token required
  Future<dynamic> patch(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {"requiresToken": true}),
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request with token required
  Future<dynamic> authDelete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {"requiresToken": true}),
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// Raw POST response without extracting .data
  Future<Response<dynamic>> rawPost(
    String uri, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.post(uri, data: data, options: options);
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }

  /// POST a single file as `multipart/form-data`, with the bearer token.
  ///
  /// [fieldName] must match the parameter name the endpoint binds its
  /// `IFormFile` to — the backend's blob endpoints bind a parameter literally
  /// named `file`, so the part name is not cosmetic.
  ///
  /// Kept here rather than in a datasource so uploads inherit the shared
  /// interceptor stack (auth, retry, logging) like every other call. Dio sets
  /// the multipart boundary itself; do not set Content-Type by hand.
  Future<dynamic> postFile(
    String uri, {
    required File file,
    String fieldName = 'file',
    String? filename,
    Map<String, dynamic>? fields,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?fields,
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: filename ?? file.uri.pathSegments.last,
        ),
      });

      final response = await _dio.post<dynamic>(
        uri,
        data: formData,
        options: options ?? Options(headers: {'requiresToken': true}),
        onSendProgress: onSendProgress,
      );
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException("Unable to process the data");
    } catch (e) {
      rethrow;
    }
  }
}
