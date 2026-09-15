import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/datasources/saved_for_later_api.dart';

/// Records every call. POST answers [postBody] or throws [postError].
class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(dio: Dio());

  final List<String> calls = [];
  final List<Object?> bodies = [];
  final List<Options?> sentOptions = [];
  Object? postBody;
  Exception? postError;

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add('POST $uri');
    bodies.add(data);
    sentOptions.add(options);
    final error = postError;
    if (error != null) throw error;
    return postBody;
  }

  @override
  Future<dynamic> authDelete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add('DELETE $uri');
    return null;
  }
}

void main() {
  late _RecordingApiClient client;
  late SavedForLaterRemoteApi api;

  setUp(() {
    client = _RecordingApiClient();
    api = SavedForLaterRemoteApi(client);
  });

  test('save posts the variant straight to the saved list', () async {
    client.postBody = {
      'id': 'saved-1',
      'productId': 'p-1',
      'productVariantId': 'v-1',
    };

    final entry = await api.save(productId: 'p-1', variantId: 'v-1');

    expect(client.calls, ['POST /v1/cart/saved-for-later']);
    expect(client.bodies.single, {
      'productVariantId': 'v-1',
      'productId': 'p-1',
    });
    final headers = client.sentOptions.single!.headers!;
    expect(headers['requiresToken'], isTrue);
    expect(headers['Idempotency-Key'], isA<String>());
    expect(
      entry,
      const SavedForLaterEntry(
        savedItemId: 'saved-1',
        productId: 'p-1',
        variantId: 'v-1',
      ),
    );
  });

  test('save never calls a cart route', () async {
    client.postBody = {
      'id': 'saved-1',
      'productId': 'p-1',
      'productVariantId': 'v-1',
    };

    await api.save(productId: 'p-1', variantId: 'v-1');

    expect(
      client.calls.where(
        (c) => c.contains('/v1/cart/lines') || c.contains('from-cart'),
      ),
      isEmpty,
    );
  });

  test('a body without a row keeps the caller ids', () async {
    final entry = await api.save(productId: 'p-1', variantId: 'v-1');

    expect(
      entry,
      const SavedForLaterEntry(
        savedItemId: '',
        productId: 'p-1',
        variantId: 'v-1',
      ),
    );
  });

  test('a failed save throws after the one request', () async {
    client.postError = Exception('404');

    await expectLater(
      api.save(productId: 'p-1', variantId: 'v-1'),
      throwsException,
    );
    expect(client.calls, ['POST /v1/cart/saved-for-later']);
  });

  test('remove deletes the saved row', () async {
    await api.remove('saved-1');

    expect(client.calls, ['DELETE /v1/cart/saved-for-later/saved-1']);
  });
}
