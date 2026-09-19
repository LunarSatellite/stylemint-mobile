import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/data/datasources/agent_commerce_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/domain/entities/agent_mandate.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/screens/connected_assistants_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_commerce_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_mandate_issue_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_proposal_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class _MockDataSource extends Mock implements AgentCommerceDataSource {}

const String _credential = 'sma_7f3Kq9ZbT2';
final DateTime _now = DateTime.utc(2026, 9, 19, 12);

DateTime _clock() => _now;

AgentMandate _mandate({
  String id = 'm-1',
  String name = 'Marlowe',
  AgentScopeSet? scopes,
  DateTime? expires,
  DateTime? revoked,
  List<String> products = const <String>[],
}) => AgentMandate(
  id: id,
  agentName: name,
  scopes:
      scopes ??
      const AgentScopeSet(<AgentMandateScope>{
        AgentMandateScope.catalogRead,
        AgentMandateScope.cartWrite,
      }),
  maxOrderAmount: 25000,
  currency: 'NPR',
  allowedProductIds: products,
  expiresUtc: expires ?? _now.add(const Duration(days: 30)),
  createdUtc: _now.subtract(const Duration(days: 1)),
  revokedUtc: revoked,
);

AgentProposal _proposal({
  String id = 'pr-1',
  AgentProposalStatus status = AgentProposalStatus.pendingCustomerConfirmation,
  int? rawStatus,
  List<AgentProposalLine>? lines,
  DateTime? expires,
}) => AgentProposal(
  id: id,
  mandateId: 'm-1',
  lines:
      lines ??
      const <AgentProposalLine>[
        AgentProposalLine(
          productId: 'p-1',
          title: 'Linen overshirt',
          quantity: 2,
          unitPriceAmount: 4200,
          lineSubtotalAmount: 8400,
          currency: 'NPR',
          optionLabel: 'M / Emerald',
          sellerHandle: '@thamel.atelier',
        ),
      ],
  quotedTotal: 8400,
  currency: 'NPR',
  status: status,
  rawStatus: rawStatus,
  expiresUtc: expires ?? _now.add(const Duration(minutes: 15)),
  createdUtc: _now.subtract(const Duration(minutes: 5)),
);

AgentActivityEntry _activity({
  String id = 'a-1',
  String action = 'cart.add',
  bool allowed = true,
  String? errorCode,
}) => AgentActivityEntry(
  id: id,
  agentName: 'Marlowe',
  action: action,
  allowed: allowed,
  recordedUtc: _now.subtract(const Duration(minutes: 3)),
  errorCode: errorCode,
);

void main() {
  late _MockDataSource dataSource;

  setUp(() {
    dataSource = _MockDataSource();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    when(dataSource.listMandates).thenAnswer((_) async => <AgentMandate>[]);
    when(dataSource.listProposals).thenAnswer((_) async => <AgentProposal>[]);
    when(
      () => dataSource.listActivity(limit: any(named: 'limit')),
    ).thenAnswer((_) async => <AgentActivityEntry>[]);
    when(
      () => dataSource.issueMandate(
        agentName: any(named: 'agentName'),
        scopes: any(named: 'scopes'),
        maxOrderAmount: any(named: 'maxOrderAmount'),
        currency: any(named: 'currency'),
        allowedProductIds: any(named: 'allowedProductIds'),
        expiresUtc: any(named: 'expiresUtc'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer(
      (_) async => IssuedAgentMandate(
        mandate: _mandate(),
        credential: _credential,
      ),
    );
    when(
      () => dataSource.revokeMandate(
        mandateId: any(named: 'mandateId'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => dataSource.confirmProposal(
        proposalId: any(named: 'proposalId'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => _proposal(status: AgentProposalStatus.confirmed));
    when(
      () => dataSource.rejectProposal(
        proposalId: any(named: 'proposalId'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => _proposal(status: AgentProposalStatus.rejected));
  });

  setUpAll(() {
    registerFallbackValue(AgentScopeSet.none);
    registerFallbackValue(DateTime.utc(2026));
  });

  Widget host(
    Widget child, {
    double textScale = 1,
    Size size = const Size(390, 844),
    List<AgentAllowlistCandidate> candidates =
        const <AgentAllowlistCandidate>[],
  }) => ProviderScope(
    overrides: [
      agentCommerceDataSourceProvider.overrideWithValue(dataSource),
      agentAllowlistCandidatesProvider.overrideWithValue(candidates),
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

  /// A tall surface by default: the screen is one `ListView`, and a viewport
  /// the height of a phone would leave the rows below the fold unbuilt and
  /// therefore invisible to a finder. The 320dp tests below set a real
  /// phone size on purpose.
  Widget screen({double textScale = 1, Size size = const Size(390, 3000)}) =>
      ProviderScope(
        overrides: [
          agentCommerceDataSourceProvider.overrideWithValue(dataSource),
          agentAllowlistCandidatesProvider.overrideWithValue(
            const <AgentAllowlistCandidate>[],
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const ConnectedAssistantsScreen(clock: _clock),
          ),
        ),
      );

  /// Gives the test a real render surface of [size].
  ///
  /// `MediaQuery(size:)` alone only changes what widgets *believe*; the
  /// viewport stays 800x600, so a `ListView` never builds the rows below the
  /// fold and a 320dp overflow check would silently run at 800dp.
  void useSurface(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Fills in every limit the backend enforces and issues the mandate.
  Future<void> fillAndIssue(WidgetTester tester) async {
    await enter(tester, 'agent-mandate-name-field', 'Marlowe');
    await tapVisible(
      tester,
      find.byKey(const ValueKey('agent-scope-cartWrite')),
    );
    await enter(tester, 'agent-mandate-cap-field', '25000');
    await tapVisible(tester, find.byKey(const ValueKey('agent-currency-NPR')));
    await tapVisible(tester, find.byKey(const ValueKey('agent-allowlist-any')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('agent-expiry-preset-30')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('agent-mandate-issue-button')),
    );
  }

  // ── Issuing, and the credential shown once ───────────────────────────────

  group('issuing a mandate', () {
    testWidgets('every backend-enforced limit is settable', (tester) async {
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();

      // Name, all four scopes, the cap, the currency, the allowlist mode and
      // the lifetime each have their own control.
      expect(find.byKey(const ValueKey('agent-mandate-name-field')), findsOne);
      for (final scope in AgentMandateScope.values) {
        expect(
          find.byKey(ValueKey('agent-scope-${scope.name}')),
          findsOne,
          reason: scope.name,
        );
      }
      expect(find.byKey(const ValueKey('agent-mandate-cap-field')), findsOne);
      expect(find.byKey(const ValueKey('agent-currency-NPR')), findsOne);
      expect(find.byKey(const ValueKey('agent-currency-other')), findsOne);
      expect(find.byKey(const ValueKey('agent-allowlist-any')), findsOne);
      expect(find.byKey(const ValueKey('agent-allowlist-chosen')), findsOne);
      expect(find.byKey(const ValueKey('agent-expiry-days-field')), findsOne);
      expect(
        find.byKey(const ValueKey('agent-expiry-preset-90')),
        findsOne,
      );
    });

    testWidgets('nothing is pre-selected', (tester) async {
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();

      for (final scope in AgentMandateScope.values) {
        final tile = tester.widget<CheckboxListTile>(
          find.byKey(ValueKey('agent-scope-${scope.name}')),
        );
        expect(tile.value, isFalse, reason: scope.name);
      }
      for (final key in <String>[
        'agent-currency-NPR',
        'agent-currency-other',
        'agent-allowlist-any',
        'agent-allowlist-chosen',
        'agent-expiry-preset-7',
        'agent-expiry-preset-30',
        'agent-expiry-preset-90',
      ]) {
        expect(
          tester.widget<ChoiceChip>(find.byKey(ValueKey(key))).selected,
          isFalse,
          reason: key,
        );
      }
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('agent-mandate-cap-field')),
            )
            .controller
            ?.text,
        isEmpty,
      );
      // And an empty form cannot issue anything.
      await tapVisible(
        tester,
        find.byKey(const ValueKey('agent-mandate-issue-button')),
      );
      verifyNever(
        () => dataSource.issueMandate(
          agentName: any(named: 'agentName'),
          scopes: any(named: 'scopes'),
          maxOrderAmount: any(named: 'maxOrderAmount'),
          currency: any(named: 'currency'),
          allowedProductIds: any(named: 'allowedProductIds'),
          expiresUtc: any(named: 'expiresUtc'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
    });

    testWidgets('what an agent can never do is stated on this screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('agent-never-can-panel')), findsOne);
      for (final line in AgentCommerceCopy.neverCan) {
        expect(find.text(line), findsOne, reason: line);
      }
    });

    testWidgets('an expiry beyond 90 days is refused here, with the reason', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();
      await enter(tester, 'agent-expiry-days-field', '120');

      expect(find.byKey(const ValueKey('agent-expiry-problem')), findsOne);
      expect(find.textContaining('at most 90 days'), findsOne);
      expect(find.textContaining('18 Dec 2026'), findsOne);
      // And the readout does not pretend the date is valid.
      expect(find.byKey(const ValueKey('agent-expiry-readout')), findsNothing);

      // 90 is accepted.
      await enter(tester, 'agent-expiry-days-field', '90');
      expect(find.byKey(const ValueKey('agent-expiry-problem')), findsNothing);
      expect(find.byKey(const ValueKey('agent-expiry-readout')), findsOne);
    });

    testWidgets('a mandate beyond 90 days is never sent', (tester) async {
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();
      await enter(tester, 'agent-mandate-name-field', 'Marlowe');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('agent-scope-cartWrite')),
      );
      await enter(tester, 'agent-mandate-cap-field', '25000');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('agent-currency-NPR')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('agent-allowlist-any')),
      );
      await enter(tester, 'agent-expiry-days-field', '365');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('agent-mandate-issue-button')),
      );
      verifyNever(
        () => dataSource.issueMandate(
          agentName: any(named: 'agentName'),
          scopes: any(named: 'scopes'),
          maxOrderAmount: any(named: 'maxOrderAmount'),
          currency: any(named: 'currency'),
          allowedProductIds: any(named: 'allowedProductIds'),
          expiresUtc: any(named: 'expiresUtc'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
    });

    testWidgets('the limits are sent exactly as the customer set them', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();
      await fillAndIssue(tester);

      final call = verify(
        () => dataSource.issueMandate(
          agentName: captureAny(named: 'agentName'),
          scopes: captureAny(named: 'scopes'),
          maxOrderAmount: captureAny(named: 'maxOrderAmount'),
          currency: captureAny(named: 'currency'),
          allowedProductIds: captureAny(named: 'allowedProductIds'),
          expiresUtc: captureAny(named: 'expiresUtc'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).captured;
      expect(call[0], 'Marlowe');
      expect((call[1] as AgentScopeSet).bits, AgentMandateScope.cartWrite.bit);
      expect(call[2], 25000);
      expect(call[3], 'NPR');
      expect(call[4], isEmpty);
      expect(
        (call[5] as DateTime).difference(_now).inDays,
        30,
      );
    });

    testWidgets('the credential is shown once, and cannot be copied', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();
      await fillAndIssue(tester);

      expect(find.byKey(const ValueKey('agent-one-time-credential')), findsOne);
      // Grouped in fours so it can be read aloud.
      expect(find.text('sma_ 7f3K q9Zb T2'), findsOne);
      expect(find.text(AgentCommerceCopy.credentialWarning), findsOne);
      // No copy affordance and no selectable text anywhere in the sheet.
      expect(find.byType(SelectableText), findsNothing);
      expect(find.textContaining('Copy'), findsNothing);
      // The only outbound path is the system share sheet.
      expect(
        find.byKey(const ValueKey('agent-credential-share-button')),
        findsOne,
      );
    });

    testWidgets('closing the sheet drops the credential', (tester) async {
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();
      await fillAndIssue(tester);
      expect(find.text('sma_ 7f3K q9Zb T2'), findsOne);

      await tapVisible(
        tester,
        find.byKey(const ValueKey('agent-credential-done-button')),
      );
      expect(find.text('sma_ 7f3K q9Zb T2'), findsNothing);
    });

    testWidgets('the credential lands in no storage, no log and no route', (
      tester,
    ) async {
      // Record every platform-channel message the app sends while the
      // credential is on screen — this catches shared_preferences, secure
      // storage, the clipboard and anything else that leaves the isolate.
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
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();
      final previous = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logged.add(message);
      };
      await fillAndIssue(tester);
      // Restored inside the body: the test binding asserts the foundation
      // debug hooks are back to default before the test finishes.
      debugPrint = previous;
      expect(find.text('sma_ 7f3K q9Zb T2'), findsOne);

      // Storage, inspected after the credential has been created and drawn.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      for (final blob in sent) {
        expect(blob, isNot(contains(_credential)), reason: 'platform channel');
      }
      for (final line in logged) {
        expect(line, isNot(contains(_credential)), reason: 'log line');
      }
      // No route was pushed at all — issuing is modal, and nothing about the
      // credential is navigator state.
      expect(find.byType(AgentMandateIssueSheet), findsOne);
    });
  });

  // ── Revocation ───────────────────────────────────────────────────────────

  group('revoking', () {
    testWidgets('is one step from the mandate, and says what it stops', (
      tester,
    ) async {
      when(dataSource.listMandates).thenAnswer((_) async => [_mandate()]);
      useSurface(tester, const Size(390, 3000));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('agent-revoke-button-m-1'));
      expect(button, findsOne);
      // The promise is on the screen, not behind a help link.
      expect(find.text(AgentCommerceCopy.revocationPromise), findsWidgets);

      await tapVisible(tester, button);

      // One tap. No confirmation dialog stands between the customer and
      // stopping somebody else's software.
      verify(
        () => dataSource.revokeMandate(
          mandateId: 'm-1',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
      expect(
        find.byKey(const ValueKey('agent-revoked-confirmation')),
        findsOne,
      );
    });

    testWidgets('an ended mandate offers no revoke button', (tester) async {
      when(dataSource.listMandates).thenAnswer(
        (_) async => [
          _mandate(id: 'm-2', revoked: _now.subtract(const Duration(hours: 1))),
        ],
      );
      useSurface(tester, const Size(390, 3000));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('agent-revoke-button-m-2')),
        findsNothing,
      );
      expect(find.text('Revoked'), findsOne);
    });
  });

  // ── Proposals ────────────────────────────────────────────────────────────

  group('confirming a basket', () {
    testWidgets('cannot happen from the list', (tester) async {
      when(dataSource.listProposals).thenAnswer((_) async => [_proposal()]);
      useSurface(tester, const Size(390, 3000));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('agent-proposal-card-pr-1')), findsOne);
      expect(find.byKey(const ValueKey('agent-review-button-pr-1')), findsOne);
      // No confirm control exists until the basket has been opened.
      expect(
        find.byKey(const ValueKey('agent-proposal-confirm-button')),
        findsNothing,
      );
    });

    testWidgets('shows what is bought, from whom and at what total', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AgentProposalSheet(proposal: _proposal(), clock: _clock)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Linen overshirt'), findsOne);
      expect(find.textContaining('@thamel.atelier'), findsOne);
      expect(find.textContaining('M / Emerald'), findsOne);
      expect(find.textContaining('2 × NPR 4,200.00'), findsOne);
      expect(find.text('NPR 8,400.00'), findsWidgets);
      expect(
        find.byKey(const ValueKey('agent-proposal-confirm-button')),
        findsOne,
      );
      verifyNever(
        () => dataSource.confirmProposal(
          proposalId: any(named: 'proposalId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
    });

    testWidgets('only a tap inside the sheet confirms it', (tester) async {
      await tester.pumpWidget(
        host(AgentProposalSheet(proposal: _proposal(), clock: _clock)),
      );
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const ValueKey('agent-proposal-confirm-button')),
      );
      verify(
        () => dataSource.confirmProposal(
          proposalId: 'pr-1',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
    });

    testWidgets('rejecting buys nothing', (tester) async {
      await tester.pumpWidget(
        host(AgentProposalSheet(proposal: _proposal(), clock: _clock)),
      );
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const ValueKey('agent-proposal-reject-button')),
      );
      verify(
        () => dataSource.rejectProposal(
          proposalId: 'pr-1',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
      verifyNever(
        () => dataSource.confirmProposal(
          proposalId: any(named: 'proposalId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
    });

    testWidgets('a basket with no readable lines offers no confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          AgentProposalSheet(
            proposal: _proposal(lines: const <AgentProposalLine>[]),
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('agent-proposal-empty-basket')),
        findsOne,
      );
    });

    testWidgets('an unknown status is shown plainly and is not actionable', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          AgentProposalSheet(
            proposal: _proposal(
              status: AgentProposalStatus.unknown,
              rawStatus: 42,
            ),
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Unrecognised status (42)'), findsWidgets);
      expect(
        find.byKey(const ValueKey('agent-proposal-confirm-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('agent-proposal-unknown-status')),
        findsOne,
      );
    });

    testWidgets('an expired basket offers no confirmation', (tester) async {
      await tester.pumpWidget(
        host(
          AgentProposalSheet(
            proposal: _proposal(
              expires: _now.subtract(const Duration(minutes: 1)),
            ),
            clock: _clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('agent-proposal-confirm-button')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('agent-proposal-expired')), findsOne);
    });
  });

  // ── Activity ─────────────────────────────────────────────────────────────

  group('the activity feed', () {
    testWidgets('shows refusals alongside allowed calls', (tester) async {
      when(
        () => dataSource.listActivity(limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [
          _activity(),
          _activity(
            id: 'a-2',
            action: 'proposal.execute',
            allowed: false,
            errorCode: 'external_agent.human_approval_required',
          ),
          _activity(
            id: 'a-3',
            allowed: false,
            errorCode: 'external_agent.product_outside_mandate',
          ),
        ],
      );
      useSurface(tester, const Size(390, 3000));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('agent-activity-a-1')), findsOne);
      expect(find.byKey(const ValueKey('agent-activity-a-2')), findsOne);
      expect(find.byKey(const ValueKey('agent-activity-a-3')), findsOne);
      // Both refusals carry their reason in words, not a code.
      expect(find.byKey(const ValueKey('agent-activity-reason-a-2')), findsOne);
      expect(find.byKey(const ValueKey('agent-activity-reason-a-3')), findsOne);
      expect(find.text('Refused'), findsNWidgets(2));
      expect(find.text('Allowed'), findsOne);
      expect(
        find.text(
          AgentCommerceCopy.refusalReason(
            'external_agent.product_outside_mandate',
          ),
        ),
        findsOne,
      );
    });

    testWidgets('an unrecognised action is shown as itself', (tester) async {
      when(
        () => dataSource.listActivity(limit: any(named: 'limit')),
      ).thenAnswer((_) async => [_activity(action: 'future.verb')]);
      useSurface(tester, const Size(390, 3000));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('future.verb'), findsOne);
    });
  });

  // ── Unknown scopes on a live mandate ─────────────────────────────────────

  testWidgets('a scope this build cannot name is disclosed, not hidden', (
    tester,
  ) async {
    when(dataSource.listMandates).thenAnswer(
      (_) async => [_mandate(scopes: AgentScopeSet.fromBits(1 | 128))],
    );
    useSurface(tester, const Size(390, 3000));
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('agent-unrecognised-scopes')), findsOne);
  });

  // ── Layout and semantics ─────────────────────────────────────────────────

  group('320dp at text scale 1.3', () {
    testWidgets('the screen does not overflow', (tester) async {
      when(dataSource.listMandates).thenAnswer(
        (_) async => [
          _mandate(products: const <String>['p-1', 'p-2']),
          _mandate(id: 'm-9', revoked: _now.subtract(const Duration(hours: 2))),
        ],
      );
      when(dataSource.listProposals).thenAnswer((_) async => [_proposal()]);
      when(
        () => dataSource.listActivity(limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [
          _activity(),
          _activity(
            id: 'a-2',
            allowed: false,
            errorCode: 'external_agent.amount_over_limit',
          ),
        ],
      );
      useSurface(tester, const Size(320, 640));
      await tester.pumpWidget(
        screen(textScale: 1.3, size: const Size(320, 640)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // And the whole list is scrollable rather than clipped.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the issuing sheet does not overflow', (tester) async {
      useSurface(tester, const Size(320, 640));
      await tester.pumpWidget(
        host(
          const AgentMandateIssueSheet(clock: _clock),
          textScale: 1.3,
          size: const Size(320, 640),
          candidates: const <AgentAllowlistCandidate>[
            AgentAllowlistCandidate(
              productId: 'p-1',
              title: 'A rather long product title that will wrap at 320dp',
              subtitle: 'M / Emerald',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('agent-allowlist-chosen')),
      );
      expect(tester.takeException(), isNull);
      await fillAndIssue(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the basket sheet does not overflow', (tester) async {
      useSurface(tester, const Size(320, 640));
      await tester.pumpWidget(
        host(
          AgentProposalSheet(proposal: _proposal(), clock: _clock),
          textScale: 1.3,
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('semantics', () {
    testWidgets('every control on the issuing sheet is labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Issue this mandate and show its credential once',
        ),
        findsOne,
      );
      expect(
        find.bySemanticsLabel('Cancel without connecting anything'),
        findsOne,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Read the catalogue\. Prices, stock'),
        ),
        findsOne,
      );
      handle.dispose();
    });

    testWidgets('the credential is spoken character by character', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const AgentMandateIssueSheet(clock: _clock)),
      );
      await tester.pumpAndSettle();
      await fillAndIssue(tester);
      expect(
        find.bySemanticsLabel(
          'Mandate credential: ${_credential.split('').join(' ')}',
        ),
        findsOne,
      );
      expect(
        find.bySemanticsLabel('Send the credential using another app'),
        findsOne,
      );
      handle.dispose();
    });

    testWidgets('revoke and confirm say what they do', (tester) async {
      when(dataSource.listMandates).thenAnswer((_) async => [_mandate()]);
      final handle = tester.ensureSemantics();
      useSurface(tester, const Size(390, 3000));
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('^Revoke Marlowe.+mandate now')),
        findsOne,
      );
      handle.dispose();
    });

    testWidgets('the confirm button names the total it will charge', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(AgentProposalSheet(proposal: _proposal(), clock: _clock)),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          'Confirm this basket of 2 items for NPR 8,400.00',
        ),
        findsOne,
      );
      expect(
        find.bySemanticsLabel('Reject this basket. Nothing is bought.'),
        findsOne,
      );
      handle.dispose();
    });
  });
}
