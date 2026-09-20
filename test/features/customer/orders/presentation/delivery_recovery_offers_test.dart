import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/delivery_recovery_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_recovery_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_recovery_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_recovery_offers_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const String _tracking = 'SM-D-00000001';

/// One acceptance as the fake saw it — offer, acknowledgement and the
/// Idempotency-Key the client chose.
class _AcceptCall {
  const _AcceptCall({
    required this.offerId,
    required this.acknowledged,
    required this.idempotencyKey,
  });

  final String offerId;
  final bool acknowledged;
  final String idempotencyKey;
}

class _FakeRecoveryDataSource implements DeliveryRecoveryDataSource {
  _FakeRecoveryDataSource({
    this.offersOnRefresh = const <Map<String, dynamic>>[],
    this.acceptErrors = const <Exception>[],
    this.acceptResponse,
  });

  /// What a re-read of `/recovery-offers` returns.
  List<Map<String, dynamic>> offersOnRefresh;

  /// Thrown, in order, by successive acceptance attempts. When it runs out
  /// the acceptance succeeds.
  List<Exception> acceptErrors;

  Map<String, dynamic>? acceptResponse;

  final List<_AcceptCall> acceptCalls = <_AcceptCall>[];
  int listCalls = 0;

  @override
  Future<List<DeliveryRecoveryOffer>> listOffers(String trackingNumber) async {
    listCalls += 1;
    return offersOnRefresh.map(DeliveryRecoveryOffer.fromJson).toList();
  }

  @override
  Future<DeliveryRecoveryOffer> acceptOffer({
    required String trackingNumber,
    required String offerId,
    required bool acknowledgeRefundWindow,
    required String idempotencyKey,
  }) async {
    acceptCalls.add(
      _AcceptCall(
        offerId: offerId,
        acknowledged: acknowledgeRefundWindow,
        idempotencyKey: idempotencyKey,
      ),
    );
    if (acceptErrors.isNotEmpty) {
      throw acceptErrors.removeAt(0);
    }
    return DeliveryRecoveryOffer.fromJson(
      acceptResponse ??
          _offerJson(
            offerId: offerId,
            status: 'Accepted',
            outcomeReference: 'RF-2026-0001',
          ),
    );
  }
}

DioException _conflict(String errorCode) => DioException(
  requestOptions: RequestOptions(path: '/accept'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/accept'),
    statusCode: 409,
    data: <String, dynamic>{'errorCode': errorCode},
  ),
);

DioException get _serverBlip => DioException(
  requestOptions: RequestOptions(path: '/accept'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/accept'),
    statusCode: 503,
    data: <String, dynamic>{'errorCode': 'server.unavailable'},
  ),
);

Map<String, dynamic> _offerJson({
  String offerId = 'offer-cancel',
  String remedy = 'CancelForRefund',
  bool requiresAck = true,
  Duration expiresIn = const Duration(minutes: 20),
  String description = 'We can stop this delivery now and refund you in full.',
  String status = 'Offered',
  String? outcomeReference,
}) => <String, dynamic>{
  'offerId': offerId,
  'trackingNumber': _tracking,
  'remedy': remedy,
  'status': status,
  'riskReasonCode': 'delivery.risk.deadline_passed',
  'description': description,
  'requiresRefundWindowAcknowledgement': requiresAck,
  'offeredUtc': DateTime.now().toUtc().toIso8601String(),
  'expiresUtc': DateTime.now().toUtc().add(expiresIn).toIso8601String(),
  'acceptedUtc': null,
  'outcomeReference': outcomeReference,
};

Map<String, dynamic> _riskJson({
  bool atRisk = true,
  List<Map<String, dynamic>> remedies = const <Map<String, dynamic>>[],
}) => <String, dynamic>{
  'atRisk': atRisk,
  'riskReasonCode': atRisk ? 'delivery.risk.deadline_passed' : null,
  'customerMessage': atRisk
      ? 'This parcel is running later than promised.'
      : 'On track for Sunday.',
  'recommendedAction': atRisk ? 'Choose what you would like us to do.' : null,
  'remedies': remedies,
};

/// The recovery surface on its own, so the offer behaviour can be driven
/// without the whole order-detail screen.
Widget _host({
  required _FakeRecoveryDataSource dataSource,
  required Map<String, dynamic> risk,
  double textScale = 1,
  double width = 400,
}) => ProviderScope(
  overrides: [
    deliveryRecoveryDataSourceProvider.overrideWithValue(dataSource),
    deliveryRiskProvider.overrideWith(
      (ref, trackingNumber) async => DeliveryRiskAssessment.fromJson(risk),
    ),
  ],
  child: MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 800),
        textScaler: TextScaler.linear(textScale),
      ),
      child: const Scaffold(
        body: SingleChildScrollView(
          child: DeliveryRecoveryOffersView(trackingNumber: _tracking),
        ),
      ),
    ),
  ),
);

OrderDetail _order() => OrderDetail(
  id: 'order-id',
  orderNumber: 'NK2026-00015',
  status: OrderTrackStatus.inTransit,
  placedAt: DateTime.utc(2026, 9, 11),
  estimatedDelivery: DateTime.utc(2026, 9, 14),
  items: const [],
  subtotal: const Money(amount: 1000, currency: 'NPR'),
  shipping: const Money(amount: 100, currency: 'NPR'),
  tax: const Money(amount: 0, currency: 'NPR'),
  total: const Money(amount: 1100, currency: 'NPR'),
  shippingAddress: 'Kathmandu, Nepal',
  paymentMethod: 'eSewa',
  trackingNumber: _tracking,
  canCancel: true,
  canReturn: false,
);

/// The real order-detail screen, so the remedies are proved to land on the
/// surface the customer already reads — not on a new destination.
Widget _orderDetailScreen({
  required _FakeRecoveryDataSource dataSource,
  required Map<String, dynamic> risk,
}) {
  final repository = _MockOrdersRepository();
  when(
    () => repository.getOrderDetail('NK2026-00015'),
  ).thenAnswer((_) async => right(_order()));
  when(() => repository.getOrderTimeline('NK2026-00015')).thenAnswer(
    (_) async => left(const NetworkExceptions.serverUnavailable()),
  );
  return ProviderScope(
    overrides: [
      ordersRepositoryProvider.overrideWithValue(repository),
      deliveryRecoveryDataSourceProvider.overrideWithValue(dataSource),
      deliveryStoryProvider.overrideWith(
        (ref, trackingNumber) async => const <DeliveryStoryChapter>[],
      ),
      deliveryRiskProvider.overrideWith(
        (ref, trackingNumber) async => DeliveryRiskAssessment.fromJson(risk),
      ),
    ],
    child: const MaterialApp(
      home: OrderDetailScreen(orderId: 'NK2026-00015'),
    ),
  );
}

void main() {
  group('the risk surface', () {
    testWidgets('renders the remedies with the risk narration', (
      tester,
    ) async {
      final api = _FakeRecoveryDataSource();
      await tester.pumpWidget(
        _orderDetailScreen(
          dataSource: api,
          risk: _riskJson(
            remedies: [
              _offerJson(),
              _offerJson(
                offerId: 'offer-support',
                remedy: 'PrioritySupportReview',
                requiresAck: false,
                description: 'We can put a person on this delivery today.',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The worry and the remedies are one block, not two destinations.
      expect(
        find.text('This parcel is running later than promised.'),
        findsOneWidget,
      );
      expect(find.text('What we can do about it'), findsOneWidget);
      expect(find.text('Cancel this delivery and refund me'), findsOneWidget);
      expect(find.text('Put a person on this'), findsOneWidget);
      expect(
        find.text('We can stop this delivery now and refund you in full.'),
        findsOneWidget,
      );
      // The remedies came with the risk read; no second call was needed.
      expect(api.listCalls, 0);
    });

    testWidgets('a delivery that is not at risk shows nothing', (tester) async {
      final api = _FakeRecoveryDataSource();
      await tester.pumpWidget(
        _orderDetailScreen(dataSource: api, risk: _riskJson(atRisk: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delivery-recovery-offers')), findsNothing);
      expect(find.text('What we can do about it'), findsNothing);
      expect(find.textContaining('all good', findRichText: true), findsNothing);
      expect(api.listCalls, 0);
    });
  });

  group('cancelling for a refund', () {
    testWidgets('the acknowledgement is never pre-set and gates the call', (
      tester,
    ) async {
      final api = _FakeRecoveryDataSource();
      await tester.pumpWidget(
        _host(
          dataSource: api,
          risk: _riskJson(remedies: [_offerJson()]),
        ),
      );
      await tester.pumpAndSettle();

      // One tap only opens the confirmation — it never cancels.
      await tester.tap(find.byKey(const ValueKey('recovery-cta-offer-cancel')));
      await tester.pumpAndSettle();
      expect(api.acceptCalls, isEmpty);

      expect(
        find.text('Cancel this delivery and refund you?'),
        findsOneWidget,
      );
      expect(
        find.textContaining('5 to 7 working days'),
        findsWidgets,
      );
      expect(find.textContaining('cannot be undone'), findsOneWidget);

      // The box starts unticked and the confirm control is inert.
      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('recovery-ack-checkbox')),
      );
      expect(checkbox.value, isFalse);
      final confirmBefore = tester.widget<FilledButton>(
        find.byKey(const Key('recovery-confirm-cta')),
      );
      expect(confirmBefore.onPressed, isNull);

      await tester.tap(find.byKey(const Key('recovery-confirm-cta')));
      await tester.pumpAndSettle();
      expect(api.acceptCalls, isEmpty);

      // The customer acknowledges, themselves.
      await tester.tap(find.byKey(const Key('recovery-ack-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recovery-confirm-cta')));
      await tester.pumpAndSettle();

      expect(api.acceptCalls, hasLength(1));
      expect(api.acceptCalls.single.acknowledged, isTrue);
      expect(
        find.text('Cancelled, and your refund is on its way'),
        findsOneWidget,
      );
      expect(find.text('Reference RF-2026-0001'), findsOneWidget);
    });

    testWidgets('backing out of the confirmation changes nothing', (
      tester,
    ) async {
      final api = _FakeRecoveryDataSource();
      await tester.pumpWidget(
        _host(
          dataSource: api,
          risk: _riskJson(remedies: [_offerJson()]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('recovery-cta-offer-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recovery-dismiss-cta')));
      await tester.pumpAndSettle();

      expect(api.acceptCalls, isEmpty);
      expect(find.text('Cancel this delivery and refund me'), findsOneWidget);
    });
  });

  group('the two 409s', () {
    testWidgets('expired asks the customer again', (tester) async {
      final api = _FakeRecoveryDataSource(
        acceptErrors: [_conflict(DeliveryRecoveryErrorCodes.offerExpired)],
        offersOnRefresh: [
          _offerJson(
            offerId: 'offer-support',
            remedy: 'PrioritySupportReview',
            requiresAck: false,
            description: 'We can put a person on this delivery today.',
          ),
        ],
      );
      await tester.pumpWidget(
        _host(
          dataSource: api,
          risk: _riskJson(remedies: [_offerJson()]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('recovery-cta-offer-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recovery-ack-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recovery-confirm-cta')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('recovery-notice-expired')),
        findsOneWidget,
      );
      expect(
        find.text('That option ran out before we could confirm it'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recovery-notice-stale')), findsNothing);
      // Not stranded: the current options were fetched and are tappable.
      expect(api.listCalls, 1);
      expect(find.text('Put a person on this'), findsOneWidget);
    });

    testWidgets('stale says the delivery moved', (tester) async {
      final api = _FakeRecoveryDataSource(
        acceptErrors: [_conflict(DeliveryRecoveryErrorCodes.offerStale)],
        offersOnRefresh: [
          _offerJson(
            offerId: 'offer-support',
            remedy: 'PrioritySupportReview',
            requiresAck: false,
            description: 'We can put a person on this delivery today.',
          ),
        ],
      );
      await tester.pumpWidget(
        _host(
          dataSource: api,
          risk: _riskJson(remedies: [_offerJson()]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('recovery-cta-offer-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recovery-ack-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recovery-confirm-cta')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recovery-notice-stale')), findsOneWidget);
      expect(
        find.text('Your delivery moved while you were deciding'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recovery-notice-expired')), findsNothing);
      expect(api.listCalls, 1);
      expect(find.text('Put a person on this'), findsOneWidget);
    });
  });

  testWidgets('a retried acceptance reuses its idempotency key', (
    tester,
  ) async {
    final api = _FakeRecoveryDataSource(
      acceptErrors: [_serverBlip],
      acceptResponse: _offerJson(
        offerId: 'offer-support',
        remedy: 'PrioritySupportReview',
        requiresAck: false,
        status: 'Accepted',
        outcomeReference: 'TK-2026-0007',
      ),
    );
    await tester.pumpWidget(
      _host(
        dataSource: api,
        risk: _riskJson(
          remedies: [
            _offerJson(
              offerId: 'offer-support',
              remedy: 'PrioritySupportReview',
              requiresAck: false,
              description: 'We can put a person on this delivery today.',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recovery-cta-offer-support')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recovery-notice-failed')), findsOneWidget);
    expect(api.acceptCalls, hasLength(1));

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(api.acceptCalls, hasLength(2));
    expect(
      api.acceptCalls.first.idempotencyKey,
      api.acceptCalls.last.idempotencyKey,
    );
    expect(api.acceptCalls.first.idempotencyKey, isNotEmpty);
    expect(find.text('Support has this delivery'), findsOneWidget);
  });

  testWidgets('an unknown remedy kind degrades gracefully', (tester) async {
    final api = _FakeRecoveryDataSource();
    await tester.pumpWidget(
      _host(
        dataSource: api,
        risk: _riskJson(
          remedies: [
            _offerJson(
              offerId: 'offer-future',
              remedy: 'RerouteToPickupPoint',
              requiresAck: false,
              description: 'We can send this to a pickup point near you.',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Another option for this delivery'), findsOneWidget);
    // The backend's own sentence carries it — never a blank card.
    expect(
      find.text('We can send this to a pickup point near you.'),
      findsOneWidget,
    );

    // An unrecognised remedy is still confirmed, because this build cannot
    // know whether it moves money.
    await tester.tap(find.byKey(const ValueKey('recovery-cta-offer-future')));
    await tester.pumpAndSettle();
    expect(find.text('Go ahead with this option?'), findsOneWidget);
    expect(find.byKey(const Key('recovery-ack-checkbox')), findsNothing);
    await tester.tap(find.byKey(const Key('recovery-confirm-cta')));
    await tester.pumpAndSettle();
    expect(api.acceptCalls, hasLength(1));
    expect(api.acceptCalls.single.acknowledged, isFalse);
  });

  testWidgets('an offer that lapses on screen stops being tappable', (
    tester,
  ) async {
    final api = _FakeRecoveryDataSource(
      offersOnRefresh: [
        _offerJson(
          offerId: 'offer-support',
          remedy: 'PrioritySupportReview',
          requiresAck: false,
          description: 'We can put a person on this delivery today.',
        ),
      ],
    );
    await tester.pumpWidget(
      _host(
        dataSource: api,
        risk: _riskJson(
          remedies: [_offerJson(expiresIn: const Duration(seconds: 2))],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cancel this delivery and refund me'), findsOneWidget);

    // The 30-minute window closes while the customer is still looking.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('recovery-cta-offer-cancel')),
      findsNothing,
    );
    expect(find.byKey(const Key('recovery-notice-lapsed')), findsOneWidget);
    expect(find.text('That option just timed out'), findsOneWidget);
    // Refreshed rather than stranded.
    expect(api.listCalls, greaterThanOrEqualTo(1));
    expect(find.text('Put a person on this'), findsOneWidget);
    expect(api.acceptCalls, isEmpty);
  });

  testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
    final api = _FakeRecoveryDataSource();
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        dataSource: api,
        width: 320,
        textScale: 1.3,
        risk: _riskJson(
          remedies: [
            _offerJson(),
            _offerJson(
              offerId: 'offer-support',
              remedy: 'PrioritySupportReview',
              requiresAck: false,
              description: 'We can put a person on this delivery today.',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // And the confirmation sheet, which carries the longest copy.
    await tester.tap(find.byKey(const ValueKey('recovery-cta-offer-cancel')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('every control carries a semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    final api = _FakeRecoveryDataSource();
    await tester.pumpWidget(
      _host(
        dataSource: api,
        risk: _riskJson(remedies: [_offerJson()]),
      ),
    );
    await tester.pumpAndSettle();

    final cta = tester.getSemantics(
      find.byKey(const ValueKey('recovery-cta-offer-cancel')),
    );
    expect(cta.label, isNotEmpty);
    expect(cta.label, contains('Cancel this delivery'));

    await tester.tap(find.byKey(const ValueKey('recovery-cta-offer-cancel')));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(const Key('recovery-ack-checkbox'))).label,
      contains('5 to 7 working days'),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('recovery-confirm-cta'))).label,
      isNotEmpty,
    );
    expect(
      tester.getSemantics(find.byKey(const Key('recovery-dismiss-cta'))).label,
      isNotEmpty,
    );
    handle.dispose();
  });

  group('the wire contract', () {
    test('parses a remedy this build does not know about', () {
      final offer = DeliveryRecoveryOffer.fromJson(
        _offerJson(remedy: 'SplitTheShipment'),
      );
      expect(offer.remedy, DeliveryRemedyKind.unknown);
      expect(offer.rawRemedy, 'SplitTheShipment');
      expect(offer.status, DeliveryRecoveryOfferStatus.offered);
    });

    test('accepts numeric enum values too', () {
      final offer = DeliveryRecoveryOffer.fromJson(
        <String, dynamic>{..._offerJson(), 'remedy': 2, 'status': 3},
      );
      expect(offer.remedy, DeliveryRemedyKind.prioritySupportReview);
      expect(offer.status, DeliveryRecoveryOfferStatus.expired);
      expect(offer.isActionableAt(DateTime.now().toUtc()), isFalse);
    });

    test('a missing expiry falls back to the 30-minute lifetime', () {
      final json = <String, dynamic>{..._offerJson()}..remove('expiresUtc');
      final offer = DeliveryRecoveryOffer.fromJson(json);
      expect(offer.isActionableAt(DateTime.now().toUtc()), isTrue);
      expect(
        offer.expiresUtc.difference(offer.offeredUtc),
        const Duration(minutes: 30),
      );
    });

    test('an on-track assessment carries no remedies', () {
      final risk = DeliveryRiskAssessment.fromJson(_riskJson(atRisk: false));
      expect(risk.atRisk, isFalse);
      expect(risk.remedies, isEmpty);
    });

    test('the countdown reads in plain words', () {
      expect(
        remainingWindowLabel(const Duration(minutes: 12)),
        'open for another 12 minutes',
      );
      expect(
        remainingWindowLabel(const Duration(minutes: 1, seconds: 5)),
        'open for another minute',
      );
      expect(
        remainingWindowLabel(const Duration(seconds: 20)),
        'open for under a minute',
      );
      expect(remainingWindowLabel(Duration.zero), 'closed');
    });
  });
}
