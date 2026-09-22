import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_sound_button.dart';

/// SM-016 (22 Sep TestFlight QA): a TikTok reel played with no audio and no
/// sound control anywhere on the player, so the viewer could neither tell it
/// was muted nor do anything about it.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool muted,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReelSoundButton(muted: muted, onTap: onTap ?? () {}),
      ),
    ),
  );

  testWidgets('shows the muted state, and says so to a screen reader', (
    tester,
  ) async {
    await pump(tester, muted: true);

    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.bySemanticsLabel('Turn sound on'), findsOneWidget);
  });

  // The old control rendered only while muted, which is why a reel playing
  // quietly showed nothing at all. Both states must be visible.
  testWidgets('stays on screen when sound is on, showing the other state', (
    tester,
  ) async {
    await pump(tester, muted: false);

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
    expect(find.bySemanticsLabel('Turn sound off'), findsOneWidget);
  });

  testWidgets('a tap reports the toggle', (tester) async {
    var taps = 0;
    await pump(tester, muted: true, onTap: () => taps++);

    await tester.tap(find.byKey(const Key('reel_sound_button')));
    await tester.pump();

    expect(taps, 1);
  });
}
