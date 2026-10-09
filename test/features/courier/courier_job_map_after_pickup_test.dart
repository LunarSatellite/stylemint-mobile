import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_job_mapper.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/rider_locator.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_job_map.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/location_capture_service.dart';

import 'courier_job_mapper_test.dart' show contractJobJson;

/// No GPS fix: the case that left the rider with no line after pick-up.
class _NoFixLocator implements RiderLocator {
  @override
  Future<LocationCaptureResult> locate() async =>
      const LocationPermissionDenied();

  @override
  Stream<LocationCaptured> follow() => const Stream.empty();

  @override
  Future<void> openSettings(LocationCaptureResult? reason) async {}
}

/// OSRM unreachable: the dashed straight line stands in.
class _NoRoutePlanner implements CourierRoutePlanner {
  final List<List<GeoPoint>> asked = [];

  @override
  Future<CourierRoute?> plan(List<GeoPoint> stops) async {
    asked.add(stops);
    return null;
  }
}

CourierJob _job(String status) =>
    CourierJobMapper.job(contractJobJson(status: status));

void main() {
  late _NoRoutePlanner planner;

  setUp(() => planner = _NoRoutePlanner());

  Widget map(CourierJob job) => ProviderScope(
    overrides: [
      riderLocatorProvider.overrideWithValue(_NoFixLocator()),
      courierRoutePlannerProvider.overrideWithValue(planner),
      courierMapTilesEnabledProvider.overrideWithValue(false),
    ],
    child: MaterialApp(
      home: Scaffold(body: CourierJobMap(job: job)),
    ),
  );

  List<Polyline> lines(WidgetTester tester) => tester
      .widgetList<PolylineLayer>(find.byType(PolylineLayer))
      .expand((layer) => layer.polylines)
      .toList();

  testWidgets(
    'after pick-up, with no GPS fix, both pins, the shop-to-door line and '
    'the Google Maps button stay',
    (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(map(_job('Assigned')));
      await tester.pump();
      await tester.pump();
      expect(lines(tester), hasLength(1));

      // "Picked up": the same map, re-read with the new status.
      await tester.pumpWidget(map(_job('PickedUp')));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byKey(CourierJobMap.openExternalKey), findsOneWidget);
      final line = lines(tester);
      expect(line, hasLength(1), reason: 'the link between the two places');
      expect(line.single.points, hasLength(2));
      expect(planner.asked.last, hasLength(2));
    },
  );

  test('Google Maps goes to the door once the parcel is collected', () {
    final picked = CourierJobMap.externalDirectionsUri(_job('PickedUp'))!;
    expect(picked.queryParameters['destination'], '27.689,85.315');
    expect(picked.queryParameters.containsKey('waypoints'), isFalse);

    final awaiting = CourierJobMap.externalDirectionsUri(
      _job('AwaitingConfirmation'),
    )!;
    expect(awaiting.queryParameters['destination'], '27.689,85.315');
  });

  test('before pick-up it goes to the door through the shop', () {
    final assigned = CourierJobMap.externalDirectionsUri(_job('Assigned'))!;
    expect(assigned.queryParameters['destination'], '27.689,85.315');
    expect(assigned.queryParameters['waypoints'], '27.6794,85.3288');
  });
}
