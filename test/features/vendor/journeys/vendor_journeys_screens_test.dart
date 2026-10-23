import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/data/vendor_journeys_api.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/domain/vendor_journey.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/journey_vendor_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/create_journey_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/journey_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/vendor_journey_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/vendor_journeys_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';

const _jId = '7b0c0000-0000-4000-8000-000000000001';
const _me = 'aaaaaaaa-0000-4000-8000-000000000001';
const _hotel = 'aaaaaaaa-0000-4000-8000-000000000002';
const _fly = 'aaaaaaaa-0000-4000-8000-000000000003';

const _notDeployed = ServiceFailure(ServiceFailureKind.notFound);

Map<String, dynamic> _step(
  String id,
  int index, {
  required String vendor,
  required String name,
  int state = 2,
  String? reelId,
  String? note,
}) => {
  'id': id,
  'index': index,
  'state': state,
  'vendorAccountId': vendor,
  'vendorName': name,
  'reelId': reelId ?? (state == 2 ? 'reel-$id' : null),
  'caption': state == 2 ? 'Reel of $name' : null,
  'isVisible': state == 2,
  'hiddenReason': state == 2 ? 0 : 1,
  'inviteNote': note,
};

VendorJourney _journey({
  int myRole = 1,
  String? myStepId = 's1',
  int state = 1,
  List<Map<String, dynamic>>? steps,
  String owner = _me,
  String ownerName = 'Greenline Tours',
}) => readVendorJourney({
  'id': _jId,
  'title': 'Pokhara weekend',
  'city': 'Pokhara',
  'state': state,
  'ownerVendorAccountId': owner,
  'ownerName': ownerName,
  'myRole': myRole,
  'myStepId': myStepId,
  'isLive': true,
  'visibleStepCount': 2,
  'maxSteps': 8,
  'steps':
      steps ??
      [
        _step('s1', 0, vendor: _me, name: 'Greenline Tours'),
        _step('s2', 1, vendor: _hotel, name: 'Hotel Barahi'),
        _step('s3', 2, vendor: _fly, name: 'Sunrise Paragliding'),
      ],
});

class _FakeApi implements VendorJourneysApi {
  Either<ServiceFailure, List<VendorJourney>> listResult = right(const []);
  Either<ServiceFailure, VendorJourney> getResult = right(_journey());
  List<JourneyReelOption> reels = const [
    JourneyReelOption(reelId: 'r1', caption: 'Our deluxe bus'),
    JourneyReelOption(
      reelId: 'r2',
      caption: 'Night bus',
      canUse: false,
      reason: 'journey.reel_limit',
    ),
  ];
  List<JourneyVendor> vendors = const [
    JourneyVendor(
      vendorAccountId: _hotel,
      businessName: 'Hotel Barahi',
      city: 'Pokhara',
      category: 1,
      isVerified: true,
    ),
  ];

  final List<String> calls = [];
  Map<String, Object?> last = {};

  Either<ServiceFailure, VendorJourney> _ok(VendorJourney j) => right(j);

  @override
  Future<Either<ServiceFailure, List<VendorJourney>>> list({
    JourneyRole? role,
    JourneyState? state,
  }) async => listResult;

  @override
  Future<Either<ServiceFailure, VendorJourney>> get(String journeyId) async =>
      getResult;

  @override
  Future<Either<ServiceFailure, VendorJourney>> create({
    required String reelId,
    String? title,
    String? city,
  }) async {
    calls.add('create');
    last = {'reelId': reelId, 'title': title, 'city': city};
    return getResult;
  }

  @override
  Future<Either<ServiceFailure, VendorJourney>> update(
    String journeyId, {
    String? title,
    String? city,
  }) async {
    calls.add('update');
    return getResult;
  }

  @override
  Future<Either<ServiceFailure, VendorJourney>> invite(
    String journeyId, {
    required String vendorAccountId,
    String? note,
  }) async {
    calls.add('invite');
    last = {'vendorAccountId': vendorAccountId, 'note': note};
    return _ok(
      _journey(
        steps: [
          _step('s1', 0, vendor: _me, name: 'Greenline Tours'),
          _step(
            's2',
            1,
            vendor: _hotel,
            name: 'Hotel Barahi',
            state: 1,
            note: note,
          ),
        ],
      ),
    );
  }

  @override
  Future<Either<ServiceFailure, VendorJourney>> accept(
    String journeyId,
    String stepId, {
    required String reelId,
  }) async {
    calls.add('accept');
    last = {'stepId': stepId, 'reelId': reelId};
    return _ok(_journey(myRole: 2, myStepId: stepId, owner: _hotel));
  }

  @override
  Future<Either<ServiceFailure, Unit>> decline(
    String journeyId,
    String stepId,
  ) async {
    calls.add('decline');
    return right(unit);
  }

  @override
  Future<Either<ServiceFailure, VendorJourney>> replaceReel(
    String journeyId,
    String stepId, {
    required String reelId,
  }) async {
    calls.add('replace');
    last = {'stepId': stepId, 'reelId': reelId};
    return getResult;
  }

  @override
  Future<Either<ServiceFailure, Unit>> leave(String journeyId) async {
    calls.add('leave');
    return right(unit);
  }

  @override
  Future<Either<ServiceFailure, VendorJourney>> reorder(
    String journeyId,
    List<String> stepIds,
  ) async {
    calls.add('reorder');
    last = {'stepIds': stepIds};
    final current = getResult.getOrElse((_) => throw StateError('no journey'));
    final byId = {for (final s in current.steps) s.id: s};
    return _ok(current.withSteps([for (final id in stepIds) byId[id]!]));
  }

  @override
  Future<Either<ServiceFailure, VendorJourney>> removeStep(
    String journeyId,
    String stepId,
  ) async {
    calls.add('remove');
    last = {'stepId': stepId};
    return getResult;
  }

  @override
  Future<Either<ServiceFailure, VendorJourney>> end(String journeyId) async {
    calls.add('end');
    return getResult;
  }

  @override
  Future<Either<ServiceFailure, List<JourneyVendor>>> searchVendors(
    String query, {
    int limit = 20,
  }) async {
    calls.add('search');
    return right(vendors);
  }

  @override
  Future<Either<ServiceFailure, List<JourneyReelOption>>> myReels({
    String? journeyId,
    int limit = 30,
  }) async => right(reels);
}

void main() {
  late _FakeApi api;

  setUp(() => api = _FakeApi());

  Future<GoRouter> pump(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('Home')),
        ...vendorJourneyRoutes,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [vendorJourneysApiProvider.overrideWithValue(api)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('list', () {
    testWidgets('a server without journeys says it is being set up', (
      tester,
    ) async {
      api.listResult = left(_notDeployed);
      await pump(tester, JourneyRoutes.list);

      expect(find.byType(ServiceSettingUpView), findsOneWidget);
      expect(find.text('Journeys are being set up'), findsOneWidget);
      expect(find.byKey(VendorJourneysScreen.createKey), findsNothing);
    });

    testWidgets('invites, my journeys and the ones I am in, apart', (
      tester,
    ) async {
      api.listResult = right([
        _journey(),
        _journey(myRole: 3, myStepId: 's2', owner: _fly).withSteps(const []),
        _journey(myRole: 2, myStepId: 's2', owner: _fly),
      ]);
      await pump(tester, JourneyRoutes.list);

      expect(find.text('Invites for you'), findsOneWidget);
      expect(find.text('Your journeys'), findsOneWidget);
      expect(find.text("Journeys you're in"), findsOneWidget);
      expect(find.text('Invited'), findsOneWidget);
      expect(find.byKey(VendorJourneysScreen.createKey), findsOneWidget);
    });
  });

  group('create', () {
    testWidgets('a title, one of my reels, and the new journey opens', (
      tester,
    ) async {
      await pump(tester, JourneyRoutes.create);

      final submit = find.byKey(CreateJourneyScreen.submitKey);
      expect(
        tester.widget<ServiceActionButton>(submit).onPressed,
        isNull,
        reason: 'no reel picked yet',
      );

      await tester.enterText(
        find.byKey(JourneyTitleFields.titleKey),
        'Pokhara weekend',
      );
      // A reel already in 3 journeys cannot be picked.
      await tester.tap(find.byKey(JourneySheetKeys.reelOption('r2')));
      await tester.pump();
      expect(tester.widget<ServiceActionButton>(submit).onPressed, isNull);
      expect(
        find.text('That reel is already in 3 journeys. Pick another reel.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(JourneySheetKeys.reelOption('r1')));
      await tester.pump();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(api.calls, ['create']);
      expect(api.last, {
        'reelId': 'r1',
        'title': 'Pokhara weekend',
        'city': '',
      });
      expect(find.byType(VendorJourneyDetailScreen), findsOneWidget);
    });
  });

  group('detail', () {
    testWidgets('the owner invites a business by name, with a note', (
      tester,
    ) async {
      api.getResult = right(
        _journey(steps: [_step('s1', 0, vendor: _me, name: 'Greenline Tours')]),
      );
      await pump(tester, JourneyRoutes.detailPath(_jId));

      await tester.tap(find.byKey(VendorJourneyDetailScreen.inviteKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(JourneySheetKeys.vendorSearch), 'Hot');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(JourneySheetKeys.vendorResult(_hotel)));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(JourneySheetKeys.inviteNote),
        'Join our Pokhara weekend?',
      );
      await tester.tap(find.byKey(JourneySheetKeys.inviteSend));
      await tester.pumpAndSettle();

      expect(api.calls, ['search', 'invite']);
      expect(api.last, {
        'vendorAccountId': _hotel,
        'note': 'Join our Pokhara weekend?',
      });
      expect(find.byKey(VendorJourneyDetailScreen.stepKey('s2')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(VendorJourneyDetailScreen.stepKey('s2')),
          matching: find.text('Invited'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an invitee accepts by picking one of their reels', (
      tester,
    ) async {
      api.getResult = right(
        _journey(
          myRole: 3,
          myStepId: 's2',
          owner: _fly,
          ownerName: 'Sunrise Paragliding',
          steps: [
            _step('s1', 0, vendor: _fly, name: 'Sunrise Paragliding'),
            _step(
              's2',
              1,
              vendor: _me,
              name: 'Greenline Tours',
              state: 1,
              note: 'Bus to Pokhara?',
            ),
          ],
        ),
      );
      await pump(tester, JourneyRoutes.detailPath(_jId));

      expect(
        find.text('Sunrise Paragliding invited you to add a step'),
        findsOneWidget,
      );
      expect(find.text('"Bus to Pokhara?"'), findsOneWidget);
      expect(find.byKey(VendorJourneyDetailScreen.leaveKey), findsNothing);

      await tester.ensureVisible(find.byKey(VendorJourneyDetailScreen.acceptKey));
      await tester.tap(find.byKey(VendorJourneyDetailScreen.acceptKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(JourneySheetKeys.reelOption('r1')));
      await tester.pump();
      await tester.tap(find.byKey(JourneySheetKeys.reelConfirm));
      await tester.pumpAndSettle();

      expect(api.calls, ['accept']);
      expect(api.last, {'stepId': 's2', 'reelId': 'r1'});
      expect(find.byKey(VendorJourneyDetailScreen.leaveKey), findsOneWidget);
    });

    testWidgets('the owner drags a step into a new order', (tester) async {
      await pump(tester, JourneyRoutes.detailPath(_jId));

      final handle = find.byKey(VendorJourneyDetailScreen.dragKey('s3'));
      final tile = tester.getSize(find.byKey(VendorJourneyDetailScreen.stepKey('s3')));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(0, -tile.height * 1.1 / 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(api.calls, ['reorder']);
      expect(api.last, {
        'stepIds': ['s1', 's3', 's2'],
      });
      final s3 = tester.getTopLeft(find.byKey(VendorJourneyDetailScreen.stepKey('s3')));
      final s2 = tester.getTopLeft(find.byKey(VendorJourneyDetailScreen.stepKey('s2')));
      expect(s3.dy, lessThan(s2.dy));
    });

    testWidgets("the owner can't remove their own step, only others'", (
      tester,
    ) async {
      await pump(tester, JourneyRoutes.detailPath(_jId));

      expect(find.byKey(VendorJourneyDetailScreen.removeKey('s1')), findsNothing);
      await tester.tap(find.byKey(VendorJourneyDetailScreen.removeKey('s2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ServiceConfirmDialogKeys.confirm));
      await tester.pumpAndSettle();
      expect(api.calls, ['remove']);
      expect(api.last, {'stepId': 's2'});
    });

    testWidgets('a member leaves and is taken back to the list', (
      tester,
    ) async {
      api.getResult = right(_journey(myRole: 2, myStepId: 's2', owner: _fly));
      final router = await pump(tester, JourneyRoutes.list);
      unawaited(router.push(JourneyRoutes.detailPath(_jId)));
      await tester.pumpAndSettle();

      expect(find.byKey(VendorJourneyDetailScreen.inviteKey), findsNothing);
      expect(find.byKey(VendorJourneyDetailScreen.endKey), findsNothing);
      expect(find.byKey(VendorJourneyDetailScreen.dragKey('s1')), findsNothing);

      await tester.ensureVisible(find.byKey(VendorJourneyDetailScreen.leaveKey));
      await tester.tap(find.byKey(VendorJourneyDetailScreen.leaveKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ServiceConfirmDialogKeys.confirm));
      await tester.pumpAndSettle();

      expect(api.calls, ['leave']);
      expect(find.byType(VendorJourneyDetailScreen), findsNothing);
      expect(find.byType(VendorJourneysScreen), findsOneWidget);
    });

    testWidgets('a member replaces their reel', (tester) async {
      api.getResult = right(_journey(myRole: 2, myStepId: 's2', owner: _fly));
      await pump(tester, JourneyRoutes.detailPath(_jId));

      await tester.ensureVisible(
        find.byKey(VendorJourneyDetailScreen.replaceKey),
      );
      await tester.tap(find.byKey(VendorJourneyDetailScreen.replaceKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(JourneySheetKeys.reelOption('r1')));
      await tester.pump();
      await tester.tap(find.byKey(JourneySheetKeys.reelConfirm));
      await tester.pumpAndSettle();

      expect(api.calls, ['replace']);
      expect(api.last, {'stepId': 's2', 'reelId': 'r1'});
    });

    testWidgets('a server without journeys says it is being set up', (
      tester,
    ) async {
      api.getResult = left(_notDeployed);
      await pump(tester, JourneyRoutes.detailPath(_jId));
      expect(find.text('Journeys are being set up'), findsOneWidget);
    });

    testWidgets('a journey I am no longer in says so', (tester) async {
      api.getResult = left(
        const ServiceFailure(
          ServiceFailureKind.notFound,
          code: 'journey.not_found',
        ),
      );
      await pump(tester, JourneyRoutes.detailPath(_jId));
      expect(
        find.text('This journey is not available any more.'),
        findsOneWidget,
      );
    });

    testWidgets('an ended journey is read only', (tester) async {
      api.getResult = right(_journey(state: 2));
      await pump(tester, JourneyRoutes.detailPath(_jId));

      expect(find.text('Ended'), findsOneWidget);
      expect(find.byKey(VendorJourneyDetailScreen.inviteKey), findsNothing);
      expect(find.byKey(VendorJourneyDetailScreen.endKey), findsNothing);
      expect(find.byKey(VendorJourneyDetailScreen.removeKey('s2')), findsNothing);
      expect(find.byKey(VendorJourneyDetailScreen.dragKey('s2')), findsNothing);
    });
  });

  group('notifications', () {
    test('journey notices open the journey', () {
      for (final type in [
        'journey',
        'journey.invite.received',
        'journey.member.left',
        'journey.ended',
      ]) {
        expect(
          notificationLocation(
            NotificationPayload(
              type: type,
              data: const {'journeyId': _jId, 'stepId': 's2'},
            ),
          ),
          '/vendor/journeys/$_jId',
          reason: type,
        );
      }
    });

    test('without an id: the server link, else the list', () {
      expect(
        journeyNotificationLocation(
          'journey',
          const {},
          link: '/vendor/journeys/$_jId',
        ),
        '/vendor/journeys/$_jId',
      );
      expect(journeyNotificationLocation('journey', const {}), JourneyRoutes.list);
      expect(journeyNotificationLocation('booking.vendor.confirmed', const {}), isNull);
    });
  });
}
