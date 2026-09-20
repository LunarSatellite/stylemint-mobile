import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/location_capture_service.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/repositories/shipping_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/screens/add_edit_address_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/screens/shipping_addresses_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/screens/view_address_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/widgets/address_pin_map.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeLocationService implements LocationCaptureService {
  _FakeLocationService(this.result);

  LocationCaptureResult result;

  bool openedAppSettings = false;
  bool openedLocationSettings = false;

  /// Every read of the device position, of any kind. The service has no
  /// silent variant, so this counting one call is the same thing as the
  /// shopper having tapped "Use my current location" exactly once.
  int promptedCalls = 0;

  @override
  Future<LocationCaptureResult> capture({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    promptedCalls++;
    return result;
  }

  @override
  Future<bool> openAppSettings() async {
    openedAppSettings = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openedLocationSettings = true;
    return true;
  }
}

class _FakeShippingRepository implements ShippingRepository {
  _FakeShippingRepository({this.addresses = const []});

  List<ShippingAddress> addresses;

  /// Failure returned by add/update, if any.
  NetworkExceptions? writeFailure;

  /// Result returned by resolveMapsLink.
  Either<NetworkExceptions, ResolvedMapsLink>? resolveResult;

  ShippingAddress? lastWritten;
  int writeCalls = 0;

  @override
  Future<Either<NetworkExceptions, List<ShippingAddress>>>
  getAddresses() async => right(addresses);

  @override
  Future<Either<NetworkExceptions, ShippingAddress>> addAddress(
    ShippingAddress address,
  ) async {
    writeCalls++;
    lastWritten = address;
    final failure = writeFailure;
    return failure != null ? left(failure) : right(address);
  }

  @override
  Future<Either<NetworkExceptions, ShippingAddress>> updateAddress(
    String id,
    ShippingAddress address,
  ) async {
    writeCalls++;
    lastWritten = address;
    final failure = writeFailure;
    return failure != null ? left(failure) : right(address);
  }

  @override
  Future<Either<NetworkExceptions, ResolvedMapsLink>> resolveMapsLink(
    String url,
  ) async =>
      resolveResult ??
      right(
        ResolvedMapsLink(latitude: 27.7172, longitude: 85.324, sourceUrl: url),
      );

  @override
  Future<Either<NetworkExceptions, Unit>> deleteAddress(String id) async =>
      right(unit);

  @override
  Future<Either<NetworkExceptions, Unit>> setDefault(String id) async =>
      right(unit);
}

/// Stand-in for the OpenStreetMap surface: a button that reports a dragged
/// pin, so the drag path is testable without fetching a single tile.
Widget _fakeMap(
  BuildContext context,
  double latitude,
  double longitude,
  void Function(double, double) onPinMoved,
) {
  return TextButton(
    key: const Key('fake_pin_drag'),
    onPressed: () => onPinMoved(27.68, 85.31),
    child: const Text('drag'),
  );
}

// ── Harness ──────────────────────────────────────────────────────────────────

Future<void> _pumpAddEdit(
  WidgetTester tester, {
  required _FakeLocationService location,
  required _FakeShippingRepository repository,
  ShippingAddress? address,
  // Tall enough that the lazy ListView builds every field.
  Size surface = const Size(400, 2600),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    initialLocation: '/add',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('addresses')),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => AddEditAddressScreen(address: address),
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        locationCaptureServiceProvider.overrideWithValue(location),
        shippingRepositoryProvider.overrideWithValue(repository),
        pinMapBuilderProvider.overrideWithValue(_fakeMap),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// True while the details sheet is on screen.
bool _sheetIsOpen() =>
    find.byKey(const Key('address_details_sheet')).evaluate().isNotEmpty;

/// Brings the details sheet up if it isn't already — the screen always offers
/// a way back in, so this never has to re-capture a location.
Future<void> _openDetails(WidgetTester tester) async {
  if (_sheetIsOpen()) return;
  await tester.ensureVisible(find.byKey(const Key('open_details_button')));
  await tester.tap(find.byKey(const Key('open_details_button')));
  await tester.pumpAndSettle();
}

Future<void> _dismissDetails(WidgetTester tester) async {
  if (!_sheetIsOpen()) return;
  await tester.tap(find.byKey(const Key('close_details_sheet_button')));
  await tester.pumpAndSettle();
}

/// Fills the required receiver fields so a save isn't blocked by them.
Future<void> _fillReceiver(WidgetTester tester) async {
  await _openDetails(tester);
  await tester.ensureVisible(find.byKey(const Key('receiver_name_field')));
  await tester.enterText(
    find.byKey(const Key('receiver_name_field')),
    'Sita Rai',
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('receiver_phone_field')));
  await tester.enterText(
    find.byKey(const Key('receiver_phone_field')),
    '+9779800000000',
  );
  await tester.pumpAndSettle();
}

/// Saves from wherever the customer is: the sheet's own button when it is up,
/// the screen's primary button when it isn't.
Future<void> _tapSave(WidgetTester tester) async {
  final sheetSave = find.byKey(const Key('details_sheet_save_button'));
  final target = sheetSave.evaluate().isNotEmpty
      ? sheetSave
      : find.byKey(const Key('address_save_button'));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

ShippingAddress _legacyAddress() => const ShippingAddress(
  id: 'legacy-1',
  label: 'Home',
  receiverName: 'Ram Thapa',
  receiverPhone: '+9779811111111',
  country: 'NP',
  addressLine1: 'Jhamsikhel Road 12',
  city: 'Lalitpur',
  state: 'Bagmati',
  zipCode: '44700',
);

void main() {
  // ── Entity / rendering rules ───────────────────────────────────────────────

  group('summaryLine', () {
    test('prefers the customer note over anything else', () {
      const address = ShippingAddress(
        id: '1',
        label: 'Home',
        receiverName: 'A',
        receiverPhone: 'B',
        country: 'NP',
        locationNote: 'Blue gate opposite the pharmacy',
        latitude: 27.7,
        longitude: 85.3,
      );
      expect(address.summaryLine, 'Blue gate opposite the pharmacy');
    });

    test('never renders a null city as "null" or an empty part', () {
      const address = ShippingAddress(
        id: '1',
        label: 'Home',
        receiverName: 'A',
        receiverPhone: 'B',
        country: 'NP',
        addressLine1: 'Jhamsikhel Road 12',
      );
      expect(address.summaryLine, 'Jhamsikhel Road 12');
      expect(address.summaryLine, isNot(contains('null')));
      expect(address.summaryLine, isNot(contains(', ,')));
    });

    test('falls back to the point when there is no note or postal text', () {
      const address = ShippingAddress(
        id: '1',
        label: 'Home',
        receiverName: 'A',
        receiverPhone: 'B',
        country: 'NP',
        latitude: 27.7172,
        longitude: 85.324,
      );
      expect(address.summaryLine, '27.71720, 85.32400');
    });

    test('is never blank', () {
      const address = ShippingAddress(
        id: '1',
        label: 'Home',
        receiverName: 'A',
        receiverPhone: 'B',
        country: 'NP',
      );
      expect(address.summaryLine, isNotEmpty);
    });
  });

  group('location sanity guards', () {
    test('rejects 0,0 and out-of-range coordinates', () {
      expect(isPlausibleCoordinate(0, 0), isFalse);
      expect(isPlausibleCoordinate(0.001, -0.002), isFalse);
      expect(isPlausibleCoordinate(91, 85.3), isFalse);
      expect(isPlausibleCoordinate(27.7, 181), isFalse);
      expect(isPlausibleCoordinate(double.nan, 85.3), isFalse);
      expect(isPlausibleCoordinate(null, null), isFalse);
    });

    test('accepts a real point', () {
      expect(isPlausibleCoordinate(27.7172, 85.324), isTrue);
    });

    test('measures distance well enough to spot a far-away pin', () {
      // Kathmandu → Pokhara is roughly 140 km.
      final metres = distanceBetweenMetres(27.7172, 85.324, 28.2096, 83.9856);
      expect(metres, greaterThan(130000));
      expect(metres, lessThan(160000));
      expect(metres, greaterThan(kFarFromDeviceMetres));
    });
  });

  // ── Current location ───────────────────────────────────────────────────────

  group('use my current location', () {
    testWidgets('captures a point and shows the accuracy', (tester) async {
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 8,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: _FakeShippingRepository(),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('captured_point_card')), findsOneWidget);
      expect(find.text('27.71720, 85.32400'), findsOneWidget);
      expect(find.text('Accurate to about 8 m'), findsOneWidget);
      expect(find.text('Your current location'), findsOneWidget);
    });

    testWidgets('sends locationCapturedFrom 1 for a GPS point', (tester) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 8,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(repository.writeCalls, 1);
      expect(
        repository.lastWritten!.locationCapturedFrom,
        LocationSource.deviceGps,
      );
      expect(repository.lastWritten!.locationAccuracyMetres, 8);
    });

    testWidgets('permission denied explains and offers the alternative', (
      tester,
    ) async {
      final location = _FakeLocationService(const LocationPermissionDenied());
      await _pumpAddEdit(
        tester,
        location: location,
        repository: _FakeShippingRepository(),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('location_message')), findsOneWidget);
      expect(find.textContaining('needs location access'), findsOneWidget);
      expect(find.textContaining('paste a Maps link'), findsWidgets);
      // A plain denial is retryable, so no settings escape hatch is offered.
      expect(find.byKey(const Key('open_settings_button')), findsNothing);
    });

    testWidgets('denied forever offers app settings and opens them', (
      tester,
    ) async {
      final location = _FakeLocationService(
        const LocationPermissionDeniedForever(),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: _FakeShippingRepository(),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('turned off for StyleMint'), findsOneWidget);
      expect(find.text('Open settings'), findsOneWidget);

      await tester.tap(find.byKey(const Key('open_settings_button')));
      await tester.pumpAndSettle();
      expect(location.openedAppSettings, isTrue);
    });

    testWidgets('services off offers the location settings page', (
      tester,
    ) async {
      final location = _FakeLocationService(const LocationServicesDisabled());
      await _pumpAddEdit(
        tester,
        location: location,
        repository: _FakeShippingRepository(),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Location services are off'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('open_settings_button')));
      await tester.pumpAndSettle();
      expect(location.openedLocationSettings, isTrue);
    });

    testWidgets('a timeout says so and stays recoverable', (tester) async {
      final location = _FakeLocationService(const LocationTimedOut());
      await _pumpAddEdit(
        tester,
        location: location,
        repository: _FakeShippingRepository(),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('happens indoors'), findsOneWidget);
      expect(find.byKey(const Key('captured_point_card')), findsNothing);
    });

    testWidgets('a poor fix warns and asks for confirmation before saving', (
      tester,
    ) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 420,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('only accurate to about 420 m'), findsWidgets);

      await _fillReceiver(tester);
      await _tapSave(tester);

      // Confirmation, not refusal.
      expect(find.byKey(const Key('confirm_location_title')), findsOneWidget);
      expect(repository.writeCalls, 0);

      await tester.tap(find.byKey(const Key('confirm_location_button')));
      await tester.pumpAndSettle();
      expect(repository.writeCalls, 1);
    });

    testWidgets('a 0,0 fix is refused before it reaches the API', (
      tester,
    ) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 0,
          longitude: 0,
          accuracyMetres: 5,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('captured_point_card')), findsNothing);
      expect(
        find.textContaining("doesn't look like a real place"),
        findsOneWidget,
      );
      expect(repository.writeCalls, 0);
    });
  });

  // ── Maps link ──────────────────────────────────────────────────────────────

  group('location is read only when the shopper asks for it', () {
    testWidgets('opening the screen reads no location at all', (tester) async {
      // Deliberately a service that *would* hand over a fix: the assertion is
      // not "no permission dialog appeared", it is that nothing read the
      // shopper's position. An already-granted permission is not a standing
      // invitation to collect where they are on screen load.
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 8,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: _FakeShippingRepository(),
      );

      expect(location.promptedCalls, 0);
    });

    testWidgets('the reason is on screen before anything can be tapped', (
      tester,
    ) async {
      final location = _FakeLocationService(const LocationPermissionDenied());
      await _pumpAddEdit(
        tester,
        location: location,
        repository: _FakeShippingRepository(),
      );

      final reason = find.byKey(const Key('location_permission_reason'));
      await tester.ensureVisible(reason);
      expect(reason, findsOneWidget);
      expect(
        find.textContaining('only when you tap this'),
        findsOneWidget,
      );
      // Still nothing read — the reason precedes the prompt, not the reverse.
      expect(location.promptedCalls, 0);
    });

    testWidgets('pasting a Maps link never reads the device position', (
      tester,
    ) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 8,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.ensureVisible(find.byKey(const Key('maps_link_field')));
      await tester.enterText(
        find.byKey(const Key('maps_link_field')),
        'https://maps.app.goo.gl/AbCdEf123',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('resolve_maps_link_button')),
      );
      await tester.tap(find.byKey(const Key('resolve_maps_link_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(repository.writeCalls, 1);
      expect(location.promptedCalls, 0);
    });

    testWidgets('a refusal leaves the address usable and asks no more', (
      tester,
    ) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(const LocationPermissionDenied());
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      expect(location.promptedCalls, 1);

      // Saying no is an ordinary answer, not an error state: the shopper
      // carries straight on with a Maps link and saves.
      await tester.ensureVisible(find.byKey(const Key('maps_link_field')));
      await tester.enterText(
        find.byKey(const Key('maps_link_field')),
        'https://maps.app.goo.gl/AbCdEf123',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('resolve_maps_link_button')),
      );
      await tester.tap(find.byKey(const Key('resolve_maps_link_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(repository.writeCalls, 1);
      // Asked once, because they asked us to. Never again off their own bat.
      expect(location.promptedCalls, 1);
      // A link-derived point is the server's inference to stamp, not ours.
      expect(repository.lastWritten!.locationCapturedFrom, isNull);
    });
  });

  group('paste a Maps link', () {
    testWidgets('resolves the link and shows the point', (tester) async {
      final repository = _FakeShippingRepository();
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(const LocationPermissionDenied()),
        repository: repository,
      );

      await tester.ensureVisible(find.byKey(const Key('maps_link_field')));
      await tester.enterText(
        find.byKey(const Key('maps_link_field')),
        'https://maps.app.goo.gl/AbCdEf123',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('resolve_maps_link_button')),
      );
      await tester.tap(find.byKey(const Key('resolve_maps_link_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('captured_point_card')), findsOneWidget);
      expect(find.text('From your Maps link'), findsOneWidget);
      expect(find.text('27.71720, 85.32400'), findsOneWidget);
    });

    testWidgets('keeps the pasted link verbatim on save', (tester) async {
      final repository = _FakeShippingRepository();
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(const LocationPermissionDenied()),
        repository: repository,
      );

      await tester.ensureVisible(find.byKey(const Key('maps_link_field')));
      await tester.enterText(
        find.byKey(const Key('maps_link_field')),
        'https://maps.app.goo.gl/AbCdEf123',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('resolve_maps_link_button')),
      );
      await tester.tap(find.byKey(const Key('resolve_maps_link_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(
        repository.lastWritten!.mapsLink,
        'https://maps.app.goo.gl/AbCdEf123',
      );
      // The backend stamps SharedMapsLink itself — the app must not send 4.
      expect(repository.lastWritten!.locationCapturedFrom, isNull);
    });

    testWidgets('a rejected link shows the server message on the field', (
      tester,
    ) async {
      final repository = _FakeShippingRepository()
        ..resolveResult = left(
          const NetworkExceptions.validation(
            code: 'validation.invalid',
            field: 'mapsLink',
            message: 'That link is not a supported Maps link.',
          ),
        );
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(const LocationPermissionDenied()),
        repository: repository,
      );

      await tester.ensureVisible(find.byKey(const Key('maps_link_field')));
      await tester.enterText(
        find.byKey(const Key('maps_link_field')),
        'https://example.com/not-a-map',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('resolve_maps_link_button')),
      );
      await tester.tap(find.byKey(const Key('resolve_maps_link_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('That link is not a supported Maps link.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('captured_point_card')), findsNothing);
    });

    testWidgets('a field error from the errors[] array is surfaced too', (
      tester,
    ) async {
      final repository = _FakeShippingRepository()
        ..resolveResult = left(
          const NetworkExceptions.validation(
            code: 'validation.failed',
            errors: [
              FieldErrorVm(
                field: 'mapsLink',
                code: 'link.unresolvable',
                message: 'We could not follow that link.',
              ),
            ],
          ),
        );
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(const LocationPermissionDenied()),
        repository: repository,
      );

      await tester.ensureVisible(find.byKey(const Key('maps_link_field')));
      await tester.enterText(
        find.byKey(const Key('maps_link_field')),
        'https://maps.app.goo.gl/broken',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('resolve_maps_link_button')),
      );
      await tester.tap(find.byKey(const Key('resolve_maps_link_button')));
      await tester.pumpAndSettle();

      expect(find.text('We could not follow that link.'), findsOneWidget);
    });
  });

  // ── Pin ────────────────────────────────────────────────────────────────────

  group('adjust the pin', () {
    testWidgets('dragging the pin sends locationCapturedFrom 2', (
      tester,
    ) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 8,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      // The map lives on the screen behind the sheet, so step back to it.
      await _dismissDetails(tester);
      await tester.ensureVisible(find.byKey(const Key('fake_pin_drag')));
      await tester.tap(find.byKey(const Key('fake_pin_drag')));
      await tester.pumpAndSettle();

      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(
        repository.lastWritten!.locationCapturedFrom,
        LocationSource.manualPin,
      );
      expect(repository.lastWritten!.latitude, 27.68);
      expect(repository.lastWritten!.longitude, 85.31);
    });

    testWidgets('the real map credits OpenStreetMap on screen', (tester) async {
      // The default builder — no override — so this exercises the real
      // flutter_map surface. Tiles can't load in a widget test, which is
      // exactly the offline case: the map must still build, and the OSM
      // credit must still be painted.
      await tester.binding.setSurfaceSize(const Size(400, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddressPinMap(
                latitude: 27.7172,
                longitude: 85.324,
                onPinMoved: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TextSourceAttribution), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

      // The credit sits wholly inside the 180px map box — visible, not
      // clipped away by the rounded corners or pushed off the bottom.
      final mapBox = tester.getRect(find.byKey(const Key('address_pin_map')));
      final credit = tester.getRect(find.byType(TextSourceAttribution));
      expect(mapBox.contains(credit.topLeft), isTrue);
      expect(mapBox.contains(credit.bottomRight - const Offset(1, 1)), isTrue);

      // Tiles come from OSM, tagged with a real user agent.
      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.urlTemplate, contains('tile.openstreetmap.org'));
      expect(
        tileLayer.tileProvider.headers['User-Agent'],
        'flutter_map (app.stylemint.stylemint_mobile_frontend)',
      );

      // No tile error escaped as an exception.
      expect(tester.takeException(), isNull);
    });

    testWidgets('the real pin still drags with no tiles loaded', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      double? movedLat;
      double? movedLng;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddressPinMap(
                latitude: 27.7172,
                longitude: 85.324,
                onPinMoved: (lat, lng) {
                  movedLat = lat;
                  movedLng = lng;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Drag the marker south-east across the map.
      await tester.drag(
        find.byKey(const Key('address_pin_marker')),
        const Offset(30, 30),
      );
      await tester.pump();

      // One callback, at the end of the gesture — not one per frame.
      expect(movedLat, isNotNull);
      expect(movedLng, isNotNull);
      // Dragging right/down moves east and south.
      expect(movedLng! > 85.324, isTrue);
      expect(movedLat! < 27.7172, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  // ── The description box ────────────────────────────────────────────────────

  group('how do we find it', () {
    testWidgets('saving with an empty note succeeds', (tester) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 8,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(repository.writeCalls, 1);
      expect(repository.lastWritten!.locationNote, isEmpty);
    });

    testWidgets('the note is sent when written', (tester) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 8,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('location_note_field')),
      );
      await tester.enterText(
        find.byKey(const Key('location_note_field')),
        'Blue gate opposite the pharmacy, second floor, ring twice',
      );
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(
        repository.lastWritten!.locationNote,
        'Blue gate opposite the pharmacy, second floor, ring twice',
      );
    });

    testWidgets('a note over 500 characters is rejected', (tester) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 8,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('location_note_field')),
      );
      await tester.enterText(
        find.byKey(const Key('location_note_field')),
        'x' * 501,
      );
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      // maxLength clamps the field, so nothing invalid can reach the API.
      expect(repository.lastWritten?.locationNote.length ?? 0, lessThan(501));
    });

    testWidgets('the placeholder teaches the format', (tester) async {
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(const LocationPermissionDenied()),
        repository: _FakeShippingRepository(),
      );
      await _openDetails(tester);

      expect(find.textContaining('Blue gate'), findsOneWidget);
      expect(find.textContaining('second floor'), findsOneWidget);
      expect(find.textContaining('ask for'), findsOneWidget);
    });
  });

  // ── No typed postal fields ─────────────────────────────────────────────────

  testWidgets('the customer is never asked for a street, city or postcode', (
    tester,
  ) async {
    await _pumpAddEdit(
      tester,
      location: _FakeLocationService(const LocationPermissionDenied()),
      repository: _FakeShippingRepository(),
    );
    await _openDetails(tester);

    expect(find.text('Address Line 1'), findsNothing);
    expect(find.text('City'), findsNothing);
    expect(find.text('State/Province'), findsNothing);
    expect(find.text('Zip/Postal Code'), findsNothing);
    // Label, receiver name, receiver phone and country stay.
    expect(find.text('Receiver Name'), findsOneWidget);
    expect(find.text('Receiver Phone'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Save Address As'), findsOneWidget);
  });

  // ── Save guards ────────────────────────────────────────────────────────────

  group('save guards', () {
    testWidgets('blocked with neither a point nor a link', (tester) async {
      final repository = _FakeShippingRepository();
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(const LocationPermissionDenied()),
        repository: repository,
      );

      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(repository.writeCalls, 0);
      expect(find.byKey(const Key('address_save_error')), findsOneWidget);
      expect(find.textContaining('Add a location first'), findsOneWidget);
    });

    testWidgets('a far-away point asks for confirmation but never refuses', (
      tester,
    ) async {
      final repository = _FakeShippingRepository();
      // The only reference point we are ever entitled to is one the shopper
      // asked us to take: they tap "Use my current location" in Pokhara, then
      // drag the pin onto a Kathmandu address ~140 km away.
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 28.2096,
          longitude: 83.9856,
          accuracyMetres: 10,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      await _dismissDetails(tester);
      await tester.ensureVisible(find.byKey(const Key('fake_pin_drag')));
      await tester.tap(find.byKey(const Key('fake_pin_drag')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(find.byKey(const Key('confirm_location_title')), findsOneWidget);
      expect(find.textContaining('km from where you are'), findsOneWidget);
      expect(repository.writeCalls, 0);

      await tester.tap(find.byKey(const Key('confirm_location_button')));
      await tester.pumpAndSettle();
      expect(repository.writeCalls, 1);
    });

    testWidgets('an unanticipated server rejection reads as a field error', (
      tester,
    ) async {
      final repository = _FakeShippingRepository()
        ..writeFailure = const NetworkExceptions.validation(
          code: 'address.outside_service_area',
          field: 'latitude',
          message: "We don't deliver to that area yet.",
        );
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 8,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(find.byKey(const Key('location_error')), findsOneWidget);
      expect(find.text("We don't deliver to that area yet."), findsOneWidget);
    });
  });

  // ── The details sheet ──────────────────────────────────────────────────────

  group('the details sheet', () {
    _FakeLocationService gpsAt({double accuracy = 12}) => _FakeLocationService(
      LocationCaptured(
        latitude: 27.7172,
        longitude: 85.324,
        accuracyMetres: accuracy,
      ),
    );

    testWidgets('capturing a location brings the rest of the form up', (
      tester,
    ) async {
      await _pumpAddEdit(
        tester,
        location: gpsAt(),
        repository: _FakeShippingRepository(),
      );

      expect(find.byKey(const Key('address_details_sheet')), findsNothing);

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('address_details_sheet')), findsOneWidget);
      // The point is named at the top, so the customer knows what these
      // details belong to.
      expect(
        find.text('Your current location, accurate to about 12 m'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('receiver_name_field')), findsOneWidget);
      expect(find.byKey(const Key('receiver_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('address_label_field')), findsOneWidget);
      expect(find.byKey(const Key('location_note_field')), findsOneWidget);
      expect(
        find.byKey(const Key('details_sheet_save_button')),
        findsOneWidget,
      );
    });

    testWidgets('a resolved Maps link opens it and names the link', (
      tester,
    ) async {
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(const LocationPermissionDenied()),
        repository: _FakeShippingRepository(),
      );

      await tester.ensureVisible(find.byKey(const Key('maps_link_field')));
      await tester.enterText(
        find.byKey(const Key('maps_link_field')),
        'https://maps.app.goo.gl/AbCdEf123',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resolve_maps_link_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('address_details_sheet')), findsOneWidget);
      expect(find.text('The spot from your Maps link'), findsOneWidget);
    });

    testWidgets('a dragged pin opens it and names the pin', (tester) async {
      await _pumpAddEdit(
        tester,
        location: gpsAt(),
        repository: _FakeShippingRepository(),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _dismissDetails(tester);

      await tester.ensureVisible(find.byKey(const Key('fake_pin_drag')));
      await tester.tap(find.byKey(const Key('fake_pin_drag')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('address_details_sheet')), findsOneWidget);
      expect(find.text('The pin you placed'), findsOneWidget);
    });

    testWidgets('dismissing keeps the point, and the sheet reopens', (
      tester,
    ) async {
      await _pumpAddEdit(
        tester,
        location: gpsAt(),
        repository: _FakeShippingRepository(),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _dismissDetails(tester);

      // Dismissed, but nothing was thrown away.
      expect(find.byKey(const Key('address_details_sheet')), findsNothing);
      expect(find.byKey(const Key('captured_point_card')), findsOneWidget);
      expect(find.text('27.71720, 85.32400'), findsOneWidget);

      // And the way back in is on the screen, not hidden.
      expect(find.byKey(const Key('details_summary_card')), findsOneWidget);
      expect(find.text('Delivery details still needed'), findsOneWidget);

      await _openDetails(tester);
      expect(find.byKey(const Key('address_details_sheet')), findsOneWidget);
    });

    testWidgets('typed values survive a dismiss and a re-capture', (
      tester,
    ) async {
      final repository = _FakeShippingRepository();
      final location = gpsAt();
      await _pumpAddEdit(tester, location: location, repository: repository);

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await tester.enterText(
        find.byKey(const Key('location_note_field')),
        'Blue gate opposite the pharmacy',
      );
      await tester.pumpAndSettle();
      await _dismissDetails(tester);

      // Capture again, somewhere else entirely.
      location.result = const LocationCaptured(
        latitude: 27.68,
        longitude: 85.29,
        accuracyMetres: 6,
      );
      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('address_details_sheet')), findsOneWidget);
      expect(find.text('Sita Rai'), findsOneWidget);
      expect(find.text('+9779800000000'), findsOneWidget);
      expect(find.text('Blue gate opposite the pharmacy'), findsOneWidget);

      await _tapSave(tester);
      expect(repository.writeCalls, 1);
      expect(repository.lastWritten!.receiverName, 'Sita Rai');
      expect(repository.lastWritten!.locationNote,
          'Blue gate opposite the pharmacy');
      // The newer point won.
      expect(repository.lastWritten!.latitude, 27.68);

      // Saving from the sheet closes it and leaves the screen — it must not
      // pop the sheet and strand the customer on the address form.
      expect(find.byKey(const Key('address_details_sheet')), findsNothing);
      expect(find.text('addresses'), findsOneWidget);
    });

    testWidgets('the screen sends you into the sheet rather than failing '
        'a validation you cannot see', (tester) async {
      final repository = _FakeShippingRepository();
      await _pumpAddEdit(
        tester,
        location: gpsAt(),
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _dismissDetails(tester);

      await tester.ensureVisible(find.byKey(const Key('address_save_button')));
      await tester.tap(find.byKey(const Key('address_save_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('address_details_sheet')), findsOneWidget);
      expect(find.text('Required'), findsWidgets);
      expect(repository.writeCalls, 0);
    });
  });

  // ── What a rejection actually says ─────────────────────────────────────────

  group('server errors reach the customer', () {
    testWidgets('a field rejection shows the server sentence on that field', (
      tester,
    ) async {
      final repository = _FakeShippingRepository()
        ..writeFailure = const NetworkExceptions.validation(
          code: 'validation.out_of_range',
          field: 'locationAccuracyMetres',
          // What the mapper now pulls out of problem-details `detail`.
          message: 'Your location is only accurate to about 140 m — we need '
              '100 m or better. Step outside and try again, or drag the pin.',
        );
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(
          const LocationCaptured(
            latitude: 27.7172,
            longitude: 85.324,
            accuracyMetres: 8,
          ),
        ),
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      // The specific sentence, against the point it is about — and never the
      // problem-details title.
      expect(
        find.textContaining('only accurate to about 140 m'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('location_error')), findsOneWidget);
      expect(find.textContaining('Validation error'), findsNothing);
      // Still on the form, with everything they typed.
      expect(find.byKey(const Key('address_details_sheet')), findsOneWidget);
      expect(find.text('Sita Rai'), findsOneWidget);
    });

    testWidgets('a receiver-field rejection lands on that input', (
      tester,
    ) async {
      final repository = _FakeShippingRepository()
        ..writeFailure = const NetworkExceptions.validation(
          code: 'validation.multiple_errors',
          message: 'Validation error',
          errors: [
            FieldErrorVm(
              field: 'ReceiverPhone',
              code: 'validation.invalid_format',
              message: 'That phone number needs a country code, like +977.',
            ),
          ],
        );
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(
          const LocationCaptured(
            latitude: 27.7172,
            longitude: 85.324,
            accuracyMetres: 8,
          ),
        ),
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(
        find.text('That phone number needs a country code, like +977.'),
        findsOneWidget,
      );
      expect(find.textContaining('Validation error'), findsNothing);
      expect(find.byKey(const Key('address_save_error')), findsNothing);
    });

    testWidgets('a rejection with the sheet dismissed brings it back', (
      tester,
    ) async {
      final repository = _FakeShippingRepository();
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(
          const LocationCaptured(
            latitude: 27.7172,
            longitude: 85.324,
            accuracyMetres: 8,
          ),
        ),
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _dismissDetails(tester);

      repository.writeFailure = const NetworkExceptions.validation(
        code: 'validation.invalid_format',
        field: 'receiverPhone',
        message: 'That phone number needs a country code, like +977.',
      );
      await tester.ensureVisible(find.byKey(const Key('address_save_button')));
      await tester.tap(find.byKey(const Key('address_save_button')));
      await tester.pumpAndSettle();

      expect(repository.writeCalls, 1);
      expect(find.byKey(const Key('address_details_sheet')), findsOneWidget);
      expect(
        find.text('That phone number needs a country code, like +977.'),
        findsOneWidget,
      );
    });

    testWidgets('a rejection with nothing but a generic title still says '
        'something', (tester) async {
      final repository = _FakeShippingRepository()
        ..writeFailure = const NetworkExceptions.validation(
          code: 'validation.out_of_range',
          message: 'Validation error',
        );
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(
          const LocationCaptured(
            latitude: 27.7172,
            longitude: 85.324,
            accuracyMetres: 8,
          ),
        ),
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(find.byKey(const Key('address_save_error')), findsOneWidget);
      expect(find.textContaining('Validation error'), findsNothing);
      expect(
        find.textContaining('out of the allowed range'),
        findsOneWidget,
      );
    });

    testWidgets('an error below the fold is scrolled into view', (
      tester,
    ) async {
      const message = 'Tell us which gate — "second floor" alone is not '
          'enough for a rider who has never been here.';
      final repository = _FakeShippingRepository()
        ..writeFailure = const NetworkExceptions.validation(
          code: 'validation.too_short',
          field: 'locationNote',
          message: message,
        );
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(
          const LocationCaptured(
            latitude: 27.7172,
            longitude: 85.324,
            accuracyMetres: 8,
          ),
        ),
        repository: repository,
        // Short enough that the note sits below the fold of the sheet.
        surface: const Size(320, 480),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();
      await _fillReceiver(tester);
      await _tapSave(tester);

      expect(find.text(message), findsOneWidget);

      // Visible, not merely present: the sheet scrolled to it.
      final error = tester.getRect(find.text(message));
      final sheet = tester.getRect(
        find.byKey(const Key('address_details_sheet')),
      );
      expect(error.top, greaterThanOrEqualTo(sheet.top));
      expect(error.bottom, lessThanOrEqualTo(sheet.bottom));
    });

    test('problem details: the specific detail beats the generic title', () {
      final failure = mapDioExceptionToNetworkException(
        DioException(
          requestOptions: RequestOptions(path: '/v1/addresses'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/v1/addresses'),
            statusCode: 400,
            data: <String, dynamic>{
              'type': 'https://stylemint/errors/validation',
              'title': 'Validation error',
              'detail':
                  'Your location is only accurate to about 140 m — we need '
                  '100 m or better.',
              'errorCode': 'validation.out_of_range',
              'field': 'locationAccuracyMetres',
            },
          ),
        ),
      );

      expect(
        NetworkExceptions.getMessage(failure),
        'Your location is only accurate to about 140 m — we need 100 m or '
        'better.',
      );
    });

    test('a body with only a title never renders as "Validation error"', () {
      final failure = mapDioExceptionToNetworkException(
        DioException(
          requestOptions: RequestOptions(path: '/v1/addresses'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/v1/addresses'),
            statusCode: 400,
            data: <String, dynamic>{
              'title': 'Validation error',
              'errorCode': 'validation.out_of_range',
            },
          ),
        ),
      );

      final message = NetworkExceptions.getMessage(failure);
      expect(message, isNot(contains('Validation error')));
      expect(message, contains('out of the allowed range'));
    });
  });

  // ── Legacy addresses ───────────────────────────────────────────────────────

  group('legacy postal-only addresses', () {
    test('are flagged as legacy and still render their postal text', () {
      final address = _legacyAddress();
      expect(address.isLegacy, isTrue);
      expect(address.hasLocation, isFalse);
      expect(
        address.summaryLine,
        'Jhamsikhel Road 12, Lalitpur, Bagmati, 44700',
      );
    });

    testWidgets('list a legacy address with a hint to add a location', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _FakeShippingRepository(
        addresses: [_legacyAddress()],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shippingRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: ShippingAddressesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jhamsikhel Road 12, Lalitpur, Bagmati, 44700'),
          findsOneWidget);
      expect(find.byKey(const Key('legacy_address_hint')), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('view screen renders one without a blank or "null" line', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: ViewAddressScreen(address: _legacyAddress())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('legacy_view_notice')), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
      expect(find.text('Jhamsikhel Road 12, Lalitpur, Bagmati, 44700'),
          findsOneWidget);
    });

    testWidgets('opens for editing and says a location is needed first', (
      tester,
    ) async {
      final repository = _FakeShippingRepository();
      await _pumpAddEdit(
        tester,
        location: _FakeLocationService(const LocationPermissionDenied()),
        repository: repository,
        address: _legacyAddress(),
      );

      // The warning is up front, before any tap on Save.
      expect(find.byKey(const Key('legacy_location_banner')), findsOneWidget);
      expect(find.textContaining('saved the old way'), findsOneWidget);

      // Existing receiver details are preserved for editing.
      await _openDetails(tester);
      await tester.ensureVisible(find.byKey(const Key('receiver_name_field')));
      await tester.pumpAndSettle();
      expect(find.text('Ram Thapa'), findsOneWidget);

      await _tapSave(tester);
      expect(repository.writeCalls, 0);
      expect(find.textContaining('Add a location first'), findsOneWidget);
    });

    testWidgets('a legacy edit saves once a location is added', (tester) async {
      final repository = _FakeShippingRepository();
      final location = _FakeLocationService(
        const LocationCaptured(
          latitude: 27.7172,
          longitude: 85.324,
          accuracyMetres: 9,
        ),
      );
      await _pumpAddEdit(
        tester,
        location: location,
        repository: repository,
        address: _legacyAddress(),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('legacy_location_banner')), findsNothing);

      await _tapSave(tester);
      expect(repository.writeCalls, 1);
      expect(repository.lastWritten!.latitude, 27.7172);
    });
  });

  // ── Layout ─────────────────────────────────────────────────────────────────

  testWidgets('no overflow at 320dp with 1.3x text scale', (tester) async {
    final location = _FakeLocationService(
      const LocationCaptured(
        latitude: 27.7172,
        longitude: 85.324,
        accuracyMetres: 8,
      ),
    );
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('addresses')),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, _) => const AddEditAddressScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationCaptureServiceProvider.overrideWithValue(location),
          shippingRepositoryProvider.overrideWithValue(
            _FakeShippingRepository(),
          ),
          pinMapBuilderProvider.overrideWithValue(_fakeMap),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.3,
            maxScaleFactor: 1.3,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // With a captured point the map and accuracy row are on screen too. The
    // sheet comes up over them, so step back to the screen to scroll it.
    await tester.tap(find.byKey(const Key('use_current_location_button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _dismissDetails(tester);

    // Scroll the whole form past the viewport so every row lays out at this
    // width — a lazy ListView would otherwise never build the lower fields.
    final list = find.byType(ListView);
    for (var i = 0; i < 12; i++) {
      await tester.drag(list, const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the sheet fits 320dp at 1.3x with the keyboard up', (
    tester,
  ) async {
    final location = _FakeLocationService(
      const LocationCaptured(
        latitude: 27.7172,
        longitude: 85.324,
        accuracyMetres: 420,
      ),
    );
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('addresses')),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, _) => const AddEditAddressScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationCaptureServiceProvider.overrideWithValue(location),
          shippingRepositoryProvider.overrideWithValue(
            _FakeShippingRepository(),
          ),
          pinMapBuilderProvider.overrideWithValue(_fakeMap),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              // A software keyboard taking half a short screen: the worst
              // case for a sheet full of text fields.
              data: media.copyWith(
                viewInsets: const EdgeInsets.only(bottom: 300),
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('use_current_location_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('address_details_sheet')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The sheet never grows past the space the keyboard leaves it.
    final sheetRect = tester.getRect(
      find.byKey(const Key('address_details_sheet')),
    );
    expect(sheetRect.height, lessThanOrEqualTo(640 - 300));

    // Save stays reachable, and every field is reachable by scrolling.
    expect(find.byKey(const Key('details_sheet_save_button')), findsOneWidget);
    final scroller = find.descendant(
      of: find.byKey(const Key('address_details_sheet')),
      matching: find.byType(SingleChildScrollView),
    );
    for (var i = 0; i < 10; i++) {
      await tester.drag(scroller, const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.byKey(const Key('location_note_field')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
