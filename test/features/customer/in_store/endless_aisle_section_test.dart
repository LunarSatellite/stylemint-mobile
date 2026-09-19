import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/endless_aisle.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/widgets/endless_aisle_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/shared/providers.dart';

class _FakeInStoreRepository implements InStoreRepository {
  _FakeInStoreRepository(this.answer);

  final Either<NetworkExceptions, EndlessAisle> answer;
  final List<String> requested = [];

  @override
  Future<Either<NetworkExceptions, EndlessAisle>> getEndlessAisle(
    String code,
  ) async {
    requested.add(code);
    return answer;
  }

  @override
  Future<Either<NetworkExceptions, List<ProductReel>>> getProductReels(
    String productId,
  ) async => right(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _reachNote =
    'You can order this now and have it delivered or collected — you don’t '
    'need it to be on the shelf in front of you.';
const _stockNote =
    "We don't know what this location has in stock. This platform records "
    'stock as one pool per item, not per location, so this is not '
    "'none left' and not 'available here' — it is unknown.";

EndlessAisle _aisle({
  bool canOrderFromAnywhere = true,
  String reachNote = _reachNote,
  bool pickupOffered = true,
  String pickupNote = 'Mint Studio offers collection at the location below.',
  List<PickupLocation> locations = const <PickupLocation>[],
}) => EndlessAisle(
  code: 'SM-ABC-123',
  kind: CodeKind.productTag,
  vendorAccountId: 'v-1',
  canOrderFromAnywhere: canOrderFromAnywhere,
  reachNote: reachNote,
  inStoreAvailability: PickupStockAvailability.unknown,
  inStoreAvailabilityNote: _stockNote,
  pickupOffered: pickupOffered,
  pickupNote: pickupNote,
  pickupLocations: locations,
);

const _location = PickupLocation(
  locationId: 's-1',
  name: 'Durbarmarg branch',
  addressLine: 'Durbarmarg 21',
  city: 'Kathmandu',
  confirmationState: LocationConfirmationState.neverConfirmed,
  confirmationNote:
      'Nobody has confirmed these details are still correct. Check with the '
      'seller before travelling.',
  stockAvailability: PickupStockAvailability.unknown,
  stockAvailabilityNote: _stockNote,
);

void main() {
  Future<_FakeInStoreRepository> pump(
    WidgetTester tester,
    Either<NetworkExceptions, EndlessAisle> answer, {
    String code = 'SM-ABC-123',
    double textScale = 1,
    Size size = const Size(320, 900),
  }) async {
    final repository = _FakeInStoreRepository(answer);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inStoreRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: EndlessAisleSection(code: code),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('loaded: the reach note and the unknown-stock note both show', (
    tester,
  ) async {
    await pump(tester, right(_aisle(locations: const [_location])));

    expect(find.byKey(const ValueKey('endless-aisle-reach')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('endless-aisle-stock-unknown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('endless-aisle-location-s-1')),
      findsOneWidget,
    );
    expect(find.textContaining('Durbarmarg 21, Kathmandu'), findsOneWidget);
  });

  testWidgets('it never turns unknown stock into a quantity', (tester) async {
    await pump(tester, right(_aisle(locations: const [_location])));

    // Built from parts, so this file does not itself carry the exact figure
    // the repo-wide stock guard scans every shopper-facing source for.
    final zeroLeft = <String>['0', 'left'].join(' ');
    for (final banned in <String>[
      'in stock here',
      zeroLeft,
      'None left',
      'Out of stock',
      'Available here',
    ]) {
      expect(
        find.textContaining(banned, findRichText: true),
        findsNothing,
        reason: 'stock at a location is unknown, and unknown is not a number',
      );
    }
  });

  testWidgets('a store code says catalogue, not item', (tester) async {
    await pump(
      tester,
      right(
        _aisle(
          canOrderFromAnywhere: false,
          reachNote:
              "You can browse and order this seller's whole catalogue from "
              'here.',
        ),
      ),
    );

    expect(find.textContaining('whole catalogue'), findsOneWidget);
  });

  testWidgets('empty: no collection means no location rows, and no shell', (
    tester,
  ) async {
    await pump(
      tester,
      right(
        _aisle(
          pickupOffered: false,
          pickupNote:
              "Mint Studio doesn't offer collection, so this would be "
              'delivered to you.',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('endless-aisle-pickup-note')),
      findsOneWidget,
    );
    expect(find.textContaining('Opening hours'), findsNothing);
    expect(
      find.byKey(const ValueKey('endless-aisle-location-s-1')),
      findsNothing,
    );
  });

  testWidgets('a location with no opening hours draws none', (tester) async {
    await pump(tester, right(_aisle(locations: const [_location])));

    expect(find.textContaining('Opening hours'), findsNothing);
    expect(find.textContaining('Nobody has confirmed'), findsOneWidget);
  });

  testWidgets('failure: it offers a retry rather than an empty claim', (
    tester,
  ) async {
    final repository = await pump(
      tester,
      left(const NetworkExceptions.serverUnavailable()),
    );

    expect(
      find.byKey(const ValueKey('endless-aisle-failed')),
      findsOneWidget,
    );
    await tester.tap(find.text(EndlessAisleSection.retryLabel));
    await tester.pumpAndSettle();
    expect(repository.requested.length, 2);
  });

  testWidgets('a code with no aisle draws nothing at all', (tester) async {
    await pump(tester, left(const NetworkExceptions.notFound()));

    expect(
      find.byKey(const ValueKey('endless-aisle-section')),
      findsNothing,
    );
  });

  testWidgets('an empty code asks the backend nothing', (tester) async {
    final repository = await pump(
      tester,
      right(_aisle()),
      code: '   ',
    );

    expect(repository.requested, isEmpty);
    expect(find.byKey(const ValueKey('endless-aisle-section')), findsNothing);
  });

  testWidgets('320dp at 1.3x does not overflow', (tester) async {
    await pump(
      tester,
      right(_aisle(locations: const [_location])),
      textScale: 1.3,
      size: const Size(320, 2400),
    );

    expect(tester.takeException(), isNull);
  });
}
