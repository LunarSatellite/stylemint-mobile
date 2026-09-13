import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/sponsored_products_errors.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/presentation/widgets/sponsor_product_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/shared/providers.dart';

typedef _Call = ({String productId, int cap, DateTime? endsUtc});

const _products = [
  SponsorProductTarget(productId: 'p-1', productName: 'Linen shirt'),
  SponsorProductTarget(productId: 'p-2', productName: 'Canvas tote'),
];

const _saved = SponsoredListing(
  id: 'l-2',
  productId: 'p-2',
  productName: 'Canvas tote',
  state: SponsoredListingState.active,
  isLive: true,
  dailyImpressionCap: 250,
);

final Finder _capField = find.byKey(const ValueKey('sponsor-daily-cap'));

DateTime _todayPlus(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

void main() {
  late List<_Call> calls;
  SponsorFormResult? result;
  late bool closed;

  setUp(() {
    calls = [];
    result = null;
    closed = false;
  });

  SponsorProductSubmit answering(
    Either<NetworkExceptions, SponsoredListing> answer,
  ) => ({required productId, required dailyImpressionCap, endsUtc}) async {
    calls.add((
      productId: productId,
      cap: dailyImpressionCap,
      endsUtc: endsUtc,
    ));
    return answer;
  };

  Future<void> openSheet(
    WidgetTester tester, {
    Either<NetworkExceptions, SponsoredListing> answer = const Right(_saved),
    SponsorProductTarget? product,
    SponsoredListing? existing,
    Either<NetworkExceptions, List<SponsorProductTarget>> products =
        const Right(_products),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sponsorableProductsProvider.overrideWith((ref) async => products),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showSponsorProductSheet(
                    context,
                    onSubmit: answering(answer),
                    product: product,
                    existing: existing,
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('validateDailyImpressionCap', () {
    test('accepts 10 to 10,000 only', () {
      expect(
        validateDailyImpressionCap(null),
        dailyImpressionCapRequiredMessage,
      );
      expect(
        validateDailyImpressionCap(' '),
        dailyImpressionCapRequiredMessage,
      );
      expect(validateDailyImpressionCap('9'), dailyImpressionCapRangeMessage);
      expect(
        validateDailyImpressionCap('10001'),
        dailyImpressionCapRangeMessage,
      );
      expect(
        validateDailyImpressionCap('lots'),
        dailyImpressionCapRangeMessage,
      );
      expect(validateDailyImpressionCap('10'), isNull);
      expect(validateDailyImpressionCap('10000'), isNull);
    });
  });

  testWidgets('blocks Save until most views a day is between 10 and 10,000', (
    tester,
  ) async {
    await openSheet(
      tester,
      product: const SponsorProductTarget(
        productId: 'p-1',
        productName: 'Linen shirt',
      ),
    );

    expect(find.text('Sponsor a product'), findsOneWidget);
    expect(find.text('Linen shirt'), findsOneWidget);
    expect(
      find.text('Shoppers always see the Sponsored label.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text(dailyImpressionCapRequiredMessage), findsOneWidget);

    await tester.enterText(_capField, '5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text(dailyImpressionCapRangeMessage), findsOneWidget);

    await tester.enterText(_capField, '10001');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text(dailyImpressionCapRangeMessage), findsOneWidget);
    expect(calls, isEmpty);

    await tester.enterText(_capField, '10');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(calls.single, (productId: 'p-1', cap: 10, endsUtc: null));
    expect(closed, isTrue);
  });

  testWidgets('asks for a product, then saves the one picked', (tester) async {
    await openSheet(tester);

    await tester.enterText(_capField, '250');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text(chooseProductToSponsorMessage), findsOneWidget);
    expect(calls, isEmpty);

    await tester.tap(find.text('Choose a live product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canvas tote').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(calls.single, (productId: 'p-2', cap: 250, endsUtc: null));
    expect(result, isA<SponsorFormSaved>());
    expect((result! as SponsorFormSaved).listing, _saved);
    expect(
      sponsorFormResultMessage(result!),
      'Saved. Canvas tote is sponsored.',
    );
  });

  testWidgets('says so when there are no live products', (tester) async {
    await openSheet(tester, products: const Right([]));

    expect(
      find.text("You don't have any live products to sponsor yet."),
      findsOneWidget,
    );
  });

  testWidgets('offers Try again when live products fail to load', (
    tester,
  ) async {
    await openSheet(
      tester,
      products: const Left(NetworkExceptions.serverUnavailable()),
    );

    expect(find.text("Couldn't load your live products."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Change keeps a future end date, and it can be removed', (
    tester,
  ) async {
    final lastDay = _todayPlus(10);
    final ends = sponsorshipEndsAfter(lastDay).toUtc();
    await openSheet(
      tester,
      existing: SponsoredListing(
        id: 'l-1',
        productId: 'p-1',
        productName: 'Linen shirt',
        state: SponsoredListingState.active,
        isLive: true,
        dailyImpressionCap: 500,
        endsUtc: ends,
      ),
    );

    expect(find.text('Change sponsorship'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_capField).controller?.text,
      '500',
    );
    expect(
      find.text('Runs through ${formatSponsorshipDay(lastDay)}'),
      findsOneWidget,
    );

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('No end date. Runs until you pause it.'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(calls.single, (productId: 'p-1', cap: 500, endsUtc: null));
  });

  testWidgets('Save sends the end date as the start of the day after', (
    tester,
  ) async {
    await openSheet(
      tester,
      product: const SponsorProductTarget(
        productId: 'p-1',
        productName: 'Linen shirt',
      ),
    );

    await tester.enterText(_capField, '400');
    await tester.tap(find.byKey(const ValueKey('sponsor-end-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final lastDay = _todayPlus(6);
    expect(
      find.text('Runs through ${formatSponsorshipDay(lastDay)}'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(calls.single.endsUtc, sponsorshipEndsAfter(lastDay).toUtc());
    expect(calls.single.endsUtc!.isUtc, isTrue);
  });

  testWidgets('Restart of an ended sponsorship drops its past end date', (
    tester,
  ) async {
    await openSheet(
      tester,
      existing: SponsoredListing(
        id: 'l-1',
        productId: 'p-1',
        productName: 'Linen shirt',
        state: SponsoredListingState.active,
        isLive: false,
        dailyImpressionCap: 300,
        endsUtc: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      ),
    );

    expect(find.text('Restart sponsorship'), findsOneWidget);
    expect(find.text('No end date. Runs until you pause it.'), findsOneWidget);
  });

  testWidgets('shows backend field errors under their fields', (tester) async {
    await openSheet(
      tester,
      product: const SponsorProductTarget(
        productId: 'p-1',
        productName: 'Linen shirt',
      ),
      answer: const Left(
        NetworkExceptions.validation(
          code: 'validation.multiple_errors',
          message: 'One or more validation errors occurred.',
          errors: [
            FieldErrorVm(
              field: 'DailyImpressionCap',
              code: 'validation.invalid',
              message: 'Choose between 10 and 10,000 sponsored views a day.',
            ),
            FieldErrorVm(
              field: 'EndsUtc',
              code: 'validation.invalid',
              message: 'The end date must be in the future.',
            ),
          ],
        ),
      ),
    );

    await tester.enterText(_capField, '100');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(closed, isFalse);
    expect(
      find.text('Choose between 10 and 10,000 sponsored views a day.'),
      findsOneWidget,
    );
    expect(find.text('The end date must be in the future.'), findsOneWidget);
    expect(find.byKey(const ValueKey('sponsor-form-error')), findsNothing);

    await tester.enterText(_capField, '120');
    await tester.pumpAndSettle();
    expect(
      find.text('Choose between 10 and 10,000 sponsored views a day.'),
      findsNothing,
    );
  });

  testWidgets('shows a rule violation above Save', (tester) async {
    await openSheet(
      tester,
      product: const SponsorProductTarget(
        productId: 'p-1',
        productName: 'Linen shirt',
      ),
      answer: const Left(
        NetworkExceptions.validation(
          code: 'rule.violation',
          message: 'Only live products can be sponsored.',
        ),
      ),
    );

    await tester.enterText(_capField, '100');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(closed, isFalse);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('sponsor-form-error')))
          .data,
      'Only live products can be sponsored.',
    );
  });

  testWidgets('shows our own copy for a 404', (tester) async {
    await openSheet(
      tester,
      product: const SponsorProductTarget(
        productId: 'p-1',
        productName: 'Linen shirt',
      ),
      answer: const Left(NetworkExceptions.notFound()),
    );

    await tester.enterText(_capField, '100');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(closed, isFalse);
    expect(find.text(sponsoredProductNotFoundMessage), findsOneWidget);
  });

  testWidgets('a 409 closes the form with the conflict message', (
    tester,
  ) async {
    await openSheet(
      tester,
      product: const SponsorProductTarget(
        productId: 'p-1',
        productName: 'Linen shirt',
      ),
      answer: const Left(
        NetworkExceptions.validation(
          code: sponsorshipConflictCode,
          message: 'This product is already being sponsored.',
        ),
      ),
    );

    await tester.enterText(_capField, '100');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isA<SponsorFormConflict>());
    expect(
      sponsorFormResultMessage(result!),
      'This product is already being sponsored.',
    );
  });
}
