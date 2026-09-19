import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/handover_delegation_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/handover_delegation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/handover_delegation_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/handover_delegation_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/handover_delegation_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class _MockDataSource extends Mock implements HandoverDelegationDataSource {}

const _tracking = 'SM-D-00000001';
const _code = 'ZK7Q4M2X';
final DateTime _now = DateTime.utc(2026, 9, 19, 12);

DateTime _clock() => _now;

HandoverDelegation _delegation({
  String id = 'del-1',
  String name = 'Amina Diallo',
  HandoverDelegationStatus status = HandoverDelegationStatus.active,
  Set<DelegatedException> exceptions = const <DelegatedException>{},
  DateTime? start,
  DateTime? end,
  String? revocationReason,
}) => HandoverDelegation(
  id: id,
  trackingNumber: _tracking,
  delegateDisplayName: name,
  relationship: DelegateRelationship.neighbour,
  allowedExceptions: exceptions,
  windowStartUtc: start ?? _now,
  windowEndUtc: end ?? _now.add(const Duration(hours: 4)),
  status: status,
  revocationReason: revocationReason,
  createdUtc: _now.subtract(const Duration(minutes: 5)),
);

void main() {
  late _MockDataSource dataSource;

  setUpAll(() {
    registerFallbackValue(DelegateRelationship.neighbour);
    registerFallbackValue(<DelegatedException>{});
    registerFallbackValue(DateTime.utc(2026));
  });

  setUp(() {
    dataSource = _MockDataSource();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget host(
    Widget child, {
    double textScale = 1,
    Size size = const Size(390, 844),
  }) => ProviderScope(
    overrides: [
      handoverDelegationDataSourceProvider.overrideWithValue(dataSource),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          backgroundColor: DesignTokens.bgAppBody,
          body: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );

  Widget card({bool canDelegate = true}) => host(
    HandoverDelegationCard(
      trackingNumber: _tracking,
      canDelegate: canDelegate,
      clock: _clock,
    ),
  );

  // ── Creation, and the code shown once ────────────────────────────────────

  group('creating a delegation', () {
    setUp(() {
      when(() => dataSource.list(_tracking)).thenAnswer((_) async => []);
      when(
        () => dataSource.authorise(
          trackingNumber: any(named: 'trackingNumber'),
          delegateDisplayName: any(named: 'delegateDisplayName'),
          delegateContact: any(named: 'delegateContact'),
          relationship: any(named: 'relationship'),
          allowedExceptions: any(named: 'allowedExceptions'),
          windowStartUtc: any(named: 'windowStartUtc'),
          windowEndUtc: any(named: 'windowEndUtc'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer(
        (_) async => IssuedHandoverDelegation(
          delegation: _delegation(),
          verificationCode: _code,
        ),
      );
    });

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> fillAndSubmit(WidgetTester tester) async {
      await tester.ensureVisible(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'Amina Diallo');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField).last);
      await tester.enterText(find.byType(TextField).last, 'amina@example.com');
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const ValueKey('handover-relationship-neighbour')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('handover-authorise-button')),
      );
    }

    testWidgets('shows the code once and says it will not be shown again', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const HandoverDelegationSheet(
            trackingNumber: _tracking,
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('handover-one-time-code')),
        findsNothing,
      );

      await fillAndSubmit(tester);

      expect(
        find.byKey(const ValueKey('handover-one-time-code')),
        findsOneWidget,
      );
      // Grouped in fours for reading aloud.
      expect(find.text('ZK7Q 4M2X'), findsOneWidget);
      expect(
        find.text('Shown once. You will not be able to see it again.'),
        findsOneWidget,
      );
      // And the honest alternative is offered, not a way to get it back.
      expect(
        find.textContaining('revoke it and authorise someone again'),
        findsOneWidget,
      );
    });

    testWidgets('the code lands in no storage, no log and no route', (
      tester,
    ) async {
      // Record every platform-channel message the app sends while the code is
      // on screen — this catches shared_preferences, secure storage, the
      // clipboard and anything else that leaves the isolate.
      final sent = <String>[];
      final binding = TestDefaultBinaryMessengerBinding.instance;
      const channels = <String>[
        'plugins.flutter.io/shared_preferences',
        'plugins.flutter.io/shared_preferences_android',
        'plugins.it_nomads.com/flutter_secure_storage',
        'flutter/platform',
        'dev.fluttercommunity.plus/share',
      ];
      for (final name in channels) {
        binding.defaultBinaryMessenger.setMockMessageHandler(name, (
          message,
        ) async {
          if (message != null) {
            sent.add(
              String.fromCharCodes(
                message.buffer.asUint8List(
                  message.offsetInBytes,
                  message.lengthInBytes,
                ),
              ),
            );
          }
          return null;
        });
      }
      addTearDown(() {
        for (final name in channels) {
          binding.defaultBinaryMessenger.setMockMessageHandler(name, null);
        }
      });

      final logged = <String>[];
      await tester.pumpWidget(
        host(
          const HandoverDelegationSheet(
            trackingNumber: _tracking,
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final previous = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logged.add(message);
      };
      await fillAndSubmit(tester);
      // Restored inside the body: the test binding asserts the foundation
      // debug hooks are back to default before the test finishes.
      debugPrint = previous;
      expect(find.text('ZK7Q 4M2X'), findsOneWidget);

      // Storage, inspected after the code has been created and drawn.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      for (final blob in sent) {
        expect(blob, isNot(contains(_code)), reason: 'platform channel');
      }
      for (final line in logged) {
        expect(line, isNot(contains(_code)), reason: 'log line');
      }
      // No route was pushed at all — the sheet is modal, and nothing about
      // the code is navigator state.
      expect(find.byType(HandoverDelegationSheet), findsOneWidget);
    });

    testWidgets('exceptions default to none, and none is explained', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const HandoverDelegationSheet(
            trackingNumber: _tracking,
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final e in DelegatedException.values) {
        final box = tester.widget<CheckboxListTile>(
          find.byKey(ValueKey('handover-exception-${e.name}')),
        );
        expect(box.value, isFalse, reason: e.name);
        // Plain language, not the flag name.
        expect(find.text(HandoverCopy.exceptionTitle(e)), findsOneWidget);
        expect(find.text(HandoverCopy.exceptionConsequence(e)), findsOneWidget);
      }
      expect(find.text(HandoverCopy.noExceptionsExplainer), findsOneWidget);

      await fillAndSubmit(tester);
      final captured = verify(
        () => dataSource.authorise(
          trackingNumber: any(named: 'trackingNumber'),
          delegateDisplayName: any(named: 'delegateDisplayName'),
          delegateContact: any(named: 'delegateContact'),
          relationship: any(named: 'relationship'),
          allowedExceptions: captureAny(named: 'allowedExceptions'),
          windowStartUtc: any(named: 'windowStartUtc'),
          windowEndUtc: any(named: 'windowEndUtc'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).captured.single;
      expect(captured, isEmpty);
    });

    testWidgets('a zero-length window is refused before the call is made', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const HandoverDelegationSheet(
            trackingNumber: _tracking,
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 hours down to nothing, in quarter-hour steps.
      final minus = find.byKey(const ValueKey('handover-length-minus'));
      await tester.ensureVisible(minus);
      await tester.pumpAndSettle();
      for (var i = 0; i < 16; i++) {
        await tester.tap(minus);
        await tester.pump();
      }
      expect(
        find.text(
          HandoverCopy.windowProblem(HandoverWindowProblem.endsBeforeStart),
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('handover-authorise-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('handover-authorise-button')));
      await tester.pumpAndSettle();
      // The customer is told, and nothing is sent.
      verifyNever(
        () => dataSource.authorise(
          trackingNumber: any(named: 'trackingNumber'),
          delegateDisplayName: any(named: 'delegateDisplayName'),
          delegateContact: any(named: 'delegateContact'),
          relationship: any(named: 'relationship'),
          allowedExceptions: any(named: 'allowedExceptions'),
          windowStartUtc: any(named: 'windowStartUtc'),
          windowEndUtc: any(named: 'windowEndUtc'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
      // The 15-minute floor is stated up front, so nobody aims below it.
      expect(
        find.textContaining('Between 15 minutes and 72 hours long'),
        findsOneWidget,
      );
    });

    testWidgets('a window longer than 72 hours blocks submission', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const HandoverDelegationSheet(
            trackingNumber: _tracking,
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('handover-length-3 days')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('handover-length-3 days')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('handover-window-problem')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('handover-length-plus')));
      await tester.pump();
      expect(
        find.text(HandoverCopy.windowProblem(HandoverWindowProblem.tooLong)),
        findsOneWidget,
      );
    });

    testWidgets('the window is stated in words, not just as two pickers', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const HandoverDelegationSheet(
            trackingNumber: _tracking,
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sentence = tester.widget<Text>(
        find.byKey(const ValueKey('handover-window-sentence')),
      );
      expect(sentence.data, contains('4 hours'));
      expect(
        find.textContaining('Between 15 minutes and 72 hours long'),
        findsOneWidget,
      );
    });

    testWidgets('a refusal gets its own actionable copy', (tester) async {
      when(
        () => dataSource.authorise(
          trackingNumber: any(named: 'trackingNumber'),
          delegateDisplayName: any(named: 'delegateDisplayName'),
          delegateContact: any(named: 'delegateContact'),
          relationship: any(named: 'relationship'),
          allowedExceptions: any(named: 'allowedExceptions'),
          windowStartUtc: any(named: 'windowStartUtc'),
          windowEndUtc: any(named: 'windowEndUtc'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(_dioFailure(HandoverCopy.codeConflict));

      await tester.pumpWidget(
        host(
          const HandoverDelegationSheet(
            trackingNumber: _tracking,
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await fillAndSubmit(tester);

      final copy = HandoverCopy.refusal(HandoverCopy.codeConflict);
      expect(find.text(copy.title), findsOneWidget);
      expect(find.text(copy.body), findsOneWidget);
      // And no code panel: nothing was created.
      expect(
        find.byKey(const ValueKey('handover-one-time-code')),
        findsNothing,
      );
    });

    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      await tester.pumpWidget(
        host(
          const HandoverDelegationSheet(
            trackingNumber: _tracking,
            clock: _clock,
          ),
          textScale: 1.3,
          size: const Size(320, 900),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await fillAndSubmit(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('handover-one-time-code')),
        findsOneWidget,
      );
    });
  });

  // ── The card: status, history, revocation ────────────────────────────────

  group('the card on the parcel', () {
    testWidgets('offers creation where the customer already is', (
      tester,
    ) async {
      when(() => dataSource.list(_tracking)).thenAnswer((_) async => []);
      await tester.pumpWidget(card());
      await tester.pumpAndSettle();
      expect(find.text("Can't be there when it arrives?"), findsOneWidget);
      expect(
        find.byKey(const ValueKey('handover-start-button')),
        findsOneWidget,
      );
    });

    testWidgets('hides creation once the parcel can no longer be delegated', (
      tester,
    ) async {
      when(() => dataSource.list(_tracking)).thenAnswer((_) async => []);
      await tester.pumpWidget(card(canDelegate: false));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('handover-delegation-card')),
        findsNothing,
      );
    });

    testWidgets('revoke is one step from the active delegation', (
      tester,
    ) async {
      when(() => dataSource.list(_tracking)).thenAnswer(
        (_) async => [_delegation()],
      );
      when(
        () => dataSource.revoke(
          trackingNumber: any(named: 'trackingNumber'),
          delegationId: any(named: 'delegationId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer(
        (_) async => _delegation(status: HandoverDelegationStatus.revoked),
      );

      await tester.pumpWidget(card());
      await tester.pumpAndSettle();

      final revoke = find.byKey(const ValueKey('handover-revoke-button'));
      expect(revoke, findsOneWidget);
      await tester.tap(revoke);
      await tester.pumpAndSettle();

      // One tap — no confirmation dialog, no second screen.
      expect(find.byType(AlertDialog), findsNothing);
      verify(
        () => dataSource.revoke(
          trackingNumber: _tracking,
          delegationId: 'del-1',
          idempotencyKey: any(named: 'idempotencyKey'),
          reason: any(named: 'reason'),
        ),
      ).called(1);
      expect(
        find.byKey(const ValueKey('handover-revoked-confirmation')),
        findsOneWidget,
      );
    });

    testWidgets('revoke stays available right up to the moment of handover', (
      tester,
    ) async {
      when(() => dataSource.list(_tracking)).thenAnswer(
        (_) async => [
          _delegation(
            start: _now.subtract(const Duration(hours: 3)),
            end: _now.add(const Duration(seconds: 1)),
          ),
        ],
      );
      await tester.pumpWidget(card());
      await tester.pumpAndSettle();
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Revoke now'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('a failed revoke explains why, in its own words', (
      tester,
    ) async {
      when(() => dataSource.list(_tracking)).thenAnswer(
        (_) async => [_delegation()],
      );
      when(
        () => dataSource.revoke(
          trackingNumber: any(named: 'trackingNumber'),
          delegationId: any(named: 'delegationId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          reason: any(named: 'reason'),
        ),
      ).thenThrow(_dioFailure(HandoverCopy.codeAlreadyUsed));

      await tester.pumpWidget(card());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('handover-revoke-button')));
      await tester.pumpAndSettle();

      final copy = HandoverCopy.refusal(HandoverCopy.codeAlreadyUsed);
      expect(find.text(copy.title), findsOneWidget);
      expect(find.text(copy.body), findsOneWidget);
    });

    testWidgets('each status renders distinguishably without colour', (
      tester,
    ) async {
      when(() => dataSource.list(_tracking)).thenAnswer(
        (_) async => [
          _delegation(
            id: 'a',
            name: 'Used One',
            status: HandoverDelegationStatus.consumed,
          ),
          _delegation(
            id: 'b',
            name: 'Revoked One',
            status: HandoverDelegationStatus.revoked,
            revocationReason: 'Changed my mind',
          ),
          _delegation(
            id: 'c',
            name: 'Expired One',
            status: HandoverDelegationStatus.expired,
          ),
          _delegation(id: 'd', name: 'Active One'),
        ],
      );
      await tester.pumpWidget(card());
      await tester.pumpAndSettle();

      final pills = tester
          .widgetList<MallStatusPill>(find.byType(MallStatusPill))
          .toList();
      expect(pills, hasLength(4));
      // Every pill carries a glyph, and no two states share one — so the
      // state survives a greyscale screen.
      final icons = pills.map((p) => p.icon).toList();
      expect(icons.every((i) => i != null), isTrue);
      expect(icons.toSet(), hasLength(4));
      // And each label is its own word.
      expect(pills.map((p) => p.label).toSet(), hasLength(4));
      for (final label in ['Active', 'Used', 'Revoked', 'Expired']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // No invented status.
      expect(find.text('Unavailable'), findsNothing);
      expect(find.textContaining('Changed my mind'), findsOneWidget);
    });

    testWidgets('an active row past its window is drawn as expired', (
      tester,
    ) async {
      when(() => dataSource.list(_tracking)).thenAnswer(
        (_) async => [
          _delegation(
            start: _now.subtract(const Duration(hours: 6)),
            end: _now.subtract(const Duration(hours: 1)),
          ),
        ],
      );
      await tester.pumpWidget(card());
      await tester.pumpAndSettle();
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Active'), findsNothing);
      expect(
        find.byKey(const ValueKey('handover-revoke-button')),
        findsNothing,
      );
    });

    testWidgets('the window and the exceptions are spelled out', (
      tester,
    ) async {
      when(() => dataSource.list(_tracking)).thenAnswer(
        (_) async => [
          _delegation(
            exceptions: const {DelegatedException.visibleDamage},
          ),
        ],
      );
      await tester.pumpWidget(card());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('4 hours', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('visible damage', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text(
          'Takes effect immediately — even if the courier is already at the '
          'door.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      when(() => dataSource.list(_tracking)).thenAnswer(
        (_) async => [
          _delegation(
            name: 'Bartholomew Ferdinand Oyelaran-Whitmore',
            exceptions: DelegatedException.values.toSet(),
          ),
          _delegation(
            id: 'x',
            name: 'Someone Else Entirely With A Long Name',
            status: HandoverDelegationStatus.revoked,
          ),
        ],
      );
      await tester.pumpWidget(
        host(
          const HandoverDelegationCard(
            trackingNumber: _tracking,
            clock: _clock,
          ),
          textScale: 1.3,
          size: const Size(320, 900),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('every control carries a semantics label', (tester) async {
      when(() => dataSource.list(_tracking)).thenAnswer(
        (_) async => [_delegation()],
      );
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(card());
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          RegExp('Revoke now. Amina Diallo will no longer'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          HandoverCopy.statusSemantics(HandoverDelegationStatus.active),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('^Window: ')), findsOneWidget);
      handle.dispose();
    });
  });

  group('the sheet controls carry semantics labels', () {
    testWidgets('name, relationship, window, exceptions and actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const HandoverDelegationSheet(
            trackingNumber: _tracking,
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Authorise this person and show their one-time code',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Cancel without authorising anyone'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Shorten the window by fifteen minutes'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Lengthen the window by fifteen minutes'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Change the start time')),
        findsOneWidget,
      );
      for (final e in DelegatedException.values) {
        expect(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(HandoverCopy.exceptionTitle(e))),
          ),
          findsWidgets,
          reason: e.name,
        );
      }
      handle.dispose();
    });
  });
}

/// A backend refusal shaped like the real one: `errorCode` in the body.
DioException _dioFailure(String errorCode) {
  final request = RequestOptions(path: '/v1/deliveries/$_tracking');
  return DioException(
    requestOptions: request,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: 409,
      data: <String, dynamic>{'errorCode': errorCode},
    ),
  );
}
