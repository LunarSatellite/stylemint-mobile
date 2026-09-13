import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/repositories/sponsored_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/sponsored_products_errors.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/shared/providers.dart';

class _MockRepository extends Mock implements SponsoredProductsRepository {}

SponsoredListing _listing(
  String productId, {
  SponsoredListingState state = SponsoredListingState.active,
  bool isLive = true,
  int cap = 500,
}) => SponsoredListing(
  id: 'listing-$productId',
  productId: productId,
  productName: 'Product $productId',
  state: state,
  isLive: isLive,
  dailyImpressionCap: cap,
);

final SponsoredListing _shirt = _listing('p-1');
final SponsoredListing _tote = _listing('p-2');

List<SponsoredListing>? _listings(SponsoredProductsState state) =>
    switch (state) {
      SponsoredProductsLoaded(:final listings) => listings,
      _ => null,
    };

Set<String>? _pausing(SponsoredProductsState state) => switch (state) {
  SponsoredProductsLoaded(:final pausing) => pausing,
  _ => null,
};

const _conflict = NetworkExceptions.validation(
  code: sponsorshipConflictCode,
  message: 'This product is already being sponsored.',
);

const _ruleViolation = NetworkExceptions.validation(
  code: 'rule.violation',
  message: 'Only live products can be sponsored.',
);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(DateTime.utc(2000)));

  setUp(() => repository = _MockRepository());

  void stubList(
    List<Either<NetworkExceptions, List<SponsoredListing>>> answers,
  ) {
    var call = 0;
    when(() => repository.getSponsoredListings()).thenAnswer((_) async {
      final answer = answers[call < answers.length ? call : answers.length - 1];
      call++;
      return answer;
    });
  }

  void stubSponsor(Either<NetworkExceptions, SponsoredListing> answer) {
    when(
      () => repository.sponsor(
        productId: any(named: 'productId'),
        dailyImpressionCap: any(named: 'dailyImpressionCap'),
        endsUtc: any(named: 'endsUtc'),
      ),
    ).thenAnswer((_) async => answer);
  }

  Future<SponsoredProductsNotifier> loaded() async {
    final notifier = SponsoredProductsNotifier(repository);
    addTearDown(notifier.dispose);
    await pumpEventQueue();
    return notifier;
  }

  group('load and refresh', () {
    test('starts loading and loads the list on creation', () async {
      stubList([
        right([_shirt, _tote]),
      ]);

      final notifier = SponsoredProductsNotifier(repository);
      addTearDown(notifier.dispose);
      expect(notifier.state, isA<SponsoredProductsLoading>());
      await pumpEventQueue();

      expect(_listings(notifier.state), [_shirt, _tote]);
      verify(() => repository.getSponsoredListings()).called(1);
    });

    test('fails on an error, and load() retries', () async {
      stubList([
        left(const NetworkExceptions.serverUnavailable()),
        right([_shirt]),
      ]);

      final notifier = await loaded();
      final state = notifier.state;
      expect(state, isA<SponsoredProductsFailed>());
      expect(
        (state as SponsoredProductsFailed).failure,
        const NetworkExceptions.serverUnavailable(),
      );

      await notifier.load();
      expect(_listings(notifier.state), [_shirt]);
    });

    test('refresh replaces the list without showing the loader', () async {
      final pending =
          Completer<Either<NetworkExceptions, List<SponsoredListing>>>();
      var call = 0;
      when(() => repository.getSponsoredListings()).thenAnswer(
        (_) => call++ == 0 ? Future.value(right([_shirt])) : pending.future,
      );

      final notifier = await loaded();
      final refreshing = notifier.refresh();
      expect(_listings(notifier.state), [_shirt]);

      pending.complete(right([_tote, _shirt]));
      await refreshing;
      expect(_listings(notifier.state), [_tote, _shirt]);
    });

    test('a failed refresh keeps the list on screen', () async {
      stubList([
        right([_shirt]),
        left(const NetworkExceptions.noInternetConnection()),
      ]);

      final notifier = await loaded();
      await notifier.refresh();

      expect(_listings(notifier.state), [_shirt]);
    });

    test('an older response arriving late is ignored', () async {
      final first =
          Completer<Either<NetworkExceptions, List<SponsoredListing>>>();
      final second =
          Completer<Either<NetworkExceptions, List<SponsoredListing>>>();
      var call = 0;
      when(
        () => repository.getSponsoredListings(),
      ).thenAnswer((_) => call++ == 0 ? first.future : second.future);

      final notifier = SponsoredProductsNotifier(repository);
      addTearDown(notifier.dispose);
      final retry = notifier.load();

      second.complete(right([_tote]));
      await retry;
      first.complete(right([_shirt]));
      await pumpEventQueue();

      expect(_listings(notifier.state), [_tote]);
    });
  });

  group('pause', () {
    test('marks the card as pausing, then shows the paused listing', () async {
      stubList([
        right([_shirt, _tote]),
      ]);
      final paused = _listing(
        'p-1',
        state: SponsoredListingState.paused,
        isLive: false,
      );
      final pending = Completer<Either<NetworkExceptions, SponsoredListing>>();
      when(() => repository.pause('p-1')).thenAnswer((_) => pending.future);

      final notifier = await loaded();
      final pausing = notifier.pause('p-1');
      expect(_pausing(notifier.state), {'p-1'});

      pending.complete(right(paused));
      expect(await pausing, isNull);

      expect(_pausing(notifier.state), isEmpty);
      expect(_listings(notifier.state), [paused, _tote]);
      expect(_listings(notifier.state)!.first.status, SponsorshipStatus.paused);
    });

    test('a failed pause returns the failure and keeps the list', () async {
      stubList([
        right([_shirt]),
      ]);
      when(
        () => repository.pause('p-1'),
      ).thenAnswer(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );

      final notifier = await loaded();
      final failure = await notifier.pause('p-1');
      await pumpEventQueue();

      expect(failure, const NetworkExceptions.serverUnavailable());
      expect(_listings(notifier.state), [_shirt]);
      expect(_pausing(notifier.state), isEmpty);
      verify(() => repository.getSponsoredListings()).called(1);
    });

    test('a 404 on pause re-checks the list', () async {
      stubList([
        right([_shirt, _tote]),
        right([_tote]),
      ]);
      when(
        () => repository.pause('p-1'),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      final notifier = await loaded();
      final failure = await notifier.pause('p-1');
      await pumpEventQueue();

      expect(failure, const NetworkExceptions.notFound());
      expect(_listings(notifier.state), [_tote]);
      verify(() => repository.getSponsoredListings()).called(2);
    });
  });

  group('sponsor', () {
    test('adds a new sponsorship first and re-checks the list', () async {
      final started = _listing('p-3', cap: 100);
      stubList([
        right([_shirt]),
        left(const NetworkExceptions.serverUnavailable()),
      ]);
      stubSponsor(right(started));

      final notifier = await loaded();
      final result = await notifier.sponsor(
        productId: 'p-3',
        dailyImpressionCap: 100,
        endsUtc: DateTime.utc(2026, 10),
      );
      await pumpEventQueue();

      expect(result.getRight().toNullable(), started);
      // The re-check failed, so the list shows the saved card plus the rest.
      expect(_listings(notifier.state), [started, _shirt]);
      verify(
        () => repository.sponsor(
          productId: 'p-3',
          dailyImpressionCap: 100,
          endsUtc: DateTime.utc(2026, 10),
        ),
      ).called(1);
      verify(() => repository.getSponsoredListings()).called(2);
    });

    test(
      'a change replaces the card in place, then takes the fresh list',
      () async {
        final changed = _listing('p-2', cap: 900);
        final fresh = _listing('p-2', cap: 900);
        stubList([
          right([_shirt, _tote]),
          right([_shirt, fresh]),
        ]);
        stubSponsor(right(changed));

        final notifier = await loaded();
        await notifier.sponsor(productId: 'p-2', dailyImpressionCap: 900);
        await pumpEventQueue();

        expect(_listings(notifier.state), [_shirt, fresh]);
        expect(_listings(notifier.state)!.last.dailyImpressionCap, 900);
      },
    );

    test('a rejected save returns the failure and leaves the list', () async {
      stubList([
        right([_shirt]),
      ]);
      stubSponsor(left(_ruleViolation));

      final notifier = await loaded();
      final result = await notifier.sponsor(
        productId: 'p-9',
        dailyImpressionCap: 100,
      );
      await pumpEventQueue();

      expect(result.getLeft().toNullable(), _ruleViolation);
      expect(_listings(notifier.state), [_shirt]);
      verify(() => repository.getSponsoredListings()).called(1);
    });

    test('a 409 on first sponsor re-checks the list', () async {
      final other = _listing('p-3');
      stubList([
        right([_shirt]),
        right([other, _shirt]),
      ]);
      stubSponsor(left(_conflict));

      final notifier = await loaded();
      final result = await notifier.sponsor(
        productId: 'p-3',
        dailyImpressionCap: 100,
      );
      await pumpEventQueue();

      expect(isSponsorshipConflict(result.getLeft().toNullable()!), isTrue);
      expect(_listings(notifier.state), [other, _shirt]);
      verify(() => repository.getSponsoredListings()).called(2);
    });

    test('saving while the list had failed loads it afresh', () async {
      final started = _listing('p-3');
      stubList([
        left(const NetworkExceptions.serverUnavailable()),
        right([started, _shirt]),
      ]);
      stubSponsor(right(started));

      final notifier = await loaded();
      expect(notifier.state, isA<SponsoredProductsFailed>());

      await notifier.sponsor(productId: 'p-3', dailyImpressionCap: 100);
      await pumpEventQueue();

      expect(_listings(notifier.state), [started, _shirt]);
    });
  });
}
