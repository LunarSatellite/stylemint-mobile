import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/screens/assistant_conversation_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/widgets/assistant_suggestion_shelf.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/widgets/assistant_turn_bubble.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/shared/providers.dart';

import 'assistant_fixtures.dart';

/// A phone that is small and set large: the combination that overflows.
const _narrow = Size(320, 640);
const _bigText = TextScaler.linear(1.3);

Future<void> _pumpThread(
  WidgetTester tester,
  FakeAssistantRepository repository, {
  Size size = const Size(390, 844),
  TextScaler scaler = TextScaler.noScaling,
  List<int>? cartCounts,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assistantRepositoryProvider.overrideWithValue(repository),
        // Stands the cart stack down; the count is recorded instead.
        assistantCartSyncProvider.overrideWithValue(
          (count) => cartCounts?.add(count),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: scaler),
          child: const AssistantConversationScreen(conversationId: 'conv-1'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders turns oldest-first with each role distinguished', (
    tester,
  ) async {
    final repository = FakeAssistantRepository(
      turns: [
        turnFrom(id: 'u-1', role: 'user', message: 'I need a winter coat'),
        turnFrom(
          id: 'm-1',
          role: 'minty',
          message: 'Try this field coat',
          suggested: productA,
        ),
        turnFrom(id: 's-1', role: 'system', message: 'Added to your bag.'),
      ],
      resolved: {productA: 'Field coat'},
    );

    await _pumpThread(tester, repository);

    expect(find.text('I need a winter coat'), findsOneWidget);
    expect(find.text('Try this field coat'), findsOneWidget);

    // Role is carried by a named speaker, not by colour alone.
    expect(find.text('YOU'), findsOneWidget);
    expect(find.text('MINTY'), findsOneWidget);
    expect(find.text('Added to your bag.'), findsOneWidget);

    // Oldest first: the customer's message sits above Minty's reply.
    final user = tester.getTopLeft(
      find.byKey(AssistantTurnBubble.keyFor('u-1')),
    );
    final minty = tester.getTopLeft(
      find.byKey(AssistantTurnBubble.keyFor('m-1')),
    );
    expect(user.dy, lessThan(minty.dy));
  });

  testWidgets('sending a message appends the customer turn and the reply', (
    tester,
  ) async {
    final repository = FakeAssistantRepository(
      turns: [turnFrom(id: 'm-0', role: 'minty', message: 'Hello.')],
    );

    await _pumpThread(tester, repository);

    await tester.enterText(
      find.byKey(AssistantConversationScreen.composerKey),
      'Something for a wedding',
    );
    await tester.tap(find.byKey(AssistantConversationScreen.sendKey));
    await tester.pumpAndSettle();

    expect(repository.sentMessages, ['Something for a wedding']);
    expect(find.text('Something for a wedding'), findsOneWidget);
    expect(find.text('Here is an idea.'), findsOneWidget);
  });

  testWidgets('only a suggested product gets an add control, and only '
      'under the turn that suggested it', (tester) async {
    final repository = FakeAssistantRepository(
      turns: [
        // A user turn that (impossibly) came back carrying an id.
        turnFrom(
          id: 'u-1',
          role: 'user',
          message: 'that one',
          suggested: productB,
        ),
        turnFrom(
          id: 'm-1',
          role: 'minty',
          message: 'This one',
          suggested: productA,
        ),
      ],
      resolved: {productA: 'Field coat', productB: 'Rain shell'},
    );

    await _pumpThread(tester, repository);

    expect(
      find.byKey(AssistantSuggestionShelf.addKey(productA)),
      findsOneWidget,
    );
    expect(
      find.byKey(AssistantSuggestionShelf.addKey(productB)),
      findsNothing,
      reason: 'the customer cannot approve their own turn',
    );
    expect(find.byKey(AssistantSuggestionShelf.shelfKey), findsOneWidget);
  });

  testWidgets('nothing is added until the customer presses the control', (
    tester,
  ) async {
    final counts = <int>[];
    final repository = FakeAssistantRepository(
      turns: [
        turnFrom(
          id: 'm-1',
          role: 'minty',
          message: 'This one',
          suggested: productA,
        ),
      ],
      resolved: {productA: 'Field coat'},
    );

    await _pumpThread(tester, repository, cartCounts: counts);

    // Rendering, settling and scrolling have all happened by now.
    await tester.drag(
      find.byKey(AssistantConversationScreen.listKey),
      const Offset(0, -40),
    );
    await tester.pumpAndSettle();
    expect(repository.addCalls, isEmpty);

    await tester.tap(find.byKey(AssistantSuggestionShelf.addKey(productA)));
    await tester.pumpAndSettle();

    expect(repository.addCalls, hasLength(1));
    expect(repository.addCalls.single.turnId, 'm-1');
    expect(repository.addCalls.single.productId, productA);
    expect(
      counts,
      [3],
      reason: 'the cart count the API returned reaches the badge',
    );
    expect(find.text('In your bag'), findsOneWidget);
  });

  testWidgets('a second press cannot add the same suggestion twice', (
    tester,
  ) async {
    final repository = FakeAssistantRepository(
      turns: [
        turnFrom(
          id: 'm-1',
          role: 'minty',
          message: 'This one',
          suggested: productA,
        ),
      ],
      resolved: {productA: 'Field coat'},
    );

    await _pumpThread(tester, repository);

    await tester.tap(find.byKey(AssistantSuggestionShelf.addKey(productA)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(AssistantSuggestionShelf.addKey(productA)),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(repository.addCalls, hasLength(1));
  });

  testWidgets('a retry after a failure reuses the idempotency key', (
    tester,
  ) async {
    final repository = FakeAssistantRepository(
      turns: [
        turnFrom(
          id: 'm-1',
          role: 'minty',
          message: 'This one',
          suggested: productA,
        ),
      ],
      resolved: {productA: 'Field coat'},
      failAddOnce: true,
    );

    await _pumpThread(tester, repository);

    await tester.tap(find.byKey(AssistantSuggestionShelf.addKey(productA)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AssistantSuggestionShelf.addKey(productA)));
    await tester.pumpAndSettle();

    expect(repository.addCalls, hasLength(2));
    expect(
      repository.addCalls.first.key,
      repository.addCalls.last.key,
      reason: 'one customer decision, one key',
    );
  });

  testWidgets('an unresolvable suggestion is omitted rather than stubbed', (
    tester,
  ) async {
    final repository = FakeAssistantRepository(
      turns: [
        turnFrom(
          id: 'm-1',
          role: 'minty',
          message: 'Two ideas',
          suggested: '$productA,$ghostProduct',
        ),
      ],
      resolved: {productA: 'Field coat'},
    );

    await _pumpThread(tester, repository);

    expect(find.text('Field coat'), findsOneWidget);
    expect(
      find.byKey(AssistantSuggestionShelf.addKey(productA)),
      findsOneWidget,
    );
    expect(
      find.byKey(AssistantSuggestionShelf.addKey(ghostProduct)),
      findsNothing,
    );
  });

  testWidgets('a turn whose suggestions all fail to resolve draws no shelf', (
    tester,
  ) async {
    final repository = FakeAssistantRepository(
      turns: [
        turnFrom(
          id: 'm-1',
          role: 'minty',
          message: 'An idea',
          suggested: ghostProduct,
        ),
      ],
    );

    await _pumpThread(tester, repository);

    expect(find.byKey(AssistantSuggestionShelf.shelfKey), findsNothing);
    expect(find.text('Minty suggested'), findsNothing);
  });

  testWidgets('the cursor control appears only when the API sent one', (
    tester,
  ) async {
    final repository = FakeAssistantRepository(
      turns: [turnFrom(id: 'm-1', role: 'minty', message: 'Hello.')],
    );

    await _pumpThread(tester, repository);

    expect(find.byKey(AssistantConversationScreen.loadMoreKey), findsNothing);
  });

  testWidgets('no overflow at 320dp with text at 1.3x', (tester) async {
    final repository = FakeAssistantRepository(
      turns: [
        turnFrom(
          id: 'u-1',
          role: 'user',
          message:
              'I need something warm enough for a Kathmandu winter '
              'that still works at the office.',
        ),
        turnFrom(
          id: 'm-1',
          role: 'minty',
          message: 'A wool-blend field coat would cover both.',
          suggested: '$productA,$productB',
        ),
        turnFrom(id: 's-1', role: 'system', message: 'Added to your bag.'),
      ],
      resolved: {productA: 'Field coat', productB: 'Merino rollneck'},
    );

    await _pumpThread(
      tester,
      repository,
      size: _narrow,
      scaler: _bigText,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('every control carries a semantics label', (tester) async {
    final repository = FakeAssistantRepository(
      turns: [
        turnFrom(
          id: 'm-1',
          role: 'minty',
          message: 'This one',
          suggested: productA,
        ),
      ],
      resolved: {productA: 'Field coat'},
    );
    final handle = tester.ensureSemantics();

    await _pumpThread(tester, repository);

    expect(find.bySemanticsLabel('Message Minty'), findsOneWidget);
    expect(find.bySemanticsLabel('Send message'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Add Field coat to your bag'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byKey(AssistantTurnBubble.keyFor('m-1'))).label,
      contains('Minty said. This one'),
      reason: 'a screen reader hears who spoke, not a colour',
    );

    handle.dispose();
  });

  test('no code in the assistant feature can reach checkout', () {
    // Structural, not conventional. The promise is that the AI "will not set
    // prices, reserve stock or move money", so the surface that hosts it must
    // have no path to checkout at all — not a disabled one, none.
    final sources = Directory('lib/features/customer/assistant')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(sources, isNotEmpty, reason: 'the feature should have sources');

    for (final file in sources) {
      final text = file.readAsStringSync();
      for (final forbidden in const [
        'RouteNames.checkout',
        'RouteNames.orderSuccess',
        'RouteNames.payment',
        'placeOrder',
      ]) {
        expect(
          text.contains(forbidden),
          isFalse,
          reason: '${file.path} must not reference $forbidden',
        );
      }
    }
  });
}
