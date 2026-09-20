import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/models/notification_prefs_dto.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/notification_prefs_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';

/// Every switch kept on the notification screen is proven here to reach a
/// repository call and to come back from one. The point is not that the
/// widget's own `bool` changed — that was always true, and was exactly what
/// made the dead switches look alive.
class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// The server's answer for a customer who has already refused marketing and
/// turned push off — deliberately the opposite of the entity defaults, so a
/// screen that fell back to its defaults would fail the first-load test.
const _serverPrefs = NotificationPreferences(
  pushEnabled: false,
  emailNotifications: true,
  smsNotifications: true,
  orderStatusChanges: false,
  deliveryUpdates: false,
  newReelsFromCreators: true,
  newFollowers: true,
  paymentUpdates: false,
  marketingPush: false,
  newsletter: true,
  quietHoursEnabled: false,
  quietHoursStart: '23:00',
  quietHoursEnd: '07:30',
);

_MockSettingsRepository _repo({
  NotificationPreferences loaded = _serverPrefs,
}) {
  final repo = _MockSettingsRepository();
  when(repo.getNotificationPreferences).thenAnswer((_) async => right(loaded));
  when(
    () => repo.updateNotificationPreferences(any()),
  ).thenAnswer((invocation) async {
    return right(
      invocation.positionalArguments.first as NotificationPreferences,
    );
  });
  when(
    () => repo.updateQuietHours(
      enabled: any(named: 'enabled'),
      startHhMm: any(named: 'startHhMm'),
      endHhMm: any(named: 'endHhMm'),
    ),
  ).thenAnswer((_) async => right(loaded));
  return repo;
}

Widget _app(SettingsRepository repo) => ProviderScope(
  overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
  child: const MaterialApp(home: NotificationPrefsScreen()),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Pumps the screen on a viewport tall enough to mount every row at once —
/// the list builds lazily, so off-screen switches are simply not there.
Future<void> _pumpScreen(WidgetTester tester, SettingsRepository repo) async {
  tester.view.physicalSize = const Size(600, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(repo));
  await _settle(tester);
}

/// Finds the [Switch] inside the row whose semantics node carries [title].
///
/// Going through semantics rather than through the visible [Text] is
/// deliberate: it fails if a control loses its label, which is one of the
/// things being checked.
Finder _switchFor(String title) => find.descendant(
  of: find.bySemanticsLabel(RegExp(RegExp.escape(title))),
  matching: find.byType(Switch),
);

Future<void> _toggle(WidgetTester tester, String title) async {
  await tester.tap(_switchFor(title), warnIfMissed: false);
  await _settle(tester);
}

NotificationPreferences _lastSaved(_MockSettingsRepository repo) {
  final captured = verify(
    () => repo.updateNotificationPreferences(captureAny()),
  ).captured;
  return captured.last as NotificationPreferences;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const NotificationPreferences());
  });

  group('reads the stored value back', () {
    testWidgets('first load shows the server value, not a local default', (
      tester,
    ) async {
      await _pumpScreen(tester, _repo());

      // Entity defaults for these are true / true / true. If the screen ever
      // falls back to them, a customer who refused on one device sees consent
      // silently restored on the next — which is the whole defect.
      expect(
        tester.widget<Switch>(_switchFor('Deals and offers')).value,
        isFalse,
      );
      expect(
        tester.widget<Switch>(_switchFor('Enable Push Notifications')).value,
        isFalse,
      );
      expect(
        tester.widget<Switch>(_switchFor('Order Updates')).value,
        isFalse,
      );
      // And a server "on" is shown as on, so this is not just "everything off".
      expect(
        tester.widget<Switch>(_switchFor('Marketing email')).value,
        isTrue,
      );
      expect(
        tester.widget<Switch>(_switchFor('New Followers')).value,
        isTrue,
      );
    });

    testWidgets('quiet hours window comes from the server', (tester) async {
      await _pumpScreen(tester, _repo());
      expect(find.textContaining('11:00 PM'), findsOneWidget);
      expect(find.textContaining('7:30 AM'), findsOneWidget);
    });
  });

  group('writes to its endpoint', () {
    testWidgets('refusing deals and offers reaches the repository', (
      tester,
    ) async {
      final repo = _repo(loaded: _serverPrefs.copyWith(marketingPush: true));
      await _pumpScreen(tester, repo);

      await _toggle(tester, 'Deals and offers');

      expect(_lastSaved(repo).marketingPush, isFalse);
    });

    testWidgets('every kept push category reaches the repository', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpScreen(tester, repo);

      await _toggle(tester, 'Enable Push Notifications');
      expect(_lastSaved(repo).pushEnabled, isTrue);

      await _toggle(tester, 'Order Updates');
      expect(_lastSaved(repo).orderStatusChanges, isTrue);

      await _toggle(tester, 'Delivery Updates');
      expect(_lastSaved(repo).deliveryUpdates, isTrue);

      await _toggle(tester, 'Reel Activity');
      expect(_lastSaved(repo).newReelsFromCreators, isFalse);

      await _toggle(tester, 'New Followers');
      expect(_lastSaved(repo).newFollowers, isFalse);

      await _toggle(tester, 'Account Announcements');
      expect(_lastSaved(repo).paymentUpdates, isTrue);

      await _toggle(tester, 'Marketing email');
      expect(_lastSaved(repo).newsletter, isFalse);

      await _toggle(tester, 'Email Notifications');
      expect(_lastSaved(repo).emailNotifications, isFalse);

      await _toggle(tester, 'SMS Notifications');
      expect(_lastSaved(repo).smsNotifications, isFalse);
    });

    testWidgets('Pause Notifications uses the quiet-hours endpoint', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpScreen(tester, repo);

      await _toggle(tester, 'Pause Notifications');

      // The toggles payload has no quiet-hours field, so this switch must go
      // to its own endpoint — it previously went nowhere at all.
      verify(
        () => repo.updateQuietHours(
          enabled: true,
          startHhMm: '23:00',
          endHhMm: '07:30',
        ),
      ).called(1);
      verifyNever(() => repo.updateNotificationPreferences(any()));
    });

    testWidgets('a save failure is surfaced, not swallowed', (tester) async {
      final repo = _repo();
      when(() => repo.updateNotificationPreferences(any())).thenAnswer(
        (_) async => left(const NetworkExceptions.noInternetConnection()),
      );
      await _pumpScreen(tester, repo);

      await _toggle(tester, 'Deals and offers');

      expect(
        find.text('Failed to save preferences. Please try again.'),
        findsOneWidget,
      );
      // And the switch goes back to what the server still holds, rather than
      // sitting on a value that was never stored.
      expect(
        tester.widget<Switch>(_switchFor('Deals and offers')).value,
        _serverPrefs.marketingPush,
      );
    });
  });

  group('accessibility and layout', () {
    testWidgets('every switch carries a semantics label', (tester) async {
      await _pumpScreen(tester, _repo());

      const titles = [
        'Enable Push Notifications',
        'Order Updates',
        'Delivery Updates',
        'Reel Activity',
        'New Followers',
        'Account Announcements',
        'Deals and offers',
        'Marketing email',
        'Email Notifications',
        'SMS Notifications',
        'Pause Notifications',
      ];
      for (final title in titles) {
        expect(
          _switchFor(title),
          findsOneWidget,
          reason: '"$title" must expose a labelled switch',
        );
      }
      // Nothing unlabelled slipped in alongside them.
      expect(find.byType(Switch), findsNWidgets(titles.length));
    });

    testWidgets('state is spelled out, not left to colour', (tester) async {
      await _pumpScreen(tester, _repo());
      // The server prefs above are a mix of on and off, so both words must
      // be present somewhere on the first screenful.
      expect(find.text('Off'), findsWidgets);
      expect(find.text('On'), findsWidgets);
    });

    testWidgets('no overflow at 320dp with text scale 1.3', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsRepositoryProvider.overrideWithValue(_repo())],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: NotificationPrefsScreen(),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(tester.takeException(), isNull);

      // Walk the whole list; overflow is thrown during paint of whichever
      // row is on screen, so scrolling is part of the assertion.
      final list = find.byType(ListView);
      for (var i = 0; i < 8; i++) {
        await tester.drag(list, const Offset(0, -260));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('round trip', () {
    test('a refusal survives the DTO round trip', () {
      // Six switches used to share PushMarketing and were OR-ed together, so
      // refusing one and reloading read it straight back on.
      const refused = NotificationPreferences(marketingPush: false);
      final reloaded = NotificationPreferencesDto.fromDomain(
        refused,
      ).toDomain();
      expect(reloaded.marketingPush, isFalse);
    });

    test('no two controls share one backend column', () {
      // Start from every switch off. The fields not named here already
      // default to false, so naming them would only repeat the default.
      final allOff = const NotificationPreferences().copyWith(
        pushEnabled: false,
        orderStatusChanges: false,
        deliveryUpdates: false,
        paymentUpdates: false,
        marketingPush: false,
      );
      // Flip exactly one field at a time; exactly that field must come back
      // changed. A shared column shows up here as a second field moving.
      final flips = <String, NotificationPreferences Function()>{
        'pushEnabled': () => allOff.copyWith(pushEnabled: true),
        'emailNotifications': () => allOff.copyWith(emailNotifications: true),
        'smsNotifications': () => allOff.copyWith(smsNotifications: true),
        'orderStatusChanges': () => allOff.copyWith(orderStatusChanges: true),
        'deliveryUpdates': () => allOff.copyWith(deliveryUpdates: true),
        'newReelsFromCreators': () =>
            allOff.copyWith(newReelsFromCreators: true),
        'newFollowers': () => allOff.copyWith(newFollowers: true),
        'paymentUpdates': () => allOff.copyWith(paymentUpdates: true),
        'marketingPush': () => allOff.copyWith(marketingPush: true),
        'newsletter': () => allOff.copyWith(newsletter: true),
      };
      for (final entry in flips.entries) {
        final round = NotificationPreferencesDto.fromDomain(
          entry.value(),
        ).toDomain();
        final changed = <String>{
          if (round.pushEnabled) 'pushEnabled',
          if (round.emailNotifications) 'emailNotifications',
          if (round.smsNotifications) 'smsNotifications',
          if (round.orderStatusChanges) 'orderStatusChanges',
          if (round.deliveryUpdates) 'deliveryUpdates',
          if (round.newReelsFromCreators) 'newReelsFromCreators',
          if (round.newFollowers) 'newFollowers',
          if (round.paymentUpdates) 'paymentUpdates',
          if (round.marketingPush) 'marketingPush',
          if (round.newsletter) 'newsletter',
        };
        expect(
          changed,
          {entry.key},
          reason:
              'flipping ${entry.key} must move ${entry.key} and nothing else',
        );
      }
    });

    test('the toggles payload omits columns no control owns', () {
      final json = NotificationPreferencesDto.fromDomain(
        const NotificationPreferences(),
      ).toJson();
      // Messages gates partnership invites, which this screen never showed a
      // control for; sending a value would rewrite a setting nobody touched.
      expect(json.containsKey('emailMessages'), isFalse);
      expect(json.containsKey('pushMessages'), isFalse);
      // Security has no column on UpdateNotificationTogglesVm at all.
      expect(json.containsKey('emailSecurity'), isFalse);
      expect(json.containsKey('pushSecurity'), isFalse);
      // Quiet hours goes through its own endpoint.
      expect(json.containsKey('quietHoursEnabled'), isFalse);
    });
  });
}
