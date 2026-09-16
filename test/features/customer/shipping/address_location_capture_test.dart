import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
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
  _FakeLocationService(this.result, {this.quietResult});

  LocationCaptureResult result;

  /// What the silent, no-prompt reference read returns. Defaults to a plain
  /// denial so most tests get no far-from-you reference point.
  LocationCaptureResult? quietResult;

  bool openedAppSettings = false;
  bool openedLocationSettings = false;
  int promptedCalls = 0;

  @override
  Future<LocationCaptureResult> capture({
    Duration timeout = const Duration(seconds: 15),
    bool requestPermission = true,
  }) async {
    if (!requestPermission) {
      return quietResult ?? const LocationPermissionDenied();
    }
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

/// Stand-in for the GoogleMap surface: a button that reports a dragged pin,
/// so the drag path is testable without a platform view or an API key.
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

/// Fills the required receiver fields so a save isn't blocked by them.
Future<void> _fillReceiver(WidgetTester tester) async {
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

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('address_save_button')));
  await tester.tap(find.byKey(const Key('address_save_button')));
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
      // Device is in Kathmandu; the pasted link resolves there too, so move
      // the device reference far away instead.
      final location = _FakeLocationService(
        const LocationPermissionDenied(),
        quietResult: const LocationCaptured(
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

    // With a captured point the map and accuracy row are on screen too.
    await tester.tap(find.byKey(const Key('use_current_location_button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Scroll the whole form past the viewport so every row lays out at this
    // width — a lazy ListView would otherwise never build the lower fields.
    final list = find.byType(ListView);
    for (var i = 0; i < 12; i++) {
      await tester.drag(list, const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
