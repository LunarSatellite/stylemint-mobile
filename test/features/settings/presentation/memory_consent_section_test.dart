import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/storefront_personalizer.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/widgets/memory_consent_section.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class _MockRepository extends Mock implements MemoryVaultRepository {}

class _MockPersonalizer extends Mock implements StorefrontPersonalizer {}

MemoryConsent _consent(
  MemoryPurpose purpose, {
  bool permitted = false,
  ConsentBasis basis = ConsentBasis.none,
  String reason = 'consent.undecided',
  bool needsDecision = true,
}) => MemoryConsent(
  purpose: purpose,
  purposeCode: purpose.wireValue,
  permitted: permitted,
  basis: basis,
  reason: reason,
  needsDecision: needsDecision,
);

MemoryConsent _granted(MemoryPurpose purpose) => _consent(
  purpose,
  permitted: true,
  basis: ConsentBasis.purposeGrant,
  reason: 'consent.granted',
  needsDecision: false,
);

MemoryConsent _refused(MemoryPurpose purpose) =>
    _consent(purpose, reason: 'consent.revoked', needsDecision: false);

MemoryConsent _legacy(MemoryPurpose purpose) => _consent(
  purpose,
  permitted: true,
  basis: ConsentBasis.legacyGlobalPause,
  reason: 'consent.legacy_pause_basis',
);

void main() {
  late _MockRepository repository;
  late _MockPersonalizer personalizer;

  setUpAll(() {
    registerFallbackValue(MemoryPurpose.companionRecall);
  });

  setUp(() {
    repository = _MockRepository();
    personalizer = _MockPersonalizer();
    when(() => repository.load()).thenAnswer(
      (_) async => right(const MemoryVault(paused: false, memories: [])),
    );
    when(
      () => repository.grantConsent(
        purpose: any(named: 'purpose'),
        explanation: any(named: 'explanation'),
      ),
    ).thenAnswer((_) async => right(unit));
    when(
      () => repository.revokeConsent(any()),
    ).thenAnswer((_) async => right(unit));
    when(
      () => repository.loadConsents(),
    ).thenAnswer((_) async => right(const []));
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    required MemoryVault vault,
    Size size = const Size(390, 4000),
    double textScale = 1,
  }) async {
    // A real render view, not just a MediaQuery: the section is long and
    // every control has to be reachable for a tap to land on it.
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memoryVaultRepositoryProvider.overrideWithValue(repository),
          storefrontPersonalizerProvider.overrideWithValue(personalizer),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              backgroundColor: DesignTokens.bgAppFoundation,
              body: SingleChildScrollView(
                child: MemoryConsentSection(vault: vault, busy: false),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  MemoryVault vaultWith(List<MemoryConsent> consents, {bool paused = false}) =>
      MemoryVault(paused: paused, memories: const [], consents: consents);

  testWidgets('all four purposes are listed, each with its own words', (
    tester,
  ) async {
    await pumpSection(tester, vault: vaultWith(const []));

    for (final purpose in MemoryPurpose.values) {
      expect(
        find.text(MemoryPurposeCopy.titleOf(purpose)),
        findsOneWidget,
        reason: '${purpose.name} must be present as its own decision',
      );
      expect(
        find.text(MemoryPurposeCopy.explanationOf(purpose)),
        findsOneWidget,
        reason: 'the text being agreed to must be on screen beside the '
            'choice, not folded away',
      );
    }
  });

  testWidgets('the words on screen are the words that get submitted', (
    tester,
  ) async {
    await pumpSection(tester, vault: vaultWith(const []));

    const purpose = MemoryPurpose.recommendations;
    final shown = tester
        .widget<Text>(
          find.text(MemoryPurposeCopy.explanationOf(purpose)),
        )
        .data!;

    await tester.tap(
      find.bySemanticsLabel('Allow ${MemoryPurposeCopy.spokenNameOf(purpose)}'),
    );
    await tester.pump();

    final captured = verify(
      () => repository.grantConsent(
        purpose: purpose,
        explanation: captureAny(named: 'explanation'),
      ),
    ).captured.single as String;

    expect(captured, shown);
    expect(captured.codeUnits, shown.codeUnits);
  });

  testWidgets('undecided, refused and granted each read differently', (
    tester,
  ) async {
    await pumpSection(
      tester,
      vault: vaultWith([
        _granted(MemoryPurpose.companionRecall),
        _refused(MemoryPurpose.storefrontPersonalisation),
        _consent(MemoryPurpose.recommendations),
      ]),
    );

    expect(find.text('Allowed'), findsOneWidget);
    expect(find.text('Refused'), findsOneWidget);
    expect(find.text('Not answered'), findsNWidgets(2));

    // A word and a glyph, not a colour: each state owns a distinct icon.
    final pills = tester
        .widgetList<MallStatusPill>(find.byType(MallStatusPill))
        .toList();
    final icons = pills.map((pill) => pill.icon).toSet();
    expect(icons, hasLength(3), reason: 'three states, three glyphs');

    expect(
      find.textContaining('Nobody has asked you about this yet'),
      findsNWidgets(2),
    );
    expect(find.textContaining('You said no, so this is off.'), findsOneWidget);
  });

  testWidgets('needsDecision actually asks, in the flow and not over it', (
    tester,
  ) async {
    await pumpSection(
      tester,
      vault: vaultWith([
        _legacy(MemoryPurpose.companionRecall),
        _legacy(MemoryPurpose.storefrontPersonalisation),
        _granted(MemoryPurpose.recommendations),
        _refused(MemoryPurpose.proactiveOutreach),
      ]),
    );

    expect(find.text('We still need your answer'), findsOneWidget);
    expect(find.textContaining('2 of these'), findsOneWidget);
    expect(find.text('Needs your answer'), findsNWidgets(2));

    // Not a wall: nothing is thrown over the screen to collect a yes.
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    for (final purpose in MemoryPurpose.values) {
      expect(find.text(MemoryPurposeCopy.titleOf(purpose)), findsOneWidget);
    }
  });

  testWidgets('a settled screen does not nag', (tester) async {
    await pumpSection(
      tester,
      vault: vaultWith([
        _granted(MemoryPurpose.companionRecall),
        _refused(MemoryPurpose.storefrontPersonalisation),
        _refused(MemoryPurpose.recommendations),
        _granted(MemoryPurpose.proactiveOutreach),
      ]),
    );

    expect(find.text('We still need your answer'), findsNothing);
  });

  testWidgets('nothing is pre-granted and neither answer is weighted', (
    tester,
  ) async {
    await pumpSection(tester, vault: vaultWith(const []));

    expect(find.text('Allowed'), findsNothing);
    // No pre-ticked control of any kind.
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Radio<bool>), findsNothing);
    // The permissive option gets no badge and no extra weight: both
    // answers are the same outlined widget.
    expect(find.text('Recommended'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNWidgets(8));

    final allow = tester.getSize(
      find.ancestor(
        of: find.text('Allow').first,
        matching: find.byType(OutlinedButton),
      ),
    );
    final refuse = tester.getSize(
      find.ancestor(
        of: find.text('Refuse').first,
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(allow.width, refuse.width);
  });

  testWidgets('withdrawing a granted purpose is one visible step', (
    tester,
  ) async {
    await pumpSection(
      tester,
      vault: vaultWith([_granted(MemoryPurpose.proactiveOutreach)]),
    );

    final label =
        'Withdraw '
        '${MemoryPurposeCopy.spokenNameOf(MemoryPurpose.proactiveOutreach)}';
    expect(find.bySemanticsLabel(label), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(label));
    await tester.pump();

    verify(() => repository.revokeConsent(4)).called(1);
    verifyNever(
      () => repository.grantConsent(
        purpose: any(named: 'purpose'),
        explanation: any(named: 'explanation'),
      ),
    );
  });

  testWidgets('the global pause visibly overrides all four', (tester) async {
    await pumpSection(
      tester,
      vault: vaultWith([
        _granted(MemoryPurpose.companionRecall),
        _granted(MemoryPurpose.storefrontPersonalisation),
      ], paused: true),
    );

    expect(find.text('Paused'), findsNWidgets(4));
    expect(find.text('Allowed'), findsNothing);
    expect(
      find.textContaining('none of these four run'),
      findsOneWidget,
      reason: 'the relationship is stated once, not implied',
    );
    // No Allow while paused: it would be a control that does nothing next
    // to the switch that overrules it.
    expect(find.text('Allow'), findsNothing);
    expect(
      find.textContaining('Switch remembering back on above'),
      findsNWidgets(4),
    );
    // Withdrawing still works, and is still one tap.
    expect(find.text('Withdraw'), findsNWidgets(4));
    // And the pending prompt does not shout over a pause.
    expect(find.text('We still need your answer'), findsNothing);
  });

  testWidgets('a purpose this build cannot name degrades gracefully', (
    tester,
  ) async {
    await pumpSection(
      tester,
      vault: vaultWith(const [
        MemoryConsent(
          purposeCode: 99,
          permitted: false,
          basis: ConsentBasis.none,
          reason: 'consent.undecided',
          needsDecision: true,
        ),
      ]),
    );

    expect(find.text('A newer use of your memory'), findsOneWidget);
    expect(
      find.textContaining('does not recognise this use yet'),
      findsOneWidget,
    );
    // It can be refused, but not agreed to: an unexplained yes is not
    // consent.
    final refuse = find.bySemanticsLabel(
      'Refuse this newer use of your memory',
    );
    expect(refuse, findsOneWidget);
    expect(
      find.bySemanticsLabel('Allow this newer use of your memory'),
      findsNothing,
    );

    await tester.tap(refuse);
    await tester.pump();
    verify(() => repository.revokeConsent(99)).called(1);
  });

  testWidgets('every control carries a label and a tap action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpSection(
      tester,
      vault: vaultWith([
        _granted(MemoryPurpose.companionRecall),
        _refused(MemoryPurpose.storefrontPersonalisation),
        _legacy(MemoryPurpose.recommendations),
      ]),
    );

    String control(String verb, MemoryPurpose purpose) =>
        '$verb ${MemoryPurposeCopy.spokenNameOf(purpose)}';

    final labels = <String>[
      control('Withdraw', MemoryPurpose.companionRecall),
      control('Allow', MemoryPurpose.storefrontPersonalisation),
      control('Allow', MemoryPurpose.recommendations),
      control('Refuse', MemoryPurpose.recommendations),
      control('Allow', MemoryPurpose.proactiveOutreach),
      control('Refuse', MemoryPurpose.proactiveOutreach),
    ];

    for (final label in labels) {
      final finder = find.bySemanticsLabel(label);
      expect(finder, findsOneWidget, reason: '"$label" must be spoken');
      expect(
        tester.getSemantics(finder),
        isSemantics(label: label, isButton: true, hasTapAction: true),
        reason: '"$label" must be operable, not just readable',
      );
    }

    // The state of each purpose is spoken too, not left to colour.
    expect(
      find.bySemanticsLabel(
        '${MemoryPurposeCopy.titleOf(MemoryPurpose.companionRecall)}: Allowed',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('no overflow at 320dp and 1.3x text', (tester) async {
    tester.view.physicalSize = const Size(320, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpSection(
      tester,
      vault: vaultWith([
        _legacy(MemoryPurpose.companionRecall),
        _granted(MemoryPurpose.storefrontPersonalisation),
        _refused(MemoryPurpose.recommendations),
      ]),
      size: const Size(320, 3600),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow at 320dp and 1.3x while paused', (tester) async {
    tester.view.physicalSize = const Size(320, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpSection(
      tester,
      vault: vaultWith([_granted(MemoryPurpose.companionRecall)], paused: true),
      size: const Size(320, 3600),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a storefront decision clears the Mall cached answer', (
    tester,
  ) async {
    await pumpSection(tester, vault: vaultWith(const []));

    const purpose = MemoryPurpose.storefrontPersonalisation;
    await tester.tap(
      find.bySemanticsLabel(
        'Allow ${MemoryPurposeCopy.spokenNameOf(purpose)}',
      ),
    );
    await tester.pump();

    verify(() => personalizer.forgetConsent()).called(1);
  });
}
