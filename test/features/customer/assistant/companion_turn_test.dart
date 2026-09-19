import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/datasources/assistant_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/models/companion_turn_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/models/suggested_product_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';

import 'assistant_fixtures.dart';

/// Captures what the repository asked the network for, so the idempotency
/// key and the call count can be asserted exactly.
class _RecordingApiClient implements ApiClient {
  /// Set to make the next POST fail, so a retry can be observed.
  bool failPostsOnce = false;
  final List<({String path, Object? data, String? key})> posts = [];
  final List<String> gets = [];

  /// productId -> payload. A missing id throws, as a 404 would.
  Map<String, Map<String, dynamic>> products = {};

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    gets.add(uri);
    for (final entry in products.entries) {
      if (uri.endsWith(entry.key)) return entry.value;
    }
    throw DioException(
      requestOptions: RequestOptions(path: uri),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: uri),
        statusCode: 404,
      ),
    );
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    posts.add((
      path: uri,
      data: data,
      key: options?.headers?['Idempotency-Key'] as String?,
    ));
    if (failPostsOnce) {
      failPostsOnce = false;
      throw DioException(
        requestOptions: RequestOptions(path: uri),
        type: DioExceptionType.connectionError,
      );
    }
    final body = data as Map<String, dynamic>;
    return {
      'conversationId': 'conv-1',
      'messageId': 'm-1',
      'productId': body['productId'],
      'quantity': body['quantity'],
      'cartItemCount': 4,
      'addedUtc': '2026-09-19T08:05:00Z',
      'receiptTurn': turnJson(
        id: 's-1',
        role: 'system',
        message: 'Added to your bag.',
      ),
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not used: ${invocation.memberName}');
}

void main() {
  group('turn parsing', () {
    test('splits, trims and de-duplicates the suggested id string', () {
      final turn = turnFrom(
        id: 'm-1',
        role: 'minty',
        message: 'Two ideas',
        suggested: ' $productA , $productB ,, ${productA.toUpperCase()} ',
      );
      expect(turn.suggestedProductIds, [productA, productB]);
    });

    test('a user turn never carries suggestions, whatever the wire says', () {
      final turn = turnFrom(
        id: 'u-1',
        role: 'user',
        message: 'I need a coat',
        suggested: '$productA,$productB',
      );
      expect(turn.suggestedProductIds, isEmpty);
      expect(turn.hasSuggestions, isFalse);
      expect(turn.suggests(productA), isFalse);
    });

    test('suggests() is true only for an id this turn actually named', () {
      final turn = turnFrom(
        id: 'm-1',
        role: 'minty',
        message: 'One idea',
        suggested: productA,
      );
      expect(turn.suggests(productA), isTrue);
      expect(turn.suggests(productA.toUpperCase()), isTrue);
      expect(turn.suggests(productB), isFalse);
      expect(turn.suggests(''), isFalse);
    });

    test('mood and contextType stay numeric, as the wire sends them', () {
      final turn = companionTurnFromJson(
        turnJson(
          id: 'm-1',
          role: 'minty',
          message: 'Hello',
          mood: 4,
          contextType: 11,
        ),
      );
      expect(turn.mood, 4);
      expect(turn.contextType, 11);
    });
  });

  group('suggested product resolution', () {
    Map<String, dynamic> productJson(String id, String name) => {
      'id': id,
      'name': name,
      'vendorDisplayName': 'Tundra',
      'averageRating': 4.5,
      'reviewCount': 12,
      'images': [
        {'url': 'https://example.test/a.jpg', 'sortOrder': 0},
      ],
      'variants': [
        {
          'id': 'v-1',
          'isDefault': true,
          'priceAmount': 2499.0,
          'priceCurrency': 'NPR',
          'trackInventory': true,
          'quantityOnHand': 5,
        },
      ],
    };

    test('an unresolvable suggestion is omitted, never stubbed', () async {
      final api = _RecordingApiClient()
        ..products = {productA: productJson(productA, 'Field coat')};
      final repository = AssistantRepositoryImpl(
        remoteDataSource: AssistantRemoteDataSource(apiClient: api),
      );
      final turn = turnFrom(
        id: 'm-1',
        role: 'minty',
        message: 'Two ideas',
        suggested: '$productA,$ghostProduct',
      );

      final products = await repository.resolveSuggestions(turn);

      expect(products.map((p) => p.id), [productA]);
      expect(
        products.single.name,
        'Field coat',
        reason: 'the one that resolved keeps its real name',
      );
      expect(
        products.any((p) => p.id == ghostProduct),
        isFalse,
        reason: 'no placeholder card for a product that does not exist',
      );
    });

    test('a payload with no name does not become a card', () {
      expect(
        suggestedProductFromJson({
          'id': productA,
          'name': '   ',
        }, fallbackId: productA),
        isNull,
      );
    });

    test('a user turn resolves to nothing at all', () async {
      final api = _RecordingApiClient()
        ..products = {productA: productJson(productA, 'Field coat')};
      final repository = AssistantRepositoryImpl(
        remoteDataSource: AssistantRemoteDataSource(apiClient: api),
      );
      final turn = turnFrom(
        id: 'u-1',
        role: 'user',
        message: 'I want that',
        suggested: productA,
      );

      expect(await repository.resolveSuggestions(turn), isEmpty);
      expect(api.gets, isEmpty, reason: 'it should not even ask');
    });
  });

  group('adding a suggested product', () {
    late _RecordingApiClient api;
    late AssistantRepositoryImpl repository;
    late CompanionTurn suggestion;

    setUp(() {
      api = _RecordingApiClient();
      repository = AssistantRepositoryImpl(
        remoteDataSource: AssistantRemoteDataSource(apiClient: api),
      );
      suggestion = turnFrom(
        id: 'm-1',
        role: 'minty',
        message: 'This one',
        suggested: productA,
      );
    });

    test('calls cart-additions exactly once with the caller key', () async {
      final result = await repository.addSuggestedProductToCart(
        conversationId: 'conv-1',
        turn: suggestion,
        productId: productA,
        idempotencyKey: 'key-1',
      );

      expect(result.isRight(), isTrue);
      expect(api.posts, hasLength(1));
      expect(api.posts.single.path, contains('/cart-additions'));
      expect(api.posts.single.key, 'key-1');
      expect(
        (api.posts.single.data! as Map<String, dynamic>)['messageId'],
        'm-1',
        reason: 'the add is pinned to the turn that suggested it',
      );
    });

    test('a retry of the same decision reuses the idempotency key', () async {
      api.failPostsOnce = true;
      final first = await repository.addSuggestedProductToCart(
        conversationId: 'conv-1',
        turn: suggestion,
        productId: productA,
        idempotencyKey: 'key-1',
      );
      expect(first.isLeft(), isTrue);

      final second = await repository.addSuggestedProductToCart(
        conversationId: 'conv-1',
        turn: suggestion,
        productId: productA,
        idempotencyKey: 'key-1',
      );

      expect(second.isRight(), isTrue);
      expect(api.posts.map((p) => p.key), ['key-1', 'key-1']);
    });

    test(
      'a product the turn did not suggest never reaches the network',
      () async {
        final result = await repository.addSuggestedProductToCart(
          conversationId: 'conv-1',
          turn: suggestion,
          productId: productB,
          idempotencyKey: 'key-1',
        );

        expect(api.posts, isEmpty);
        expect(
          result.fold((f) => f.validationCode, (_) => null),
          AssistantRepositoryImpl.notSuggestedCode,
        );
      },
    );

    test("the customer's own turn can never be approved", () async {
      final userTurn = turnFrom(
        id: 'u-1',
        role: 'user',
        message: 'add that',
        suggested: productA,
      );

      final result = await repository.addSuggestedProductToCart(
        conversationId: 'conv-1',
        turn: userTurn,
        productId: productA,
        idempotencyKey: 'key-1',
      );

      expect(api.posts, isEmpty);
      expect(
        result.fold((f) => f.validationCode, (_) => null),
        AssistantRepositoryImpl.notSuggestedCode,
      );
    });

    test('quantity is clamped into the 1..10 the API accepts', () async {
      await repository.addSuggestedProductToCart(
        conversationId: 'conv-1',
        turn: suggestion,
        productId: productA,
        idempotencyKey: 'key-1',
        quantity: 99,
      );
      expect(
        (api.posts.single.data! as Map<String, dynamic>)['quantity'],
        10,
      );
    });
  });
}
