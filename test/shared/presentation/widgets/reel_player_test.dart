import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:url_launcher/url_launcher.dart';

class _ExternalReel implements ReelMedia {
  const _ExternalReel();

  @override
  SocialPlatform? get platform => SocialPlatform.tiktok;

  @override
  String get permalink => 'https://www.tiktok.com/@stylemint/video/123';

  @override
  String? get thumbnailUrl => null;

  @override
  String? get videoUrl => 'legacy-provider-metadata';
}

void main() {
  testWidgets(
    'renders an external-provider action instead of an embedded player',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 320,
            height: 560,
            child: ReelPlayer(reel: _ExternalReel(), isActive: true),
          ),
        ),
      );

      expect(find.text('Watch on TikTok'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Open reel on TikTok',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('prefers the native provider handler before browser fallback', (
    tester,
  ) async {
    final modes = <LaunchMode>[];
    final launcher = ReelExternalLauncher(
      launcher: (_, {mode = LaunchMode.platformDefault}) async {
        modes.add(mode);
        return mode == LaunchMode.externalNonBrowserApplication;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 560,
          child: ReelPlayer(
            reel: const _ExternalReel(),
            isActive: true,
            externalLauncher: launcher,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ReelPlayer));
    await tester.pump();

    expect(modes, [LaunchMode.externalNonBrowserApplication]);
  });

  test('falls back to the provider permalink externally', () async {
    final modes = <LaunchMode>[];
    final launcher = ReelExternalLauncher(
      launcher: (_, {mode = LaunchMode.platformDefault}) async {
        modes.add(mode);
        return mode == LaunchMode.externalApplication;
      },
    );

    final opened = await launcher.open(
      Uri.parse('https://www.tiktok.com/@stylemint/video/123'),
    );

    expect(opened, isTrue);
    expect(modes, [
      LaunchMode.externalNonBrowserApplication,
      LaunchMode.externalApplication,
    ]);
  });

  test('never sends a non-web reel pointer to the URL resolver', () async {
    var calls = 0;
    final launcher = ReelExternalLauncher(
      launcher: (_, {mode = LaunchMode.platformDefault}) async {
        calls++;
        return true;
      },
    );

    final opened = await launcher.open(Uri.parse('file:///not-a-reel'));

    expect(opened, isFalse);
    expect(calls, 0);
  });
}
