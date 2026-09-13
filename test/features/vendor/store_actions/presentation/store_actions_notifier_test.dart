import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/entities/store_actions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/repositories/store_actions_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/shared/providers.dart';

class _MockStoreActionsRepository extends Mock
    implements StoreActionsRepository {}

const _restock = StoreAction(
  kind: StoreActionKind.restockSoon,
  severity: StoreActionSeverity.high,
  productId: 'product-1',
  productName: 'Linen shirt',
  recommendation: 'Restock Linen shirt: about 2 days of stock left.',
);

const _queue = StoreActionQueue(actions: [_restock]);
const _empty = StoreActionQueue(actions: []);

StoreActionQueue? _loadedQueue(StoreActionsState state) => switch (state) {
  StoreActionsLoaded(:final queue) => queue,
  _ => null,
};

void main() {
  late _MockStoreActionsRepository repository;

  setUp(() => repository = _MockStoreActionsRepository());

  group('StoreActionsNotifier', () {
    test('starts loading and loads the queue on creation', () async {
      when(
        () => repository.getStoreActions(),
      ).thenAnswer((_) async => right(_queue));

      final notifier = StoreActionsNotifier(repository);
      addTearDown(notifier.dispose);
      expect(notifier.state, isA<StoreActionsLoading>());
      await pumpEventQueue();

      expect(_loadedQueue(notifier.state), same(_queue));
      verify(() => repository.getStoreActions()).called(1);
    });

    test('moves to failed on a repository error, and load() retries', () async {
      when(
        () => repository.getStoreActions(),
      ).thenAnswer(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );

      final notifier = StoreActionsNotifier(repository);
      addTearDown(notifier.dispose);
      await pumpEventQueue();

      final state = notifier.state;
      expect(state, isA<StoreActionsFailed>());
      expect(
        (state as StoreActionsFailed).failure,
        const NetworkExceptions.serverUnavailable(),
      );

      when(
        () => repository.getStoreActions(),
      ).thenAnswer((_) async => right(_empty));
      await notifier.load();

      expect(_loadedQueue(notifier.state), same(_empty));
    });

    test(
      'refresh keeps the current list on screen while re-checking',
      () async {
        when(
          () => repository.getStoreActions(),
        ).thenAnswer((_) async => right(_queue));
        final notifier = StoreActionsNotifier(repository);
        addTearDown(notifier.dispose);
        await pumpEventQueue();

        final pending =
            Completer<Either<NetworkExceptions, StoreActionQueue>>();
        when(
          () => repository.getStoreActions(),
        ).thenAnswer((_) => pending.future);
        final refreshing = notifier.refresh();

        expect(_loadedQueue(notifier.state), same(_queue));

        pending.complete(right(_empty));
        await refreshing;
        expect(_loadedQueue(notifier.state), same(_empty));
      },
    );

    test('a late response from an earlier load is discarded', () async {
      final first = Completer<Either<NetworkExceptions, StoreActionQueue>>();
      when(() => repository.getStoreActions()).thenAnswer((_) => first.future);
      final notifier = StoreActionsNotifier(repository); // first load pending
      addTearDown(notifier.dispose);

      when(
        () => repository.getStoreActions(),
      ).thenAnswer((_) async => right(_empty));
      await notifier.load();
      first.complete(right(_queue));
      await pumpEventQueue();

      expect(_loadedQueue(notifier.state), same(_empty));
    });
  });

  group('storeActionCountProvider', () {
    Future<int?> readCount() async {
      final container = ProviderContainer(
        overrides: [
          storeActionsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        storeActionCountProvider.future,
        (_, _) {},
      );
      return sub.read();
    }

    test('counts the actions', () async {
      when(
        () => repository.getStoreActions(),
      ).thenAnswer((_) async => right(_queue));

      expect(await readCount(), 1);
    });

    test('is null on a failure so the dashboard shows no number', () async {
      when(
        () => repository.getStoreActions(),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      expect(await readCount(), isNull);
    });

    test('is null when the repository throws', () async {
      when(() => repository.getStoreActions()).thenThrow(StateError('boom'));

      expect(await readCount(), isNull);
    });
  });
}
