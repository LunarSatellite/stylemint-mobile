import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/repositories/clienteling_repository.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/screens/client_book_screen.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/screens/client_brief_screen.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/screens/my_clienteling_screen.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/shared/providers.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeAssociateRepo implements AssociateClientelingRepository {
  _FakeAssociateRepo({this.page, this.brief, this.activity, this.failure});

  final ClientAssignmentPage? page;
  final ClientBrief? brief;
  final List<ClientelingActivity>? activity;
  final NetworkExceptions? failure;

  Either<NetworkExceptions, T> _answer<T>(T? value) {
    final f = failure;
    if (f != null) return left(f);
    return right(value as T);
  }

  @override
  Future<Either<NetworkExceptions, ClientAssignmentPage>> listMyClients({
    String? cursor,
    int pageSize = 20,
  }) async => _answer(page);

  @override
  Future<Either<NetworkExceptions, ClientBrief>> getBrief(String id) async =>
      _answer(brief);

  @override
  Future<Either<NetworkExceptions, List<ClientelingActivity>>> listMyActivity({
    String? customerAccountId,
    int limit = 50,
  }) async {
    final rows = activity;
    if (rows == null) return left(const NetworkExceptions.unexpectedError());
    return right(rows);
  }

  @override
  Future<Either<NetworkExceptions, AssistSession>> openSession({
    required String customerAccountId,
    required String purpose,
    required String idempotencyKey,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, AssistSession>> closeSession({
    required String sessionId,
    required String idempotencyKey,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, OutreachAttempt>> sendOutreach({
    required String customerAccountId,
    required ClientelingOutreachChannel channel,
    required String subject,
    required String body,
    required String idempotencyKey,
    String? sessionId,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, AssistedOutcome>> claimOutcome({
    required String sessionId,
    required String orderId,
    required String idempotencyKey,
    String? note,
  }) async => left(const NetworkExceptions.unexpectedError());
}

class _FakeCustomerRepo implements CustomerClientelingRepository {
  _FakeCustomerRepo({this.claims, this.history, this.failure});

  final List<AssistedOutcome>? claims;
  final List<ClientelingActivity>? history;
  final NetworkExceptions? failure;

  @override
  Future<Either<NetworkExceptions, List<AssistedOutcome>>> listClaims({
    int limit = 50,
  }) async {
    final f = failure;
    if (f != null) return left(f);
    return right(claims ?? const []);
  }

  @override
  Future<Either<NetworkExceptions, List<ClientelingActivity>>> listHistory({
    int limit = 50,
  }) async {
    final rows = history;
    if (rows == null) return left(const NetworkExceptions.unexpectedError());
    return right(rows);
  }

  @override
  Future<Either<NetworkExceptions, AssistedOutcome>> confirmOutcome({
    required String outcomeId,
    required String idempotencyKey,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, AssistedOutcome>> rejectOutcome({
    required String outcomeId,
    required String idempotencyKey,
  }) async => left(const NetworkExceptions.unexpectedError());
}

// ── Harness ──────────────────────────────────────────────────────────────────

/// Every screen is checked at 320dp with a 1.3 text scale, the narrowest
/// combination this app supports and where overflows show up first.
const _narrow = Size(320, 700);

/// Same 320dp width, tall enough that a ListView builds every section so an
/// assertion can reach the ones that would otherwise sit below the fold.
const _narrowTall = Size(320, 2600);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  _FakeAssociateRepo? associate,
  _FakeCustomerRepo? customer,
  Size size = _narrow,
  double textScale = 1.3,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (associate != null)
          associateClientelingRepositoryProvider.overrideWithValue(associate),
        if (customer != null)
          customerClientelingRepositoryProvider.overrideWithValue(customer),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(home: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ClientAssignment _assignment({
  String? displayName = 'Aarati Shrestha',
  String? handle = 'aarati',
}) => ClientAssignment(
  assignmentId: 'a1',
  vendorAccountId: 'v1',
  associateAccountId: 's1',
  customerAccountId: '44444444-4444-4444-4444-444444444444',
  customerDisplayName: displayName,
  customerHandle: handle,
  status: ClientAssignmentStatus.active,
  grantedUtc: DateTime.utc(2026, 9, 1, 10),
);

ClientBrief _brief() => ClientBrief(
  assignmentId: 'a1',
  vendorAccountId: 'v1',
  associateAccountId: 's1',
  customerAccountId: 'c1',
  customerDisplayName: 'Aarati Shrestha',
  customerAccountActive: true,
  contactability: const [
    Contactability(
      channel: ClientelingOutreachChannel.email,
      allowed: true,
      decision: ClientelingOutreachDecision.sent,
      reason: 'Consented to be contacted by email.',
    ),
    Contactability(
      channel: ClientelingOutreachChannel.sms,
      allowed: false,
      decision: ClientelingOutreachDecision.blockedNoConsent,
      reason: 'No consent to be contacted by SMS.',
    ),
  ],
  recentOrdersWithThisVendor: [
    ClientOrderSummary(
      orderId: 'o1',
      orderNumber: 'SM-1042',
      vendorSubOrderStatus: 'Delivered',
      placedUtc: DateTime.utc(2026, 8, 20, 9, 30),
      itemCount: 3,
    ),
  ],
  withheld: const ['email address', 'order totals, prices and discounts'],
);

AssistedOutcome _claim({
  AssistedOutcomeStatus status = AssistedOutcomeStatus.claimed,
  bool isCredited = false,
}) => AssistedOutcome(
  outcomeId: 'x1',
  sessionId: 's1',
  vendorAccountId: 'v1',
  associateAccountId: 'a1',
  customerAccountId: 'c1',
  orderId: 'o1',
  orderNumber: 'SM-1042',
  status: status,
  isCredited: isCredited,
  note: 'Helped choose the size.',
  claimedUtc: DateTime.utc(2026, 8, 20, 10),
);

void main() {
  group('ClientBookScreen', () {
    testWidgets('loaded — lists the assigned clients', (tester) async {
      await _pump(
        tester,
        const ClientBookScreen(),
        associate: _FakeAssociateRepo(
          page: ClientAssignmentPage(items: [_assignment()]),
        ),
      );

      expect(find.text('Aarati Shrestha'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('No clients assigned to you'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty — reads as empty, never as a count', (tester) async {
      await _pump(
        tester,
        const ClientBookScreen(),
        associate: _FakeAssociateRepo(
          page: const ClientAssignmentPage(items: []),
        ),
      );

      expect(find.text('No clients assigned to you'), findsOneWidget);
      // An empty book shows no numbers at all — no "0 clients".
      expect(find.textContaining('0'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure — shows the error, not an empty list', (tester) async {
      await _pump(
        tester,
        const ClientBookScreen(),
        associate: _FakeAssociateRepo(
          failure: const NetworkExceptions.serverUnavailable(),
        ),
      );

      expect(find.text('No clients assigned to you'), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a nameless client falls back to its account id', (
      tester,
    ) async {
      await _pump(
        tester,
        const ClientBookScreen(),
        associate: _FakeAssociateRepo(
          page: ClientAssignmentPage(
            items: [_assignment(displayName: null, handle: null)],
          ),
        ),
      );

      expect(find.text('Account 44444444'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ClientBriefScreen', () {
    testWidgets('loaded — shows the consent gate and what is withheld', (
      tester,
    ) async {
      await _pump(
        tester,
        const ClientBriefScreen(customerAccountId: 'c1'),
        associate: _FakeAssociateRepo(brief: _brief(), activity: const []),
        size: _narrowTall,
      );

      expect(find.text('Aarati Shrestha'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(
        find.text('No consent to be contacted by SMS.'),
        findsOneWidget,
      );
      expect(find.text('Not shown to you'), findsOneWidget);
      expect(find.text('email address'), findsOneWidget);
      // The brief carries no money, so no money is rendered.
      expect(find.textContaining('Rs'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unreadable trail is not reported as an empty trail', (
      tester,
    ) async {
      await _pump(
        tester,
        const ClientBriefScreen(customerAccountId: 'c1'),
        // activity: null makes listMyActivity fail while the brief loads.
        associate: _FakeAssociateRepo(brief: _brief()),
        size: _narrowTall,
      );

      expect(find.text('Your trail could not be loaded.'), findsOneWidget);
      expect(find.text('Nothing recorded yet.'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty trail reads as nothing recorded', (tester) async {
      await _pump(
        tester,
        const ClientBriefScreen(customerAccountId: 'c1'),
        associate: _FakeAssociateRepo(brief: _brief(), activity: const []),
        size: _narrowTall,
      );

      expect(find.text('Nothing recorded yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure — shows the error', (tester) async {
      await _pump(
        tester,
        const ClientBriefScreen(customerAccountId: 'c1'),
        associate: _FakeAssociateRepo(
          failure: const NetworkExceptions.notFound(),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Not shown to you'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('MyClientelingScreen', () {
    testWidgets('loaded — a claim awaits the customer and is not credit', (
      tester,
    ) async {
      await _pump(
        tester,
        const MyClientelingScreen(),
        customer: _FakeCustomerRepo(
          claims: [_claim()],
          history: [
            ClientelingActivity(
              activityId: 'g1',
              associateAccountId: 'a1',
              customerAccountId: 'c1',
              type: ClientelingActivityType.briefViewed,
              occurredUtc: DateTime.utc(2026, 9, 2, 12),
            ),
          ],
        ),
        size: _narrowTall,
      );

      expect(find.text('SM-1042'), findsOneWidget);
      expect(find.text('Awaiting your answer'), findsOneWidget);
      expect(find.text('Yes, they helped'), findsOneWidget);
      expect(find.text('No, they did not'), findsOneWidget);
      expect(
        find.text('An associate opened your file'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty — says nothing is waiting, shows no zero', (
      tester,
    ) async {
      await _pump(
        tester,
        const MyClientelingScreen(),
        customer: _FakeCustomerRepo(claims: const [], history: const []),
      );

      expect(
        find.text('No claims are waiting for your answer.'),
        findsOneWidget,
      );
      expect(
        find.text('No associate has acted on your account.'),
        findsOneWidget,
      );
      expect(find.textContaining('0'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unreadable history is distinct from an empty one', (
      tester,
    ) async {
      await _pump(
        tester,
        const MyClientelingScreen(),
        customer: _FakeCustomerRepo(claims: const []),
      );

      expect(find.text('Your record could not be loaded.'), findsOneWidget);
      expect(
        find.text('No associate has acted on your account.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure — shows the error instead of an empty record', (
      tester,
    ) async {
      await _pump(
        tester,
        const MyClientelingScreen(),
        customer: _FakeCustomerRepo(
          failure: const NetworkExceptions.noInternetConnection(),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.text('No claims are waiting for your answer.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a confirmed claim offers no further decision', (tester) async {
      await _pump(
        tester,
        const MyClientelingScreen(),
        customer: _FakeCustomerRepo(
          claims: [
            _claim(
              status: AssistedOutcomeStatus.confirmed,
              isCredited: true,
            ),
          ],
          history: const [],
        ),
      );

      expect(find.text('Confirmed by the customer'), findsOneWidget);
      expect(find.text('Yes, they helped'), findsNothing);
      expect(
        find.text('No claims are waiting for your answer.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
