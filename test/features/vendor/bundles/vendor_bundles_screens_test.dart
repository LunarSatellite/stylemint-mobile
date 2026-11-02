import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/bundle_vendor_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/data/vendor_bundles_api.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/domain/vendor_bundle.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/presentation/vendor_bundle_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/shared/vendor_bundle_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/shared/vendor_bundle_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';

const _id = '7b0c0000-0000-4000-8000-0000000000b1';

Map<String, dynamic> _wire({
  String myShopState = 'Pending',
  String state = 'PendingAcceptance',
  int termsVersion = 3,
}) => {
  'id': _id,
  'title': 'Trekking kit',
  'ownerKind': 'Creator',
  'ownerAccountId': 'c-1',
  'ownerName': 'Asha',
  'discountPercent': 10,
  'state': state,
  'termsVersion': termsVersion,
  'pausedReason': null,
  'myRole': 'Shop',
  'myShopState': myShopState,
  'myVendorAccountId': 'v-peak',
  'shops': [
    {
      'vendorAccountId': 'v-peak',
      'name': 'Peak Gear',
      'state': myShopState,
      'acceptedTermsVersion': null,
    },
    {
      'vendorAccountId': 'v-sock',
      'name': 'Sock Co',
      'state': 'Accepted',
      'acceptedTermsVersion': termsVersion,
    },
  ],
  'items': [
    {
      'id': 'bi-1',
      'productId': 'p-jacket',
      'vendorAccountId': 'v-peak',
      'title': 'Down jacket',
      'quantity': 1,
      'listUnitPrice': 12000,
      'bundleUnitPrice': 10800,
      'commissionRatePercent': 8,
      'shopFunds': 1200,
      'available': true,
    },
    {
      'id': 'bi-2',
      'productId': 'p-socks',
      'vendorAccountId': 'v-sock',
      'title': 'Wool socks',
      'quantity': 2,
      'listUnitPrice': 500,
      'bundleUnitPrice': 450,
      'available': true,
    },
  ],
  'totals': {
    'listTotal': 13000,
    'bundleTotal': 11700,
    'saving': 1300,
    'currency': 'NPR',
  },
};

class _FakeApi implements VendorBundlesApi {
  Either<BundleFailure, List<VendorBundle>> listResult = right([
    readVendorBundle(_wire()),
  ]);
  Either<BundleFailure, VendorBundle> getResult = right(readVendorBundle(_wire()));
  Either<BundleFailure, VendorBundle>? acceptResult;
  final accepts = <int>[];
  final declines = <String?>[];
  final withdrawals = <String?>[];

  @override
  Future<Either<BundleFailure, List<VendorBundle>>> list() async => listResult;

  @override
  Future<Either<BundleFailure, VendorBundle>> get(String bundleId) async =>
      getResult;

  @override
  Future<Either<BundleFailure, VendorBundle>> accept(
    String bundleId, {
    required int termsVersion,
  }) async {
    accepts.add(termsVersion);
    return acceptResult ??
        right(readVendorBundle(_wire(myShopState: 'Accepted', state: 'Live')));
  }

  @override
  Future<Either<BundleFailure, VendorBundle>> decline(
    String bundleId, {
    String? reason,
  }) async {
    declines.add(reason);
    return right(readVendorBundle(_wire(myShopState: 'Declined')));
  }

  @override
  Future<Either<BundleFailure, VendorBundle>> withdraw(
    String bundleId, {
    String? reason,
  }) async {
    withdrawals.add(reason);
    return right(readVendorBundle(_wire(myShopState: 'Withdrawn', state: 'Paused')));
  }
}

Future<void> _pump(WidgetTester tester, _FakeApi api, String location) async {
  tester.view
    ..physicalSize = const Size(1080, 2600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(initialLocation: location, routes: vendorBundleRoutes);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [vendorBundlesApiProvider.overrideWithValue(api)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('BundleManageDto: my items and what I fund', () {
    final b = readVendorBundle(_wire());
    expect(b.state, VendorBundleState.pendingAcceptance);
    expect(b.myShopState, VendorBundleShopState.pending);
    expect(b.canAnswer, isTrue);
    expect(b.isWaitingForMe, isTrue);
    expect(b.myItems.map((i) => i.id), ['bi-1']);
    expect(b.myFunds.amount, 1200);
    expect(b.myBundleRevenue.amount, 10800);
    expect(b.saving.amount, 1300);
    expect(b.shops.last.state, VendorBundleShopState.accepted);
  });

  test('enums read as numbers too', () {
    expect(VendorBundleState.fromWire(3), VendorBundleState.live);
    expect(VendorBundleShopState.fromWire(5), VendorBundleShopState.withdrawn);
    expect(
      VendorBundlePausedReason.fromWire(2),
      VendorBundlePausedReason.shopWithdrew,
    );
    expect(VendorBundlePausedReason.fromWire(null), isNull);
  });

  testWidgets('the list puts invites waiting for me first', (tester) async {
    final api = _FakeApi()
      ..listResult = right([
        readVendorBundle(
          {..._wire(myShopState: 'Accepted', state: 'Live'), 'id': 'live-1', 'title': 'Live kit'},
        ),
        readVendorBundle(_wire()),
      ]);
    await _pump(tester, api, VendorBundleRoutes.list);

    expect(find.text('Waiting for you'), findsOneWidget);
    expect(find.text('Live'), findsWidgets);
    expect(find.text('Answer needed'), findsOneWidget);
    final waiting = tester.getTopLeft(find.text('Trekking kit')).dy;
    final live = tester.getTopLeft(find.text('Live kit')).dy;
    expect(waiting, lessThan(live));
  });

  testWidgets('a bare 404 says bundles are being set up', (tester) async {
    final api = _FakeApi()
      ..listResult = left(const BundleFailure(BundleFailureKind.notFound));
    await _pump(tester, api, VendorBundleRoutes.list);

    expect(find.byKey(ServiceSettingUpView.viewKey), findsOneWidget);
  });

  testWidgets('accept shows the discount the shop gives up and sends the '
      'terms version', (tester) async {
    final api = _FakeApi();
    await _pump(tester, api, VendorBundleRoutes.detailPath(_id));

    expect(find.byKey(VendorBundleDetailScreen.fundsKey), findsOneWidget);
    expect(find.textContaining('You fund Rs 1,200 of the discount'), findsOneWidget);
    expect(find.textContaining('creator 8%'), findsOneWidget);

    await tester.tap(find.byKey(VendorBundleDetailScreen.acceptKey));
    await tester.pumpAndSettle();
    expect(find.text('Accept this bundle?'), findsOneWidget);
    await tester.tap(find.byKey(ServiceConfirmDialogKeys.confirm));
    await tester.pumpAndSettle();

    expect(api.accepts, [3]);
    expect(find.text('You accepted the bundle.'), findsOneWidget);
  });

  testWidgets('stale terms: the bundle reloads and says why', (tester) async {
    final api = _FakeApi()
      ..acceptResult = left(
        const BundleFailure(
          BundleFailureKind.conflict,
          code: 'bundle_terms_changed',
        ),
      );
    await _pump(tester, api, VendorBundleRoutes.detailPath(_id));

    await tester.tap(find.byKey(VendorBundleDetailScreen.acceptKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ServiceConfirmDialogKeys.confirm));
    await tester.pumpAndSettle();

    expect(find.textContaining('The bundle changed while you were looking'), findsOneWidget);
  });

  testWidgets('decline sends the optional reason', (tester) async {
    final api = _FakeApi();
    await _pump(tester, api, VendorBundleRoutes.detailPath(_id));

    await tester.tap(find.byKey(VendorBundleDetailScreen.declineKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ServiceReasonDialogKeys.field), 'No stock');
    await tester.pump();
    await tester.tap(find.byKey(ServiceReasonDialogKeys.confirm));
    await tester.pumpAndSettle();

    expect(api.declines, ['No stock']);
  });

  testWidgets('an accepted shop can withdraw; nothing to accept', (
    tester,
  ) async {
    final api = _FakeApi()
      ..getResult = right(
        readVendorBundle(_wire(myShopState: 'Accepted', state: 'Live')),
      );
    await _pump(tester, api, VendorBundleRoutes.detailPath(_id));

    expect(find.byKey(VendorBundleDetailScreen.acceptKey), findsNothing);
    await tester.tap(find.byKey(VendorBundleDetailScreen.withdrawKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ServiceReasonDialogKeys.confirm));
    await tester.pumpAndSettle();

    expect(api.withdrawals, hasLength(1));
  });

  group('notices', () {
    test('a seller bundle link opens the bundle', () {
      expect(
        bundleNotificationLocation(
          'catalog.bundle.invite_received',
          const {},
          link: '/vendor/bundles/$_id',
        ),
        '/vendor/bundles/$_id',
      );
    });

    test('by id for a seller; a creator owner falls through', () {
      expect(
        bundleNotificationLocation(
          'bundle.terms_pending',
          const {'bundleId': _id},
          actsAsVendor: true,
        ),
        VendorBundleRoutes.detailPath(_id),
      );
      expect(
        bundleNotificationLocation('bundle.live', const {'bundleId': _id}),
        isNull,
      );
      expect(bundleNotificationLocation('order.placed', const {}), isNull);
    });

    test('the app routes a pushed bundle link', () {
      expect(
        notificationLocation(
          const NotificationPayload(
            type: 'catalog.bundle.invite_received',
            data: {'deepLink': 'stylemint://vendor/bundles/$_id'},
          ),
        ),
        '/vendor/bundles/$_id',
      );
    });
  });
}
