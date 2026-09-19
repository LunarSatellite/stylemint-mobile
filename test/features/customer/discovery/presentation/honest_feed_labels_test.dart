import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feed.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/feed_provenance.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';

import '../../mall_home/mall_test_support.dart';
import '../discover_test_support.dart';

/// The lead feed is built from the **public** merchandised home page and the
/// bestselling listing. Nothing on either path knows who is reading, so the
/// copy the client writes itself may not say that anything was picked for
/// them. These tests pin the three halves of that rule:
///
/// 1. the client's own fallbacks name the source ("From the Mall");
/// 2. a server-sent section title is content and still wins;
/// 3. the one vocabulary that *is* personal still says so.
DiscoverFeedLoaded _loaded(DiscoverFeedNotifier notifier) =>
    notifier.state.feed as DiscoverFeedLoaded;

List<String> _productTitles(DiscoverFeedNotifier notifier) => [
  for (final block in _loaded(
    notifier,
  ).blocks.whereType<DiscoverProductsBlock>())
    block.title,
];

/// [sampleHome] with every product section's title and reason stripped, which
/// is what the public home contract may legitimately send: rails with items
/// and no title at all.
MallHome _untitledHome() => MallHome(
  generatedUtc: sampleHome().generatedUtc,
  sections: [
    for (final section in sampleHome().sections)
      if (section is HomeProductsSection)
        HomeProductsSection(
          id: section.id,
          items: section.items,
          eyebrow: section.eyebrow,
          seeAll: section.seeAll,
        )
      else
        section,
  ],
);

void main() {
  group('ForYouFeedSource block titles', () {
    DiscoverFeedNotifier build(MallHome home) {
      final notifier = DiscoverFeedNotifier(
        homeRepository: FakeMallHomeRepository([right(home)]),
        catalogRepository: FakeMallCatalogRepository(
          onProducts: (_) => right(
            productPage(['q-1', 'q-2', 'q-3', 'q-4', 'q-5', 'q-6', 'q-7']),
          ),
        ),
        discoverRepository: FakeDiscoverRepository(),
      );
      addTearDown(notifier.dispose);
      return notifier;
    }

    test(
      'a home with no section titles falls back to the honest label',
      () async {
        final notifier = build(_untitledHome());
        await pumpEventQueue();

        expect(_productTitles(notifier), [
          'From the Mall',
          'More from the Mall',
        ]);
        expect(
          _productTitles(notifier).join(' ').toLowerCase(),
          isNot(contains('for you')),
        );
        expect(
          _productTitles(notifier).join(' ').toLowerCase(),
          isNot(contains('pick')),
        );
      },
    );

    test('a server-sent title still wins over the fallback', () async {
      // `sampleHome`'s lead rail is titled "Picked for you" by the server.
      // That is content the Mall chose to publish, not a claim this client
      // invented, so it is rendered exactly as sent.
      final notifier = build(sampleHome());
      await pumpEventQueue();

      expect(_productTitles(notifier).first, 'Picked for you');
      // The block the client titles itself is still the honest one.
      expect(_productTitles(notifier)[1], 'More from the Mall');
    });

    test('the server reason line is still shown as the subtitle', () async {
      final notifier = build(sampleHome());
      await pumpEventQueue();

      final lead = _loaded(
        notifier,
      ).blocks.whereType<DiscoverProductsBlock>().first;
      expect(lead.subtitle, 'Because you follow Stylemint Nepal');
    });

    test('paged blocks claim nothing either', () async {
      final notifier = build(_untitledHome());
      await pumpEventQueue();
      await notifier.loadMore();

      for (final title in _productTitles(notifier)) {
        expect(title.toLowerCase(), isNot(contains('for you')));
      }
    });
  });

  group('the vocabulary', () {
    test('the lead chip names the feed, not the reader', () {
      expect(DiscoverFeedKind.forYou.label, 'The Mall');
      for (final kind in DiscoverFeedKind.values) {
        expect(kind.label.toLowerCase(), isNot(contains('for you')));
      }
    });

    test('a genuinely personalised slot still says so', () {
      expect(FeedSlotKind.personalized.label, 'From your interests');
      expect(
        FeedSlotKind.personalized.spokenLabel,
        'From the categories you follow',
      );
      expect(FeedSlotKind.personalized.isPersonal, isTrue);
      // And the generic kinds still describe the content only.
      expect(FeedSlotKind.popular.label, 'Popular right now');
      expect(FeedSlotKind.newIn.label, 'New in');
      expect(FeedSlotKind.unknown.label, 'From the Mall');
      expect(FeedSlotKind.unknown.isPersonal, isFalse);
    });
  });

  testWidgets(
    'the honest label renders, and does not overflow at 320dp × 1.3',
    (tester) async {
      await pumpDiscover(
        tester,
        home: FakeMallHomeRepository([right(_untitledHome())]),
        catalog: FakeMallCatalogRepository(
          onProducts: (_) => right(productPage(['q-1', 'q-2', 'q-3'])),
        ),
        width: 320,
        textScale: 1.3,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('From the Mall'), findsWidgets);
      expect(find.text('Picked for you'), findsNothing);
      expect(find.text('More picks for you'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the chip reads "The Mall" at 320dp × 1.3', (tester) async {
    await pumpDiscover(tester, width: 320, textScale: 1.3);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('discover-chip-forYou')),
        matching: find.text('The Mall'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
