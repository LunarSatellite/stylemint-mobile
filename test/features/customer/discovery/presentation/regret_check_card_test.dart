import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/regret_check.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/regret_check_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

const _viewedId = 'p-viewed';

const _options = [
  RegretOption(
    rank: 1,
    productId: 'p-alt',
    productName: 'Canvas tote',
    eligible: true,
    level: RegretLevel.low,
    reviewCount: 120,
    reasons: ['2% of orders returned'],
  ),
  RegretOption(
    rank: 2,
    productId: _viewedId,
    productName: 'Leather tote',
    eligible: true,
    level: RegretLevel.medium,
    reviewCount: 40,
    reasons: ['12% of orders returned'],
  ),
  RegretOption(
    rank: 3,
    productId: 'p-new',
    productName: 'Jute tote',
    eligible: false,
    level: RegretLevel.unknown,
    reviewCount: 0,
    reasons: ['Out of stock right now'],
  ),
];

const _check = RegretCheck(
  productId: _viewedId,
  abstained: false,
  recommendedProductId: 'p-alt',
  summary: 'Buyers rarely send the Canvas tote back.',
  windowDays: 90,
  options: _options,
);

const _abstained = RegretCheck(
  productId: _viewedId,
  abstained: true,
  recommendedProductId: 'p-alt',
  summary: 'None of these has enough history yet to recommend one.',
  windowDays: 90,
  options: _options,
);

const _alone = RegretCheck(
  productId: _viewedId,
  abstained: false,
  summary: 'Nothing similar to compare yet.',
  windowDays: 90,
  options: [
    RegretOption(
      rank: 1,
      productId: _viewedId,
      productName: 'Leather tote',
      eligible: true,
      level: RegretLevel.low,
      reviewCount: 40,
      reasons: [],
    ),
  ],
);

Future<RegretCheck?> _readProvider(DiscoveryRepository repository) async {
  final container = ProviderContainer(
    overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  final sub = container.listen(
    regretCheckProvider(_viewedId).future,
    (_, _) {},
  );
  return sub.read();
}

void main() {
  late _MockDiscoveryRepository repository;

  setUp(() => repository = _MockDiscoveryRepository());

  void stub(RegretCheck check) => when(
    () => repository.getRegretCheck(_viewedId),
  ).thenAnswer((_) async => right(check));

  group('regretCheckProvider', () {
    test('exposes a check that has alternatives', () async {
      stub(_check);

      expect(await _readProvider(repository), same(_check));
    });

    test('is null when only the viewed product comes back', () async {
      stub(_alone);

      expect(await _readProvider(repository), isNull);
    });

    test('is null on a repository failure', () async {
      when(
        () => repository.getRegretCheck(_viewedId),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      expect(await _readProvider(repository), isNull);
    });

    test('is null when the repository throws', () async {
      when(
        () => repository.getRegretCheck(_viewedId),
      ).thenThrow(StateError('boom'));

      expect(await _readProvider(repository), isNull);
    });
  });

  group('RegretCheckCard', () {
    Future<List<String>> pumpCard(WidgetTester tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RegretCheckCard(
                  productId: _viewedId,
                  onOpenProduct: opened.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return opened;
    }

    Finder inOption(String productId, Finder finder) => find.descendant(
      of: find.byKey(ValueKey('regret-option-$productId')),
      matching: finder,
    );

    Finder dimmingOf(String text) => find.ancestor(
      of: find.text(text),
      matching: find.descendant(
        of: find.byType(RegretCheckCard),
        matching: find.byType(Opacity),
      ),
    );

    testWidgets('lists every option with its level, reasons and tags', (
      tester,
    ) async {
      stub(_check);

      await pumpCard(tester);

      expect(find.text('Check before you buy'), findsOneWidget);
      expect(
        find.text('Buyers rarely send the Canvas tote back.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('regret-check-abstained')),
        findsNothing,
      );

      expect(inOption('p-alt', find.text('Canvas tote')), findsOneWidget);
      expect(inOption('p-alt', find.text('Rarely regretted')), findsOneWidget);
      expect(inOption('p-alt', find.text('Recommended')), findsOneWidget);
      expect(
        inOption('p-alt', find.text('2% of orders returned')),
        findsOneWidget,
      );

      expect(inOption(_viewedId, find.text('This one')), findsOneWidget);
      expect(inOption(_viewedId, find.text('Some regrets')), findsOneWidget);

      expect(inOption('p-new', find.text('Too new to tell')), findsOneWidget);
      expect(
        inOption('p-new', find.text('Out of stock right now')),
        findsOneWidget,
      );

      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('This one'), findsOneWidget);
    });

    testWidgets('dims only the options that are not eligible', (tester) async {
      stub(_check);

      await pumpCard(tester);

      expect(dimmingOf('Jute tote'), findsOneWidget);
      expect(tester.widget<Opacity>(dimmingOf('Jute tote')).opacity, 0.5);
      expect(dimmingOf('Canvas tote'), findsNothing);
      expect(dimmingOf('Leather tote'), findsNothing);
    });

    testWidgets('tapping another option opens it; the viewed one stays put', (
      tester,
    ) async {
      stub(_check);

      final opened = await pumpCard(tester);
      await tester.tap(find.text('Canvas tote'));
      await tester.tap(find.text('Leather tote'));
      await tester.pump();

      expect(opened, ['p-alt']);
    });

    testWidgets('when abstained, shows the summary prominently and no '
        'Recommended tag', (tester) async {
      stub(_abstained);

      await pumpCard(tester);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('regret-check-abstained')),
          matching: find.text(
            'None of these has enough history yet to recommend one.',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Recommended'), findsNothing);
      expect(find.text('This one'), findsOneWidget);
      expect(find.text('Canvas tote'), findsOneWidget);
    });

    testWidgets('renders nothing when the check fails', (tester) async {
      when(() => repository.getRegretCheck(_viewedId)).thenAnswer(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );

      await pumpCard(tester);

      expect(find.text('Check before you buy'), findsNothing);
    });

    testWidgets('renders nothing when there is nothing to compare', (
      tester,
    ) async {
      stub(_alone);

      await pumpCard(tester);

      expect(find.text('Check before you buy'), findsNothing);
      expect(find.text('Leather tote'), findsNothing);
    });
  });

  group('regretLevelLabel', () {
    test('uses plain shopper wording for each level', () {
      expect(regretLevelLabel(RegretLevel.low), 'Rarely regretted');
      expect(regretLevelLabel(RegretLevel.medium), 'Some regrets');
      expect(regretLevelLabel(RegretLevel.high), 'Often regretted');
      expect(regretLevelLabel(RegretLevel.unknown), 'Too new to tell');
    });
  });
}
