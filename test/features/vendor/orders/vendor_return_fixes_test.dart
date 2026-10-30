import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_return_request_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_return_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_return_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_return_error_copy.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_return_pickup_panel.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';

import '../../orders_test_harness.dart';

Map<String, dynamic> _row(Map<String, dynamic> extra) => {
  'id': 'ret-1',
  'orderId': 'o-1',
  'orderNumber': 'NK2026-00042',
  'subOrderId': 's-1',
  'subOrderLineId': 'l-1',
  'productTitleSnapshot': 'Linen shirt',
  'quantity': 1,
  'reason': 'Damaged',
  'state': 2,
  'submittedUtc': '2026-10-28T08:00:00Z',
  ...extra,
};

VendorReturnRequest _request(Map<String, dynamic> extra) =>
    VendorReturnRequestDto.fromJson(_row(extra)).toDomain();

ReturnPickup _pickup(Map<String, dynamic> extra) => ReturnPickup.fromJson({
  'id': 'p-1',
  'returnRequestId': 'ret-1',
  'trackingNumber': 'SM-R-00000042',
  'state': 1,
  'requestedUtc': '2026-10-28T08:00:00Z',
  ...extra,
});

void main() {
  group('vendor return DTO reads resolution and cancelReason', () {
    test('resolution: number or name; refund when absent', () {
      expect(_request({}).resolution, VendorReturnResolution.refund);
      expect(
        _request({'resolution': 1}).resolution,
        VendorReturnResolution.refund,
      );
      expect(
        _request({'resolution': 2}).resolution,
        VendorReturnResolution.replacement,
      );
      expect(
        _request({'resolution': 'Replacement'}).resolution,
        VendorReturnResolution.replacement,
      );
    });

    test('cancelReason values, unknown when absent or new', () {
      VendorReturnCancelReason reason(Object? wire) =>
          _request({'state': 5, 'cancelReason': wire}).cancelReason;
      expect(reason('buyer_cancelled'), VendorReturnCancelReason.buyer);
      expect(
        reason('buyer_unavailable'),
        VendorReturnCancelReason.buyerUnavailable,
      );
      expect(
        reason('handover_refused'),
        VendorReturnCancelReason.handoverRefused,
      );
      expect(reason('support'), VendorReturnCancelReason.support);
      expect(reason(null), VendorReturnCancelReason.unknown);
      expect(reason('alien_abduction'), VendorReturnCancelReason.unknown);
    });
  });

  group('seller return card labels', () {
    String label(Map<String, dynamic> extra) =>
        VendorReturnCard.statusLabel(_request(extra));

    test('completed: what the buyer gets', () {
      expect(label({'state': 4, 'resolution': 1}), 'Refund started');
      expect(label({'state': 4, 'resolution': 2}), 'Replacement sent');
      expect(label({'state': 4}), 'Refund started');
    });

    test('cancelled: who ended it', () {
      expect(
        label({'state': 5, 'cancelReason': 'buyer_cancelled'}),
        'Cancelled by buyer',
      );
      expect(
        label({'state': 5, 'cancelReason': 'buyer_unavailable'}),
        'Pickup failed',
      );
      expect(
        label({'state': 5, 'cancelReason': 'handover_refused'}),
        'Customer refused',
      );
      expect(
        label({'state': 5, 'cancelReason': 'support'}),
        'Cancelled by support',
      );
      // Never blames the buyer without the server saying so.
      expect(label({'state': 5}), 'Cancelled');
    });

    test('the other states are unchanged', () {
      expect(label({'state': 1}), 'Needs review');
      expect(label({'state': 2}), 'Awaiting return');
      expect(label({'state': 3}), 'Rejected');
    });

    testWidgets('the card shows the label', (tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: VendorReturnCard(
              request: _request({'state': 4, 'resolution': 2}),
              busy: false,
              onApprove: () {},
              onReject: () {},
              onComplete: () {},
            ),
          ),
        ),
      );
      expect(find.text('Replacement sent'), findsOneWidget);
      expect(find.text('Refund started'), findsNothing);
    });
  });

  group('"Mark received" stays locked until the rider hands it over', () {
    test('a rider return with no receivedUtc is locked, Cancelled too', () {
      for (final stage in const [
        'SearchingRider',
        'Collected',
        'AwaitingSellerConfirmation',
        'AttemptFailed',
        'NeedsSupport',
        'Cancelled',
        'SomethingNew',
      ]) {
        expect(
          _pickup({'mode': 'Rider', 'stage': stage}).blocksSellerCompletion,
          isTrue,
          reason: stage,
        );
      }
      expect(_pickup({'mode': 'Rider'}).blocksSellerCompletion, isTrue);
    });

    test('received (by the rider hand-over or support) unlocks it', () {
      expect(
        _pickup({
          'mode': 'Rider',
          'stage': 'Cancelled',
          'receivedUtc': '2026-10-29T09:00:00Z',
        }).blocksSellerCompletion,
        isFalse,
      );
      expect(
        _pickup({
          'mode': 'Rider',
          'stage': 'ReceivedBySeller',
        }).blocksSellerCompletion,
        isFalse,
      );
    });

    test('legacy and older returns are never held back', () {
      expect(
        _pickup({'mode': 'Legacy', 'stage': 'Cancelled'}).blocksSellerCompletion,
        isFalse,
      );
      expect(_pickup({'stage': 'Cancelled'}).blocksSellerCompletion, isFalse);
    });

    test('from the list row alone, Cancelled is locked too', () {
      expect(VendorReturnPickupScope.lockedByListStage('Cancelled'), isTrue);
      expect(
        VendorReturnPickupScope.lockedByListStage('ReceivedBySeller'),
        isFalse,
      );
    });

    testWidgets('a cancelled rider pickup keeps the button disabled', (
      tester,
    ) async {
      setPhoneView(tester);
      final request = _request({'state': 2, 'pickupStage': 'Cancelled'});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vendorReturnPickupProvider.overrideWith(
              (ref, id) async => _pickup({'mode': 'Rider', 'stage': 'Cancelled'}),
            ),
          ],
          child: ordersTestApp(
            SingleChildScrollView(
              child: VendorReturnPickupScope(
                request: request,
                builder: (panel, locked) => VendorReturnCard(
                  request: request,
                  busy: false,
                  onApprove: () {},
                  onReject: () {},
                  onComplete: () {},
                  completeLocked: locked,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Received · complete & refund'),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(find.text(VendorReturnCard.completeLockedText), findsOneWidget);
    });
  });

  group('seller return errors in plain words', () {
    String message(NetworkExceptions failure) =>
        VendorReturnErrorCopy.message(failure);
    NetworkExceptions code(String c) => NetworkExceptions.validation(code: c);

    test('the rider has not handed it over', () {
      expect(
        message(code('return.pickup_not_received')),
        VendorReturnErrorCopy.pickupNotReceived,
      );
    });

    test('delivery_proof.* and delivery_request.*', () {
      expect(message(code('delivery_proof.expired')), contains('expired'));
      expect(message(code('delivery_proof.invalid')), contains('doesn’t match'));
      expect(
        message(code('delivery_proof.too_many_attempts')),
        contains('15 minutes'),
      );
      expect(message(code('delivery_request.closed')), contains('no longer'));
      expect(
        message(code('delivery_request.already_assigned')),
        contains('already assigned'),
      );
      // A code of the family this app has no sentence for yet.
      expect(
        message(code('delivery_proof.brand_new')),
        isNot(VendorReturnErrorCopy.fallback),
      );
      expect(
        message(code('delivery_request.brand_new')),
        isNot(VendorReturnErrorCopy.fallback),
      );
    });

    test('a stale return, offline, and anything else', () {
      expect(
        message(code('state.invalid_transition')),
        VendorReturnErrorCopy.changed,
      );
      expect(
        message(const NetworkExceptions.conflict()),
        VendorReturnErrorCopy.changed,
      );
      expect(
        message(const NetworkExceptions.noInternetConnection()),
        VendorReturnErrorCopy.offline,
      );
      expect(
        message(const NetworkExceptions.serverUnavailable()),
        VendorReturnErrorCopy.unavailable,
      );
      expect(
        message(const NetworkExceptions.unexpectedError()),
        VendorReturnErrorCopy.fallback,
      );
      expect(message(code('return.whatever')), VendorReturnErrorCopy.fallback);
    });
  });
}
