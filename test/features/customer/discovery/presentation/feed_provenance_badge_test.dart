import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/feed_provenance.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/feed_provenance_badge.dart';

/// Phrasings that would turn generic content into a personalisation claim.
const List<String> _personalPhrases = [
  'for you',
  'your',
  'based on',
  'we thought',
  'picked for',
  'because you',
  'recommended',
  'suggested for',
  'match',
];

Widget _host(
  FeedProvenance provenance, {
  double width = 320,
  double textScale = 1,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      size: Size(width, 640),
      textScaler: TextScaler.linear(textScale),
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        child: FeedProvenanceBadge(provenance: provenance),
      ),
    ),
  ),
);

Iterable<String> _renderedText(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '');

void main() {
  testWidgets('a null score renders no rank at all', (tester) async {
    await tester.pumpWidget(
      _host(const FeedProvenance(kind: FeedSlotKind.newIn)),
    );

    expect(find.byKey(FeedProvenanceBadge.rankKey), findsNothing);
    final text = _renderedText(tester).join(' ');
    expect(text, contains('New in'));
    // Not a zero, not a dash, not a bottom rank.
    expect(text, isNot(contains('0')));
    expect(text, isNot(contains('#')));
    expect(text, isNot(contains('—')));
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a real score renders its rank', (tester) async {
    await tester.pumpWidget(
      _host(
        const FeedProvenance(
          kind: FeedSlotKind.popular,
          score: 12.5,
          rank: 2,
        ),
      ),
    );

    expect(find.byKey(FeedProvenanceBadge.rankKey), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    // The raw figure is never shown: it means different things per source.
    expect(_renderedText(tester).join(' '), isNot(contains('12.5')));
  });

  testWidgets('Popular and New in read as generic, never personal', (
    tester,
  ) async {
    for (final kind in [FeedSlotKind.popular, FeedSlotKind.newIn]) {
      await tester.pumpWidget(_host(FeedProvenance(kind: kind)));
      final handle = tester.ensureSemantics();

      final rendered = _renderedText(tester).join(' ').toLowerCase();
      expect(rendered, isNotEmpty);
      for (final phrase in _personalPhrases) {
        expect(
          rendered,
          isNot(contains(phrase)),
          reason: '${kind.name} must not imply personalisation',
        );
      }
      expect(find.bySemanticsLabel(kind.spokenLabel), findsOneWidget);
      handle.dispose();
    }

    await tester.pumpWidget(
      _host(const FeedProvenance(kind: FeedSlotKind.popular)),
    );
    expect(find.text('Popular right now'), findsOneWidget);

    await tester.pumpWidget(
      _host(const FeedProvenance(kind: FeedSlotKind.newIn)),
    );
    expect(find.text('New in'), findsOneWidget);
  });

  testWidgets('an unknown slot kind degrades conservatively', (tester) async {
    // Whatever the server adds next arrives here.
    final provenance = FeedProvenance(
      kind: FeedSlotKind.parse('SomethingTheServerAddedLater'),
    );
    expect(provenance.kind, FeedSlotKind.unknown);

    await tester.pumpWidget(_host(provenance));
    final handle = tester.ensureSemantics();

    final rendered = _renderedText(tester).join(' ').toLowerCase();
    for (final phrase in _personalPhrases) {
      expect(rendered, isNot(contains(phrase)));
    }
    // It does not borrow a claim it cannot support either.
    expect(rendered, isNot(contains('popular')));
    expect(rendered, isNot(contains('new in')));
    expect(find.text('From the Mall'), findsOneWidget);
    expect(find.byKey(FeedProvenanceBadge.rankKey), findsNothing);
    expect(
      FeedProvenanceBadge.iconFor(FeedSlotKind.unknown),
      isNot(FeedProvenanceBadge.iconFor(FeedSlotKind.personalized)),
    );
    handle.dispose();
  });

  testWidgets('state is carried by glyph and word, not colour alone', (
    tester,
  ) async {
    for (final kind in FeedSlotKind.values) {
      await tester.pumpWidget(_host(FeedProvenance(kind: kind)));
      expect(find.text(kind.label), findsOneWidget);
      expect(
        find.byIcon(FeedProvenanceBadge.iconFor(kind)),
        findsOneWidget,
        reason: '${kind.name} must draw its own glyph',
      );
    }
  });

  testWidgets('every chip is spoken', (tester) async {
    await tester.pumpWidget(
      _host(
        const FeedProvenance(
          kind: FeedSlotKind.personalized,
          score: 0.9,
          rank: 1,
        ),
      ),
    );
    final handle = tester.ensureSemantics();

    expect(
      find.bySemanticsLabel(FeedSlotKind.personalized.spokenLabel),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp('Ranked number 1', caseSensitive: false),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final kind in FeedSlotKind.values) {
      await tester.pumpWidget(
        _host(
          FeedProvenance(kind: kind, score: 9, rank: 12),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: kind.name);
    }
  });
}
