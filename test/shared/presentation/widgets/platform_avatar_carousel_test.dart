import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/platform_avatar_carousel.dart';

/// Resolves synchronously from an in-memory image so precaching completes
/// under fake async. URLs starting with `bad` fail to load.
@immutable
class _FakeAvatarProvider extends ImageProvider<_FakeAvatarProvider> {
  const _FakeAvatarProvider(this.url, this.image);

  final String url;
  final ui.Image image;

  @override
  Future<_FakeAvatarProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FakeAvatarProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _FakeAvatarProvider key,
    ImageDecoderCallback decode,
  ) {
    if (url.startsWith('bad')) {
      return OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(StateError('cannot load $url')),
      );
    }
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _FakeAvatarProvider && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Image testImage;

  setUpAll(() async {
    testImage = await createTestImage();
  });

  tearDownAll(() => testImage.dispose());

  Widget host(
    Widget child, {
    bool disableAnimations = false,
    bool tickersEnabled = true,
  }) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: TickerMode(
          enabled: tickersEnabled,
          child: Center(child: child),
        ),
      ),
    ),
  );

  PlatformAvatarCarousel carousel(List<String> urls, {Widget? fallback}) =>
      PlatformAvatarCarousel(
        imageUrls: urls,
        size: 40,
        fallback: fallback,
        imageProviderBuilder: (url) => _FakeAvatarProvider(url, testImage),
      );

  Finder inCarousel(Finder matching) => find.descendant(
    of: find.byType(PlatformAvatarCarousel),
    matching: matching,
  );

  List<String> shownUrls(WidgetTester tester) => tester
      .widgetList<Image>(inCarousel(find.byType(Image)))
      .map((image) => (image.image as _FakeAvatarProvider).url)
      .toList();

  testWidgets('a single picture stays static', (tester) async {
    await tester.pumpWidget(host(carousel(const ['a'])));
    expect(shownUrls(tester), ['a']);

    await tester.pump(const Duration(seconds: 10));

    expect(shownUrls(tester), ['a']);
    expect(inCarousel(find.byType(Transform)), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('several pictures spin to the next one each interval and loop', (
    tester,
  ) async {
    await tester.pumpWidget(host(carousel(const ['a', 'b', 'c'])));
    expect(shownUrls(tester), ['a']);

    await tester.pump(const Duration(milliseconds: 2400));
    expect(shownUrls(tester), ['a']);
    expect(inCarousel(find.byType(Transform)), findsNothing);

    // Hold ends at 2.5 s and the spin starts.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 150));
    expect(inCarousel(find.byType(Transform)), findsOneWidget);
    expect(shownUrls(tester), ['a']);

    await tester.pump(const Duration(milliseconds: 500));
    expect(inCarousel(find.byType(Transform)), findsNothing);
    expect(shownUrls(tester), ['b']);

    for (final expected in ['c', 'a']) {
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 700));
      expect(shownUrls(tester), [expected]);
    }

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion cross-fades instead of spinning', (tester) async {
    await tester.pumpWidget(
      host(carousel(const ['a', 'b']), disableAnimations: true),
    );

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 150));
    expect(inCarousel(find.byType(Transform)), findsNothing);
    expect(inCarousel(find.byType(Opacity)), findsNWidgets(2));
    expect(shownUrls(tester), ['a', 'b']);

    await tester.pump(const Duration(milliseconds: 200));
    expect(shownUrls(tester), ['b']);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('does not rotate while tickers are muted', (tester) async {
    await tester.pumpWidget(
      host(carousel(const ['a', 'b']), tickersEnabled: false),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(shownUrls(tester), ['a']);

    await tester.pumpWidget(host(carousel(const ['a', 'b'])));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 700));
    expect(shownUrls(tester), ['b']);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('skips a picture that fails to load', (tester) async {
    await tester.pumpWidget(host(carousel(const ['a', 'bad', 'c'])));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 700));
    expect(shownUrls(tester), ['c']);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the fallback when there is no picture', (tester) async {
    await tester.pumpWidget(
      host(carousel(const [' ', ''], fallback: const Text('M'))),
    );
    expect(find.text('M'), findsOneWidget);
    expect(shownUrls(tester), isEmpty);

    await tester.pumpWidget(host(carousel(const [])));
    expect(inCarousel(find.byIcon(Icons.person)), findsOneWidget);
  });

  test('resolveUrls prefers platform pictures over the single avatar', () {
    expect(
      PlatformAvatarCarousel.resolveUrls([' a ', 'b', 'a', ''], 'legacy'),
      ['a', 'b'],
    );
    expect(PlatformAvatarCarousel.resolveUrls(const [], 'legacy'), ['legacy']);
    expect(PlatformAvatarCarousel.resolveUrls(const [], ' '), isEmpty);
  });
}
