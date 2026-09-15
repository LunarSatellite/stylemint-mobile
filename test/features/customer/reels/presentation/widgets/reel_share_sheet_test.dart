import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/reel_share_targets.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_share_sheet.dart';

class _FakeLauncher implements ReelShareLauncher {
  _FakeLauncher({
    this.installed = const {'whatsapp'},
    this.opens = true,
    this.appShares = true,
  });

  /// Schemes of the installed apps.
  final Set<String> installed;
  final bool opens;

  /// Whether an app's own share screen opens (the app is installed).
  final bool appShares;
  final List<(String, String)> sharedToApp = [];
  final List<Uri> opened = [];
  final List<String> shared = [];

  @override
  Future<bool> canOpen(Uri uri) async => installed.contains(uri.scheme);

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return opens;
  }

  @override
  Future<bool> shareToApp(String package, String text) async {
    sharedToApp.add((package, text));
    return appShares;
  }

  @override
  Future<void> shareText(String text) async => shared.add(text);
}

void main() {
  final link = Uri.parse('https://stylemint.voyageritnepal.com/reels/reel-1');
  const message =
      "Watch sumendra's reel on StyleMint: "
      'https://stylemint.voyageritnepal.com/reels/reel-1';

  Future<ReelShareOutcome?> Function() open(
    WidgetTester tester,
    _FakeLauncher launcher,
  ) {
    ReelShareOutcome? outcome;
    return () async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => outcome = await showReelShareSheet(
                context,
                link: link,
                message: message,
                launcher: launcher,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return outcome;
    };
  }

  testWidgets('lists Facebook, Messages and More apps; WhatsApp and Viber '
      'only when installed', (tester) async {
    await open(tester, _FakeLauncher())();

    expect(find.text(ReelShareSheet.title), findsOneWidget);
    expect(find.text(link.toString()), findsOneWidget);
    for (final target in [
      ReelShareTarget.whatsApp,
      ReelShareTarget.facebook,
      ReelShareTarget.messages,
    ]) {
      expect(find.byKey(ReelShareSheet.targetKey(target)), findsOneWidget);
    }
    expect(find.byKey(ReelShareSheet.targetKey(ReelShareTarget.viber)),
        findsNothing);
    expect(find.byKey(ReelShareSheet.moreKey), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await open(tester, _FakeLauncher(installed: {'whatsapp', 'viber'}))();
    expect(find.byKey(ReelShareSheet.targetKey(ReelShareTarget.viber)),
        findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await open(tester, _FakeLauncher(installed: const {}))();
    expect(find.byKey(ReelShareSheet.targetKey(ReelShareTarget.whatsApp)),
        findsNothing);
    expect(
      find.byKey(ReelShareSheet.targetKey(ReelShareTarget.facebook)),
      findsOneWidget,
    );
  });

  testWidgets('WhatsApp opens its share link with the StyleMint message', (
    tester,
  ) async {
    final launcher = _FakeLauncher();
    ReelShareOutcome? outcome;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => outcome = await showReelShareSheet(
              context,
              link: link,
              message: message,
              launcher: launcher,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(ReelShareSheet.targetKey(ReelShareTarget.whatsApp)),
    );
    await tester.pumpAndSettle();

    expect(launcher.opened, [
      ReelShareTarget.whatsApp.uri(link: link, message: message),
    ]);
    expect(outcome, ReelShareOutcome.sent);
    expect(find.text(ReelShareSheet.title), findsNothing);
  });

  for (final appInstalled in [true, false]) {
    testWidgets(
      'Facebook shares the link through the Facebook app'
      '${appInstalled ? '' : ', or its web share page without it'}',
      (tester) async {
        final launcher = _FakeLauncher(appShares: appInstalled);
        await open(tester, launcher)();

        await tester.tap(
          find.byKey(ReelShareSheet.targetKey(ReelShareTarget.facebook)),
        );
        await tester.pumpAndSettle();

        expect(launcher.sharedToApp, [
          ('com.facebook.katana', link.toString()),
        ]);
        expect(
          launcher.opened,
          appInstalled
              ? isEmpty
              : [ReelShareTarget.facebook.uri(link: link, message: message)],
        );
        expect(find.text(ReelShareSheet.title), findsNothing);
      },
    );
  }

  testWidgets('an app that will not open reports failed', (tester) async {
    final launcher = _FakeLauncher(opens: false);
    ReelShareOutcome? outcome;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => outcome = await showReelShareSheet(
              context,
              link: link,
              message: message,
              launcher: launcher,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ReelShareSheet.targetKey(ReelShareTarget.messages)),
    );
    await tester.pumpAndSettle();

    expect(outcome, ReelShareOutcome.failed);
  });

  testWidgets('More apps hands the message to the phone share menu', (
    tester,
  ) async {
    final launcher = _FakeLauncher();
    await open(tester, launcher)();

    await tester.tap(find.byKey(ReelShareSheet.moreKey));
    await tester.pumpAndSettle();

    expect(launcher.shared, [message]);
    expect(launcher.opened, isEmpty);
  });

  testWidgets('Copy link copies the StyleMint link', (tester) async {
    final clipboard = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboard.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final launcher = _FakeLauncher();
    ReelShareOutcome? outcome;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => outcome = await showReelShareSheet(
              context,
              link: link,
              message: message,
              launcher: launcher,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ReelShareSheet.copyKey));
    await tester.pumpAndSettle();

    expect(clipboard, [
      {'text': link.toString()},
    ]);
    expect(outcome, ReelShareOutcome.copied);
  });

  testWidgets('closing without choosing reports dismissed', (tester) async {
    final launcher = _FakeLauncher();
    ReelShareOutcome? outcome;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => outcome = await showReelShareSheet(
              context,
              link: link,
              message: message,
              launcher: launcher,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(outcome, ReelShareOutcome.dismissed);
  });
}
