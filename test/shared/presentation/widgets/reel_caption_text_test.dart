import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_caption_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

const _standard =
    'Two weekend essentials I never leave home without\n'
    'Nomad Canvas Tote · Rs 1,800\n'
    'Glow Rituals · Rs 2,500\n'
    'Tap the product to shop on StyleMint.\n'
    '\n'
    '#StyleMint #WeekendStyle #Skincare';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.black,
    body: SizedBox(width: 360, child: child),
  ),
);

/// Flattens every TextSpan rendered under [finder] into (text, style) pairs.
List<TextSpan> _spans(WidgetTester tester) {
  final out = <TextSpan>[];
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) out.add(span);
      return true;
    });
  }
  return out;
}

void main() {
  testWidgets('standard caption collapses to hook + first product + "more"', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const ReelCaptionText(caption: _standard)));

    expect(
      find.textContaining('Two weekend essentials', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Nomad Canvas Tote', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(ReelCaptionText.moreLabel), findsOneWidget);
    expect(
      find.textContaining('Glow Rituals', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('Tap the product', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('tapping expands to every line, CTA and hashtags', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const ReelCaptionText(caption: _standard)));

    await tester.tap(find.byType(ReelCaptionText));
    await tester.pump();

    expect(find.text(ReelCaptionText.moreLabel), findsNothing);
    expect(
      find.textContaining('Glow Rituals', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Tap the product to shop on StyleMint.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('#StyleMint #WeekendStyle', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('prices and hashtags use the brand green, hook is bold white', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ReelCaptionText(caption: _standard, expandable: false)),
    );

    final spans = _spans(tester);
    final price = spans.firstWhere((s) => s.text == 'Rs 1,800');
    final hook = spans.firstWhere(
      (s) => s.text == 'Two weekend essentials I never leave home without',
    );
    final cta = spans.firstWhere(
      (s) => s.text == 'Tap the product to shop on StyleMint.',
    );
    final tag = spans.firstWhere((s) => s.text == '#Skincare');

    expect(price.style?.color, DesignTokens.primaryGreen);
    expect(tag.style?.color, DesignTokens.primaryGreen);
    expect(hook.style?.color, DesignTokens.textWhite);
    expect(hook.style?.fontWeight, FontWeight.w700);
    expect(cta.style?.color, DesignTokens.textMuted);
  });

  testWidgets('non-standard caption renders plain text with hashtags '
      'highlighted and no "more" when it fits', (tester) async {
    await tester.pumpWidget(
      _host(
        const ReelCaptionText(caption: 'Cake day with friends #cake #NewYear'),
      ),
    );

    expect(find.text(ReelCaptionText.moreLabel), findsNothing);
    final spans = _spans(tester);
    expect(spans.firstWhere((s) => s.text == '#cake').style?.color,
        DesignTokens.primaryGreen);
    expect(
      spans.firstWhere((s) => s.text == 'Cake day with friends ').style,
      isNull,
      reason: 'plain text inherits the base style from the parent span',
    );
  });

  testWidgets('long non-standard caption shows "more" and expands on tap', (
    tester,
  ) async {
    final long = List.filled(12, 'A long imported platform caption line.')
        .join('\n');
    await tester.pumpWidget(_host(ReelCaptionText(caption: long)));

    expect(find.text(ReelCaptionText.moreLabel), findsOneWidget);

    await tester.tap(find.byType(ReelCaptionText));
    await tester.pump();

    expect(find.text(ReelCaptionText.moreLabel), findsNothing);
  });

  testWidgets('empty caption renders the placeholder or nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            ReelCaptionText(caption: '  ', emptyText: 'No caption on this post'),
            ReelCaptionText(caption: null),
          ],
        ),
      ),
    );

    expect(find.text('No caption on this post'), findsOneWidget);
  });
}
