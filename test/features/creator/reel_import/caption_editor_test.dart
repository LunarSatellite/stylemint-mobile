import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/caption_editor.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/caption_standard_sheet.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/reel_caption/reel_caption.dart';

const _aeroPods = CaptionProduct(
  name: 'AeroPods Air',
  price: Money(amount: 8999, currency: 'NPR'),
);

Future<List<ReelCaptionDraft>> _pumpEditor(
  WidgetTester tester,
  ReelCaptionDraft draft,
) async {
  final changes = <ReelCaptionDraft>[];
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CaptionEditor(initialDraft: draft, onChanged: changes.add),
        ),
      ),
    ),
  );
  return changes;
}

String _preview(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find.descendant(
      of: find.byKey(CaptionEditor.previewKey),
      matching: find.byType(RichText),
    ),
  );
  return rich.text.toPlainText();
}

void main() {
  testWidgets('pre-fills from the platform caption and shows the exact hint '
      'when the hook is empty', (tester) async {
    await _pumpEditor(
      tester,
      ReelCaptionDraft.fromPlatformCaption(
        'Wow #Earbuds #AIgenerated',
        products: const [_aeroPods],
      ),
    );

    expect(find.text('Write a hook (20–70 characters)'), findsOneWidget);
    expect(find.text('#Earbuds'), findsOneWidget);
    final aiSwitch = tester.widget<SwitchListTile>(
      find.byKey(CaptionEditor.aiSwitchKey),
    );
    expect(aiSwitch.value, isTrue);
    expect(find.textContaining('Add a hook'), findsOneWidget);
  });

  testWidgets('typing a hook updates the preview and unblocks submit', (
    tester,
  ) async {
    final changes = await _pumpEditor(
      tester,
      const ReelCaptionDraft(
        hook: '',
        products: [_aeroPods],
        aiGenerated: false,
      ),
    );

    await tester.enterText(
      find.byKey(CaptionEditor.hookFieldKey),
      'Wireless sound that fits your daily commute',
    );
    await tester.pump();

    expect(changes.last.canSubmit, isTrue);
    expect(
      _preview(tester),
      'Wireless sound that fits your daily commute\n'
      'AeroPods Air · Rs 8,999\n'
      'Tap the product to shop on StyleMint.\n\n'
      '#StyleMint',
    );
    expect(find.textContaining('Add a hook'), findsNothing);
  });

  testWidgets('adds up to three topic tags, then hides the tag input', (
    tester,
  ) async {
    final changes = await _pumpEditor(
      tester,
      const ReelCaptionDraft(
        hook: 'Wireless sound that fits your daily commute',
        products: [_aeroPods],
        aiGenerated: false,
      ),
    );

    for (final tag in ['Earbuds', '#tech deals', 'earbuds', 'Music']) {
      await tester.enterText(find.byKey(CaptionEditor.tagFieldKey), tag);
      await tester.tap(find.text(CaptionEditor.addTagLabel));
      await tester.pump();
    }

    expect(changes.last.topicTags, ['Earbuds', 'techdeals', 'Music']);
    expect(find.byKey(CaptionEditor.tagFieldKey), findsNothing);
    expect(_preview(tester), endsWith('#StyleMint #Earbuds #techdeals #Music'));

    await tester.tap(find.byKey(const ValueKey('caption_editor_remove_tag_Music')));
    await tester.pump();

    expect(changes.last.topicTags, ['Earbuds', 'techdeals']);
    expect(find.byKey(CaptionEditor.tagFieldKey), findsOneWidget);
  });

  testWidgets('AI switch adds #AIgenerated to the preview', (tester) async {
    final changes = await _pumpEditor(
      tester,
      const ReelCaptionDraft(
        hook: 'Wireless sound that fits your daily commute',
        products: [],
        aiGenerated: false,
      ),
    );

    await tester.tap(find.text(CaptionEditor.aiSwitchLabel));
    await tester.pump();

    expect(changes.last.aiGenerated, isTrue);
    expect(_preview(tester), endsWith('#StyleMint #AIgenerated'));
  });

  testWidgets('info icon opens the caption standard sheet', (tester) async {
    await _pumpEditor(
      tester,
      const ReelCaptionDraft(hook: '', products: [], aiGenerated: false),
    );

    await tester.tap(find.byKey(CaptionEditor.infoButtonKey));
    await tester.pumpAndSettle();

    expect(find.text(CaptionStandardSheet.title), findsOneWidget);
    expect(find.text(CaptionStandardSheet.closeLabel), findsOneWidget);
  });
}
