import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/data/datasources/unit_markers_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/data/repositories/unit_markers_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_scan.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/unit_marker_format.dart';

import '../codes/support/recording_api_client.dart';

/// A 26-character Crockford value, the shape a real tag carries.
const String kMarker = 'ABCDEFGHJKMNPQRSTVWXYZ0123';
const String kReference = 'UM7K2P9QRSTV';
const String kMarkerId = '11111111-1111-1111-1111-111111111111';

class _AlwaysOnline implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

UnitMarkersRepository _repo(Object? Function(RecordedCall) respond) =>
    UnitMarkersRepositoryImpl(
      remoteDataSource: UnitMarkersRemoteDataSource(
        apiClient: RecordingApiClient(respond),
      ),
      networkInfo: _AlwaysOnline(),
    );

DioException _status(int code, {Map<String, dynamic>? body}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/'),
    statusCode: code,
    data: body,
  ),
);

void main() {
  group('marker format', () {
    test('accepts a 26-character Crockford value', () {
      expect(UnitMarkerFormat.normalize(kMarker), kMarker);
    });

    test('applies the read-alike substitutions a printed tag needs', () {
      // I and L read as 1, O reads as 0 — the same rule the backend applies,
      // so a tag read aloud still resolves.
      final spoken = 'IL${kMarker.substring(2)}'.replaceRange(
        20,
        21,
        'O',
      );
      final normalized = UnitMarkerFormat.normalize(spoken);
      expect(normalized, isNotNull);
      expect(normalized!.startsWith('11'), isTrue);
      expect(normalized.length, UnitMarkerFormat.length);
    });

    test('drops grouping characters but refuses a truncated value', () {
      expect(
        UnitMarkerFormat.normalize(
          '${kMarker.substring(0, 13)}-${kMarker.substring(13)}',
        ),
        kMarker,
      );
      // A truncated credential that happened to be well formed would be a
      // different tag, so short and long both fail rather than being padded
      // or cut.
      expect(UnitMarkerFormat.normalize(kMarker.substring(0, 25)), isNull);
      expect(UnitMarkerFormat.normalize('${kMarker}0'), isNull);
    });

    test('refuses the excluded Crockford letters and an 8-char code', () {
      expect(UnitMarkerFormat.normalize('U' * 26), isNull);
      expect(UnitMarkerFormat.normalize('ABCD1234'), isNull);
    });

    test('a reference is UM plus ten alphabet characters', () {
      expect(UnitMarkerReferenceFormat.normalize(kReference), kReference);
      expect(UnitMarkerReferenceFormat.normalize(kMarker), isNull);
      expect(UnitMarkerReferenceFormat.normalize('XX7K2P9QRSTV'), isNull);
    });
  });

  group('provisioning — the one-time secret', () {
    test('maps the real ProvisionedUnitMarkerVm payload', () async {
      final repo = _repo(
        (call) => <Map<String, dynamic>>[
          {
            'id': kMarkerId,
            'reference': kReference,
            'secret': kMarker,
            'productId': '22222222-2222-2222-2222-222222222222',
            'productVariantId': '33333333-3333-3333-3333-333333333333',
            'provisionedUtc': '2026-09-20T08:00:00Z',
          },
        ],
      );
      final result = await repo.provision(
        productVariantId: '33333333-3333-3333-3333-333333333333',
        quantity: 1,
      );
      final markers = result.getOrElse((_) => const []);
      expect(markers, hasLength(1));
      expect(markers.single.secret, kMarker);
      expect(markers.single.reference, kReference);
      expect(
        markers.single.provisionedAt,
        DateTime.utc(2026, 9, 20, 8),
      );
    });

    test('posts to the vendor route with an Idempotency-Key', () async {
      late RecordedCall recorded;
      final repo = _repo((call) {
        recorded = call;
        return <Map<String, dynamic>>[];
      });
      await repo.provision(productVariantId: 'v1', quantity: 3);
      expect(recorded.uri, '/v1/vendor/unit-markers');
      expect(recorded.header('Idempotency-Key'), isNotNull);
      expect(
        (recorded.data! as Map<String, dynamic>)['quantity'],
        3,
      );
    });

    test('toString never names the secret', () {
      const marker = ProvisionedUnitMarker(
        id: kMarkerId,
        reference: kReference,
        secret: kMarker,
        productId: 'p',
        productVariantId: 'v',
        provisionedAt: null,
      );
      expect(marker.toString(), isNot(contains(kMarker)));
      expect(marker.toString(), contains(kReference));
      // withoutSecret keeps the tag identifiable and drops the credential.
      expect(marker.withoutSecret.reference, kReference);
      expect(marker.withoutSecret, isA<UnitMarker>());
    });
  });

  group('scan — the marker never reaches a URL', () {
    test('sends the marker in the body, not the path or the query', () async {
      late RecordedCall recorded;
      final repo = _repo((call) {
        recorded = call;
        return <String, dynamic>{
          'unitMarkerId': kMarkerId,
          'reference': kReference,
          'status': 'Active',
          'productId': 'p1',
          'productName': 'Kathmandu Trail Jacket',
          'isBoundToSale': true,
          'inServiceSinceUtc': '2026-09-18T04:30:00Z',
          'scannedUtc': '2026-09-20T09:15:00Z',
          'placeKind': 'NotStated',
        };
      });
      await repo.scan(marker: kMarker, via: CodeScanVia.qr);

      expect(recorded.uri, '/v1/public/unit-markers/scan');
      expect(recorded.uri, isNot(contains(kMarker)));
      expect(recorded.query?.toString() ?? '', isNot(contains(kMarker)));
      expect((recorded.data! as Map<String, dynamic>)['marker'], kMarker);
      expect((recorded.data! as Map<String, dynamic>)['via'], 'Qr');
    });

    test('maps the real UnitMarkerScanResultVm payload', () async {
      final repo = _repo(
        (_) => <String, dynamic>{
          'unitMarkerId': kMarkerId,
          'reference': kReference,
          'status': 'Active',
          'productId': 'p1',
          'productName': 'Kathmandu Trail Jacket',
          'isBoundToSale': true,
          'inServiceSinceUtc': '2026-09-18T04:30:00Z',
          'scannedUtc': '2026-09-20T09:15:00Z',
          'placeKind': 'VendorStore',
          'vendorStoreId': 's1',
          'vendorStoreName': 'Durbar Marg Flagship',
          'vendorStoreCity': 'Kathmandu',
        },
      );
      final reading = (await repo.scan(
        marker: kMarker,
        via: CodeScanVia.nfc,
      )).getOrElse((_) => throw StateError('expected a reading'));

      expect(reading.status, UnitMarkerStatus.active);
      expect(reading.isBoundToSale, isTrue);
      expect(reading.inServiceSince, DateTime.utc(2026, 9, 18, 4, 30));
      expect(reading.hasProvenPlace, isTrue);
      expect(reading.vendorStoreCity, 'Kathmandu');
    });

    test('an unbound tag maps to a reading, not to a failure', () async {
      final repo = _repo(
        (_) => <String, dynamic>{
          'unitMarkerId': kMarkerId,
          'reference': kReference,
          'status': 'Active',
          'productId': 'p1',
          'isBoundToSale': false,
          'scannedUtc': '2026-09-20T09:15:00Z',
          'placeKind': 'NotStated',
        },
      );
      final reading = (await repo.scan(
        marker: kMarker,
        via: CodeScanVia.qr,
      )).getOrElse((_) => throw StateError('expected a reading'));

      expect(reading.isBoundToSale, isFalse);
      // Null is *not bound*, never a placeholder date.
      expect(reading.inServiceSince, isNull);
      expect(reading.placeKind, UnitScanPlaceKind.notStated);
      expect(reading.hasProvenPlace, isFalse);
      expect(reading.productName, isNull);
    });

    test('an unknown status never degrades into Active', () async {
      final repo = _repo(
        (_) => <String, dynamic>{
          'unitMarkerId': kMarkerId,
          'reference': kReference,
          'status': 'Quarantined',
          'productId': 'p1',
          'isBoundToSale': false,
          'placeKind': 'NotStated',
        },
      );
      final reading = (await repo.scan(
        marker: kMarker,
        via: CodeScanVia.qr,
      )).getOrElse((_) => throw StateError('expected a reading'));

      expect(reading.status, UnitMarkerStatus.unrecognised);
      expect(reading.isActiveTag, isFalse);
    });

    test('a marker StyleMint never issued is a 404 failure', () async {
      final repo = _repo((_) => _status(404));
      final result = await repo.scan(marker: kMarker, via: CodeScanVia.qr);
      expect(result.isLeft(), isTrue);
    });
  });

  group('unit passport — 404 reads as not bound', () {
    test('404 becomes UnitPassportUnbound, not a failure', () async {
      final repo = _repo((_) => _status(404));
      final result = await repo.unitPassport(kMarkerId);

      expect(result.isRight(), isTrue, reason: '404 must not be an error');
      expect(
        result.getOrElse((_) => throw StateError('expected a result')),
        isA<UnitPassportUnbound>(),
      );
    });

    test('a real failure is still a failure', () async {
      final repo = _repo((_) => _status(503));
      expect((await repo.unitPassport(kMarkerId)).isLeft(), isTrue);
    });

    test('the opaque id goes in the path and nothing else does', () async {
      late RecordedCall recorded;
      final repo = _repo((call) {
        recorded = call;
        return <String, dynamic>{
          'vendorBusinessName': 'Himalayan Outfitters',
          'authenticityStatement': 'Sold by the listing owner.',
          'schemaVersion': 2,
          'subject': {
            'scope': 'Unit',
            'scopeExplanation':
                'This passport identifies one physical item, because a marker '
                'on it is bound to an order line.',
            'identifiesPhysicalUnit': true,
          },
          'claims': <dynamic>[],
        };
      });
      await repo.unitPassport(kMarkerId);
      expect(recorded.uri, '/v1/public/unit-passports/$kMarkerId');
      expect(recorded.uri, isNot(contains(kMarker)));
    });

    test('scope arrives as a name and Unit is not faked', () async {
      final repo = _repo(
        (_) => <String, dynamic>{
          'vendorBusinessName': 'Himalayan Outfitters',
          'authenticityStatement': 'Sold by the listing owner.',
          'schemaVersion': 2,
          // A passport that narrows only to the listing says so. It is not a
          // degraded Unit and must never be rendered as one.
          'subject': {
            'scope': 'Listing',
            'scopeExplanation':
                'This passport describes a catalogue listing, not one item.',
            'identifiesPhysicalUnit': false,
          },
          'claims': <dynamic>[],
        },
      );
      final found =
          (await repo.unitPassport(kMarkerId)).getOrElse(
                (_) => throw StateError('expected a passport'),
              )
              as UnitPassportFound;

      expect(found.passport.subject!.scope, 'Listing');
      expect(found.passport.subject!.identifiesPhysicalUnit, isFalse);
    });
  });

  group('binding — refusal and correction are different outcomes', () {
    test('a successful bind maps the real UnitMarkerBindingVm', () async {
      final repo = _repo(
        (_) => <String, dynamic>{
          'id': 'b1',
          'markerReference': kReference,
          'orderId': 'o1',
          'subOrderId': 'so1',
          'subOrderLineId': 'sol1',
          'boundAtStage': 'Pack',
          'boundUtc': '2026-09-20T07:00:00Z',
          'correctsBindingId': null,
          'supersededUtc': null,
          'supersededReason': null,
        },
      );
      final outcome = (await repo.bind(
        marker: kMarker,
        subOrderLineId: 'sol1',
        stage: UnitBindingStage.pack,
      )).getOrElse((_) => throw StateError('expected an outcome'));

      expect(outcome, isA<UnitMarkerBound>());
      final binding = (outcome as UnitMarkerBound).binding;
      expect(binding.boundAtStage, UnitBindingStage.pack);
      expect(binding.isLive, isTrue);
      expect(binding.isCorrection, isFalse);
    });

    test(
      '409 is a refusal carrying the server sentence, not an error',
      () async {
        const sentence =
            'This marker is already bound to another order line. Record a '
            'correction if the first binding was wrong.';
        final repo = _repo(
          (_) => _status(
            409,
            body: {
              'errorCode': 'state.conflict',
              'detail': sentence,
              'field': 'marker',
            },
          ),
        );
        final outcome = (await repo.bind(
          marker: kMarker,
          subOrderLineId: 'sol1',
          stage: UnitBindingStage.pack,
        )).getOrElse((_) => throw StateError('expected a refusal'));

        expect(outcome, isA<UnitMarkerBindRefused>());
        final refusal = (outcome as UnitMarkerBindRefused).refusal;
        expect(refusal.kind, UnitMarkerBindRefusalKind.alreadyBound);
        // Rendered verbatim: the app never rewrites the backend's sentence.
        expect(refusal.message, sentence);
      },
    );

    test('a post-Delivered rule violation is its own refusal kind', () async {
      const sentence =
          'This order has already reached the buyer. Which physical item they '
          'hold can no longer be observed, so no marker can be bound or '
          're-bound to it.';
      final repo = _repo(
        (_) => _status(
          400,
          body: {
            'errorCode': 'rule.violation',
            'detail': sentence,
            'field': 'subOrderLineId',
          },
        ),
      );
      final outcome = (await repo.correct(
        marker: kMarker,
        subOrderLineId: 'sol1',
        stage: UnitBindingStage.pack,
        reason: 'Scanned the wrong parcel.',
      )).getOrElse((_) => throw StateError('expected a refusal'));

      final refusal = (outcome as UnitMarkerBindRefused).refusal;
      expect(refusal.kind, UnitMarkerBindRefusalKind.ruleRefused);
      expect(refusal.message, sentence);
    });

    test('a correction sends the reason the backend demands', () async {
      late RecordedCall recorded;
      final repo = _repo((call) {
        recorded = call;
        return <String, dynamic>{
          'id': 'b2',
          'markerReference': kReference,
          'orderId': 'o1',
          'subOrderId': 'so1',
          'subOrderLineId': 'sol2',
          'boundAtStage': 'Handover',
          'boundUtc': '2026-09-20T09:00:00Z',
          'correctsBindingId': 'b1',
        };
      });
      final outcome = (await repo.correct(
        marker: kMarker,
        subOrderLineId: 'sol2',
        stage: UnitBindingStage.handover,
        reason: 'Tagged the jacket instead of the trousers.',
      )).getOrElse((_) => throw StateError('expected an outcome'));

      expect(recorded.uri, '/v1/vendor/unit-markers/bindings/correct');
      expect(recorded.uri, isNot(contains(kMarker)));
      final body = recorded.data! as Map<String, dynamic>;
      expect(body['reason'], 'Tagged the jacket instead of the trousers.');
      expect(body['marker'], kMarker);
      expect((outcome as UnitMarkerBound).binding.isCorrection, isTrue);
    });

    test(
      'a superseded row keeps the seller words, never a canned one',
      () async {
        final repo = _repo(
          (_) => <dynamic>[
            {
              'id': 'b1',
              'markerReference': kReference,
              'orderId': 'o1',
              'subOrderId': 'so1',
              'subOrderLineId': 'sol1',
              'boundAtStage': 'Pack',
              'boundUtc': '2026-09-20T07:00:00Z',
              'supersededUtc': '2026-09-20T09:00:00Z',
              'supersededReason': 'Tagged the jacket instead of the trousers.',
            },
          ],
        );
        final rows = (await repo.bindingHistory(
          kReference,
        )).getOrElse((_) => const []);

        expect(rows.single.isLive, isFalse);
        expect(
          rows.single.supersededReason,
          'Tagged the jacket instead of the trousers.',
        );
      },
    );

    test('marker-named routes use the reference, never the secret', () async {
      late RecordedCall recorded;
      final repo = _repo((call) {
        recorded = call;
        return <dynamic>[];
      });
      await repo.scanHistory(kReference);
      expect(
        recorded.uri,
        '/v1/vendor/unit-markers/$kReference/scans',
      );
      expect(recorded.uri, isNot(contains(kMarker)));
    });
  });

  group('order line stage mapping mirrors the backend bridge', () {
    test('Packed and ReadyToShip are bindable', () {
      expect(orderLineStageFromSubOrderState(13).allowsBinding, isTrue);
      expect(orderLineStageFromSubOrderState(4).allowsBinding, isTrue);
    });

    test('courier states stay bindable', () {
      for (final state in [5, 6, 10, 11, 14]) {
        expect(
          orderLineStageFromSubOrderState(state),
          OrderLineFulfilmentStage.handedOver,
          reason: 'state $state',
        );
      }
    });

    test('Delivered and Returned close binding and correction', () {
      for (final state in [7, 9]) {
        final stage = orderLineStageFromSubOrderState(state);
        expect(stage, OrderLineFulfilmentStage.delivered);
        expect(stage.allowsBinding, isFalse);
        expect(stage.allowsCorrection, isFalse);
        // Closed, and with a reason — never silently absent.
        expect(stage.bindingClosedReason, isNotNull);
        expect(stage.bindingClosedHeading, 'Correction is closed');
      }
    });

    test('an unknown state is not treated as an open door', () {
      final stage = orderLineStageFromSubOrderState(99);
      expect(stage, OrderLineFulfilmentStage.unrecognised);
      expect(stage.allowsBinding, isFalse);
      expect(stage.bindingClosedReason, isNotNull);
    });
  });
}
