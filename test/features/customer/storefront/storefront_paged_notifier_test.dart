import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_page.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/notifiers/storefront_paged_notifier.dart';

import 'storefront_test_support.dart';

typedef _Result = Either<NetworkExceptions, StorefrontPage<String>>;

void main() {
  late Map<String?, List<_Result>> pages;
  late List<String?> cursors;

  StorefrontPagedNotifier<String> create({bool loadOnCreate = true}) =>
      StorefrontPagedNotifier<String>(
        (cursor) async {
          cursors.add(cursor);
          final queue = pages[cursor];
          if (queue == null || queue.isEmpty) {
            return left(const NetworkExceptions.notFound());
          }
          return queue.length == 1 ? queue.first : queue.removeAt(0);
        },
        idOf: (item) => item,
        loadOnCreate: loadOnCreate,
      );

  StorefrontPagedLoaded<String> loaded(StorefrontPagedNotifier<String> n) =>
      currentState(n) as StorefrontPagedLoaded<String>;

  setUp(() {
    pages = {};
    cursors = [];
  });

  test('loads the first page on creation', () async {
    pages[null] = [
      right(page(['a', 'b'], next: 'c1')),
    ];
    final notifier = create();
    expect(currentState(notifier), isA<StorefrontPagedLoading<String>>());

    await flushMicrotasks();

    final state = loaded(notifier);
    expect(state.items, ['a', 'b']);
    expect(state.hasMore, isTrue);
    expect(state.canLoadMore, isTrue);
    expect(state.isEmpty, isFalse);
  });

  test('loadMore appends each item once and stops on the last page', () async {
    pages[null] = [
      right(page(['a', 'b'], next: 'c1')),
    ];
    pages['c1'] = [
      right(page(['b', 'c'])),
    ];
    final notifier = create();
    await flushMicrotasks();

    await notifier.loadMore();
    expect(loaded(notifier).items, ['a', 'b', 'c']);
    expect(loaded(notifier).hasMore, isFalse);

    await notifier.loadMore();
    expect(cursors, [null, 'c1']);
  });

  test('ignores loadMore while a page is loading', () async {
    pages[null] = [
      right(page(['a'], next: 'c1')),
    ];
    pages['c1'] = [
      right(page(['b'])),
    ];
    final notifier = create();
    await flushMicrotasks();

    final first = notifier.loadMore();
    expect(loaded(notifier).isLoadingMore, isTrue);
    await notifier.loadMore();
    await first;

    expect(cursors.where((c) => c == 'c1'), hasLength(1));
    expect(loaded(notifier).items, ['a', 'b']);
  });

  test('a failed first page is a failure; refresh recovers', () async {
    pages[null] = [
      left(const NetworkExceptions.noInternetConnection()),
      right(page(['a'])),
    ];
    final notifier = create();
    await flushMicrotasks();
    expect(currentState(notifier), isA<StorefrontPagedFailure<String>>());

    await notifier.refresh();
    expect(loaded(notifier).items, ['a']);
  });

  test('a failed next page keeps the items and waits for retry', () async {
    pages[null] = [
      right(page(['a'], next: 'c1')),
    ];
    pages['c1'] = [
      left(const NetworkExceptions.serverUnavailable()),
      right(page(['b'])),
    ];
    final notifier = create();
    await flushMicrotasks();

    await notifier.loadMore();
    expect(loaded(notifier).items, ['a']);
    expect(loaded(notifier).loadMoreFailed, isTrue);
    expect(loaded(notifier).canLoadMore, isFalse);

    await notifier.loadMore();
    expect(cursors.where((c) => c == 'c1'), hasLength(1));

    await notifier.retryLoadMore();
    expect(loaded(notifier).items, ['a', 'b']);
    expect(loaded(notifier).loadMoreFailed, isFalse);
  });

  test('follows pages the server left empty while a cursor remains', () async {
    pages[null] = [right(page(const <String>[], next: 'c1'))];
    pages['c1'] = [right(page(const <String>[], next: 'c2'))];
    pages['c2'] = [
      right(page(['a'])),
    ];
    final notifier = create(loadOnCreate: false);

    await notifier.refresh();

    expect(cursors, [null, 'c1', 'c2']);
    expect(loaded(notifier).items, ['a']);
  });

  test('an empty last page is empty', () async {
    pages[null] = [right(page(const <String>[]))];
    final notifier = create(loadOnCreate: false);
    await notifier.refresh();
    expect(loaded(notifier).isEmpty, isTrue);
  });
}
