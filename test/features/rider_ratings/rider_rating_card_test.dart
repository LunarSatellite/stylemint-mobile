import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_rating_card.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/presentation/widgets/rider_rating_card.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/shared/providers.dart';

import '../orders_test_harness.dart';
import 'fake_rider_rating_repository.dart';

void main() {
  late FakeRiderRatingRepository repo;

  setUp(() => repo = FakeRiderRatingRepository());

  Future<void> pump(
    WidgetTester tester, {
    required RiderRatingEligibility? eligibility,
    RiderRaterRole role = RiderRaterRole.buyer,
    String subOrderId = 'sub-1',
    double width = 390,
    double textScale = 1,
    Future<void> Function()? onSaved,
  }) async {
    setPhoneView(tester, width: width);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [riderRatingRepositoryProvider.overrideWithValue(repo)],
        child: ordersTestApp(
          SingleChildScrollView(
            child: RiderRatingCard(
              role: role,
              subOrderId: subOrderId,
              eligibility: eligibility,
              riderName: 'Ramesh K.',
              onSaved: onSaved,
            ),
          ),
          textScale: textScale,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  group('RiderRatingCard (buyer)', () {
    testWidgets('hidden from a backend without ratings', (tester) async {
      await pump(tester, eligibility: null);
      expect(find.text('How was your rider?'), findsNothing);
      expect(find.byKey(RiderRatingCard.submitKey), findsNothing);
    });

    testWidgets('hidden when not eligible and nothing was given', (
      tester,
    ) async {
      await pump(
        tester,
        eligibility: const RiderRatingEligibility(canRateRider: false),
      );
      expect(find.text('How was your rider?'), findsNothing);
    });

    testWidgets('hidden without a sub-order to rate', (tester) async {
      await pump(
        tester,
        subOrderId: '',
        eligibility: const RiderRatingEligibility(canRateRider: true),
      );
      expect(find.text('How was your rider?'), findsNothing);
    });

    testWidgets('stars, tags that fit them, a comment → submitted', (
      tester,
    ) async {
      var saved = 0;
      await pump(
        tester,
        eligibility: const RiderRatingEligibility(canRateRider: true),
        onSaved: () async => saved++,
      );

      expect(find.text('How was your rider?'), findsOneWidget);
      expect(find.text('Ramesh K. delivered your parcel'), findsOneWidget);
      // Nothing to send before a star is picked.
      final submit = tester.widget<FilledButton>(
        find.byKey(RiderRatingCard.submitKey),
      );
      expect(submit.onPressed, isNull);

      // Two stars: the problem tags.
      await tapKey(tester, RiderRatingCard.starKey(2));
      expect(find.text('What went wrong?'), findsOneWidget);
      expect(find.byKey(RiderRatingCard.tagKey(RiderRatingTag.late)), findsOne);
      expect(find.byKey(RiderRatingCard.tagKey(RiderRatingTag.onTime)), findsNothing);
      await tapKey(tester, RiderRatingCard.tagKey(RiderRatingTag.late));

      // Five stars: praise instead, and the problem tag is dropped.
      await tapKey(tester, RiderRatingCard.starKey(5));
      expect(find.text('What went well?'), findsOneWidget);
      expect(find.text('Went to the wrong place'), findsNothing);
      await tapKey(tester, RiderRatingCard.tagKey(RiderRatingTag.onTime));
      await tapKey(
        tester,
        RiderRatingCard.tagKey(RiderRatingTag.carefulWithParcel),
      );
      await tester.enterText(
        find.byKey(RiderRatingCard.commentKey),
        '  Very careful  ',
      );
      await tapKey(tester, RiderRatingCard.submitKey);
      await tester.pump();

      final sent = repo.rated.single;
      expect(sent.role, RiderRaterRole.buyer);
      expect(sent.subOrderId, 'sub-1');
      expect(sent.stars, 5);
      expect(sent.tags, [
        RiderRatingTag.onTime,
        RiderRatingTag.carefulWithParcel,
      ]);
      expect(sent.comment?.trim(), 'Very careful');
      expect(saved, 1);

      // The rating as given, editable inside its window.
      expect(find.text('Your rating of your rider'), findsOneWidget);
      expect(find.text('On time'), findsOneWidget);
      expect(find.text('“Very careful”'), findsOneWidget);
      expect(find.byKey(RiderRatingCard.editKey), findsOneWidget);
      expect(find.byKey(RiderRatingCard.submitKey), findsNothing);
    });

    testWidgets('at most four tags', (tester) async {
      await pump(
        tester,
        eligibility: const RiderRatingEligibility(canRateRider: true),
      );
      await tapKey(tester, RiderRatingCard.starKey(4));
      final praise = RiderRatingTag.forStars(4);
      for (final tag in praise.take(4)) {
        await tapKey(tester, RiderRatingCard.tagKey(tag));
      }
      final fifth = tester.widget<FilterChip>(
        find.byKey(RiderRatingCard.tagKey(praise.last)),
      );
      expect(fifth.onSelected, isNull);
    });

    testWidgets('a refusal is shown in words and the form stays', (
      tester,
    ) async {
      repo.rateResult = left(
        const NetworkExceptions.validation(code: 'rider_rating.window_closed'),
      );
      await pump(
        tester,
        eligibility: const RiderRatingEligibility(canRateRider: true),
      );
      await tapKey(tester, RiderRatingCard.starKey(3));
      await tapKey(tester, RiderRatingCard.submitKey);
      await tester.pump();

      expect(find.textContaining('7 days after delivery'), findsOneWidget);
      expect(find.byKey(RiderRatingCard.submitKey), findsOneWidget);
      expect(find.textContaining('rider_rating'), findsNothing);
    });

    testWidgets('an existing rating shows with Edit, which reopens the form', (
      tester,
    ) async {
      repo.saved = right(
        RiderRating(
          subOrderId: 'sub-1',
          stars: 4,
          tags: const [RiderRatingTag.friendly],
          comment: 'Nice',
          editableUntilUtc: DateTime.now().toUtc().add(const Duration(days: 3)),
        ),
      );
      await pump(
        tester,
        eligibility: const RiderRatingEligibility(
          canRateRider: true,
          rating: RiderRatingBrief(stars: 4, tags: [RiderRatingTag.friendly]),
        ),
      );
      await tester.pump();

      expect(find.text('Friendly'), findsOneWidget);
      expect(find.text('“Nice”'), findsOneWidget);
      await tapKey(tester, RiderRatingCard.editKey);

      // Prefilled with what was given.
      final chip = tester.widget<FilterChip>(
        find.byKey(RiderRatingCard.tagKey(RiderRatingTag.friendly)),
      );
      expect(chip.selected, isTrue);
      expect(find.text('Nice'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);

      await tapKey(tester, RiderRatingCard.starKey(5));
      await tapKey(tester, RiderRatingCard.submitKey);
      await tester.pump();
      expect(repo.rated.single.stars, 5);
      expect(repo.rated.single.tags, [RiderRatingTag.friendly]);
    });

    testWidgets('past the edit window: read-only, no Edit', (tester) async {
      repo.saved = right(
        RiderRating(
          subOrderId: 'sub-1',
          stars: 2,
          editableUntilUtc: DateTime.now().toUtc().subtract(
            const Duration(days: 1),
          ),
        ),
      );
      await pump(
        tester,
        eligibility: const RiderRatingEligibility(
          canRateRider: true,
          rating: RiderRatingBrief(stars: 2),
        ),
      );
      await tester.pump();
      expect(find.byKey(RiderRatingCard.editKey), findsNothing);

      // And when the order itself says it can no longer be rated.
      repo.saved = right(null);
      await pump(
        tester,
        subOrderId: 'sub-2',
        eligibility: const RiderRatingEligibility(
          canRateRider: false,
          rating: RiderRatingBrief(stars: 2),
        ),
      );
      await tester.pump();
      expect(find.byKey(RiderRatingCard.editKey), findsNothing);
      expect(find.text('Your rating of your rider'), findsOneWidget);
    });

    testWidgets('no overflow at 320dp with text ×1.3', (tester) async {
      await pump(
        tester,
        width: 320,
        textScale: 1.3,
        eligibility: const RiderRatingEligibility(canRateRider: true),
      );
      await tapKey(tester, RiderRatingCard.starKey(4));
      expectNoLayoutErrors(tester);
    });
  });

  group('RiderRatingCard (vendor)', () {
    testWidgets('"Rate the rider" sends the vendor rating', (tester) async {
      await pump(
        tester,
        role: RiderRaterRole.vendor,
        eligibility: const RiderRatingEligibility(canRateRider: true),
      );
      expect(find.text('Rate the rider'), findsOneWidget);
      expect(find.text('Ramesh K. picked up this parcel'), findsOneWidget);

      await tapKey(tester, RiderRatingCard.starKey(1));
      await tapKey(tester, RiderRatingCard.tagKey(RiderRatingTag.rude));
      await tapKey(tester, RiderRatingCard.submitKey);
      await tester.pump();

      expect(repo.rated.single.role, RiderRaterRole.vendor);
      expect(repo.rated.single.stars, 1);
      expect(repo.rated.single.tags, [RiderRatingTag.rude]);
      expect(find.text('Your rating of the rider'), findsOneWidget);
    });
  });

  group('CourierRatingCard', () {
    Future<void> pumpCourier(WidgetTester tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [riderRatingRepositoryProvider.overrideWithValue(repo)],
          child: ordersTestApp(
            const SingleChildScrollView(child: CourierRatingCard()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('the summary: average, count, breakdown, tags, comments', (
      tester,
    ) async {
      repo.mine = right(
        CourierRatingOverview.fromJson({
          'average': 4.7,
          'count': 23,
          'breakdown': {'5': 18, '4': 3, '3': 1, '2': 1, '1': 0},
          'topTags': [
            {'tag': 'OnTime', 'count': 12},
          ],
          'recent': [
            {
              'stars': 5,
              'tags': ['Friendly'],
              'comment': 'Lovely',
              'raterRole': 'Buyer',
              'ageDays': 2,
            },
          ],
        }),
      );
      await pumpCourier(tester);

      expect(find.text('Your rating'), findsOneWidget);
      expect(find.text('4.7'), findsOneWidget);
      expect(find.text('23 ratings'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('On time · 12'), findsOneWidget);
      expect(find.text('Lovely'), findsOneWidget);
      expect(find.text('Buyer · 2 days ago'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('under three ratings: "New rider"', (tester) async {
      repo.mine = right(
        CourierRatingOverview.fromJson({'average': null, 'count': 2}),
      );
      await pumpCourier(tester);
      expect(find.text('New rider'), findsOneWidget);
      expect(find.text('2 ratings'), findsOneWidget);
    });

    testWidgets('nothing at all on a 404 or a failure', (tester) async {
      repo.mine = right(null);
      await pumpCourier(tester);
      expect(find.text('Your rating'), findsNothing);

      repo.mine = left(const NetworkExceptions.serverUnavailable());
      await pumpCourier(tester);
      expect(find.text('Your rating'), findsNothing);
    });
  });
}
