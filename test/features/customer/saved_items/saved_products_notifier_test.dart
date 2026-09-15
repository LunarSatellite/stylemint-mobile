import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/datasources/saved_for_later_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/notifiers/saved_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/saved_products_providers.dart';

class _FakeSavedApi implements SavedForLaterApi {
  List<SavedForLaterEntry> rows = [];
  Exception? saveError;
  Exception? removeError;

  /// When set, save and remove wait for it.
  Completer<void>? gate;
  int listCalls = 0;
  final List<(String, String)> saves = [];
  final List<String> removes = [];

  @override
  Future<List<SavedForLaterEntry>> list() async {
    listCalls++;
    return rows;
  }

  @override
  Future<SavedForLaterEntry> save({
    required String productId,
    required String variantId,
  }) async {
    saves.add((productId, variantId));
    await gate?.future;
    final error = saveError;
    if (error != null) throw error;
    return SavedForLaterEntry(
      savedItemId: 'saved-$productId',
      productId: productId,
      variantId: variantId,
    );
  }

  @override
  Future<void> remove(String savedItemId) async {
    removes.add(savedItemId);
    await gate?.future;
    final error = removeError;
    if (error != null) throw error;
  }
}

/// The real HTTP api's client: GET answers an empty list, POST answers
/// [postBody] or throws [postError].
class _RecordingClient extends ApiClient {
  _RecordingClient() : super(dio: Dio());

  final List<String> calls = [];
  final List<Object?> bodies = [];
  Object? postBody;
  Exception? postError;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add('GET $uri');
    return <Object>[];
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add('POST $uri');
    bodies.add(data);
    final error = postError;
    if (error != null) throw error;
    return postBody;
  }
}

const _savedShirt = SavedForLaterEntry(
  savedItemId: 'saved-shirt',
  productId: 'shirt',
  variantId: 'shirt-m',
);

void main() {
  late _FakeSavedApi api;
  late List<String> resolved;

  SavedProductsNotifier build({bool signedIn = true, String? defaultVariant}) =>
      SavedProductsNotifier(
        () => api,
        signedIn: signedIn,
        resolveDefaultVariant: (productId) async {
          resolved.add(productId);
          return defaultVariant;
        },
      );

  setUp(() {
    api = _FakeSavedApi()..rows = [_savedShirt];
    resolved = [];
  });

  test('reads the saved list once for a signed-in viewer', () async {
    final notifier = build();
    await pumpEventQueue();

    expect(api.listCalls, 1);
    expect(notifier.state.isLoaded, isTrue);
    expect(notifier.state.isSaved('shirt'), isTrue);
    expect(notifier.state.productIds, {'shirt'});
    expect(notifier.state.variantIds, {'shirt-m'});
  });

  test('a guest never reads the list', () async {
    final notifier = build(signedIn: false);
    await pumpEventQueue();

    expect(api.listCalls, 0);
    expect(notifier.state.isLoaded, isFalse);
    expect(notifier.state.entries, isEmpty);
  });

  test(
    'saving fills the heart at once and saves the default variant',
    () async {
      final notifier = build(defaultVariant: 'dress-s');
      await pumpEventQueue();
      api.gate = Completer<void>();

      final pending = notifier.toggle('dress');
      expect(notifier.state.isSaved('dress'), isTrue);
      expect(notifier.state.entries['dress']?.savedItemId, isEmpty);

      api.gate!.complete();
      expect(await pending, isTrue);
      expect(resolved, ['dress']);
      expect(api.saves, [('dress', 'dress-s')]);
      expect(notifier.state.entries['dress']?.savedItemId, 'saved-dress');
    },
  );

  test('a variant from the caller skips the lookup', () async {
    final notifier = build(defaultVariant: 'never');
    await pumpEventQueue();

    expect(await notifier.toggle('dress', variantId: 'dress-l'), isTrue);
    expect(resolved, isEmpty);
    expect(api.saves, [('dress', 'dress-l')]);
  });

  test('a failed save rolls the heart back', () async {
    final notifier = build(defaultVariant: 'dress-s');
    await pumpEventQueue();
    api.saveError = Exception('500');

    expect(await notifier.toggle('dress'), isFalse);
    expect(notifier.state.isSaved('dress'), isFalse);
  });

  test(
    'saving over HTTP posts once to the saved list and never the cart',
    () async {
      final client = _RecordingClient()
        ..postBody = {
          'id': 'saved-dress',
          'productId': 'dress',
          'productVariantId': 'dress-s',
        };
      final notifier = SavedProductsNotifier(
        () => SavedForLaterRemoteApi(client),
        signedIn: true,
        resolveDefaultVariant: (_) async => 'dress-s',
      );
      await pumpEventQueue();

      expect(await notifier.toggle('dress'), isTrue);
      expect(notifier.state.isSaved('dress'), isTrue);
      expect(notifier.state.entries['dress']?.savedItemId, 'saved-dress');
      expect(client.calls, [
        'GET /v1/cart/saved-for-later',
        'POST /v1/cart/saved-for-later',
      ]);
      expect(client.bodies.single, {
        'productVariantId': 'dress-s',
        'productId': 'dress',
      });
    },
  );

  test('a rejected HTTP save rolls the heart back', () async {
    final client = _RecordingClient()..postError = Exception('404');
    final notifier = SavedProductsNotifier(
      () => SavedForLaterRemoteApi(client),
      signedIn: true,
      resolveDefaultVariant: (_) async => 'dress-s',
    );
    await pumpEventQueue();

    expect(await notifier.toggle('dress'), isFalse);
    expect(notifier.state.isSaved('dress'), isFalse);
    expect(client.calls, [
      'GET /v1/cart/saved-for-later',
      'POST /v1/cart/saved-for-later',
    ]);
  });

  test('a product without a variant is not saved', () async {
    final notifier = build();
    await pumpEventQueue();

    expect(await notifier.toggle('dress'), isFalse);
    expect(api.saves, isEmpty);
    expect(notifier.state.isSaved('dress'), isFalse);
  });

  test('unsaving empties the heart at once and deletes the row', () async {
    final notifier = build();
    await pumpEventQueue();
    api.gate = Completer<void>();

    final pending = notifier.toggle('shirt');
    expect(notifier.state.isSaved('shirt'), isFalse);

    api.gate!.complete();
    expect(await pending, isTrue);
    expect(api.removes, ['saved-shirt']);
  });

  test('a failed unsave puts the row back', () async {
    final notifier = build();
    await pumpEventQueue();
    api.removeError = Exception('offline');

    expect(await notifier.toggle('shirt'), isFalse);
    expect(notifier.state.entries['shirt'], _savedShirt);
  });

  test('a second tap while saving is ignored', () async {
    final notifier = build(defaultVariant: 'dress-s');
    await pumpEventQueue();
    api.gate = Completer<void>();

    final first = notifier.toggle('dress');
    expect(await notifier.toggle('dress'), isTrue);
    api.gate!.complete();
    await first;

    expect(api.saves, hasLength(1));
    expect(notifier.state.isSaved('dress'), isTrue);
  });

  test('a list that arrives late keeps what the viewer just toggled', () async {
    api.rows = [];
    final listGate = Completer<List<SavedForLaterEntry>>();
    final notifier = SavedProductsNotifier(
      () => _LateListApi(api, listGate.future),
      signedIn: true,
      resolveDefaultVariant: (_) async => 'dress-s',
    );

    await notifier.toggle('dress');
    listGate.complete([_savedShirt]);
    await pumpEventQueue();

    expect(notifier.state.productIds, {'shirt', 'dress'});
  });

  test('every reader shares one saved state', () async {
    final container = ProviderContainer(
      overrides: [
        savedForLaterApiProvider.overrideWithValue(api),
        savedProductsSignedInProvider.overrideWithValue(true),
        savedProductsVariantResolverProvider.overrideWithValue(
          (_) async => 'dress-s',
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(savedProductsNotifierProvider);
    await pumpEventQueue();

    await container
        .read(savedProductsNotifierProvider.notifier)
        .toggle('dress');

    expect(
      container.read(savedProductsNotifierProvider).productIds,
      {'shirt', 'dress'},
    );
    expect(api.saves, [('dress', 'dress-s')]);
  });
}

class _LateListApi implements SavedForLaterApi {
  _LateListApi(this._inner, this._list);

  final _FakeSavedApi _inner;
  final Future<List<SavedForLaterEntry>> _list;

  @override
  Future<List<SavedForLaterEntry>> list() => _list;

  @override
  Future<SavedForLaterEntry> save({
    required String productId,
    required String variantId,
  }) => _inner.save(productId: productId, variantId: variantId);

  @override
  Future<void> remove(String savedItemId) => _inner.remove(savedItemId);
}
