import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/reel_shapes.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';

class _Media implements ReelMedia {
  const _Media(this.platform, this.platformVideoId);

  @override
  final SocialPlatform? platform;

  @override
  final String? platformVideoId;

  @override
  String? get videoUrl => null;

  @override
  String? get thumbnailUrl => null;

  @override
  String get permalink => '';
}

void main() {
  const wide = _Media(SocialPlatform.youtube, 'I1bYtU4F2AQ');
  const short = _Media(SocialPlatform.youtube, '39bix0Z0NOQ');

  late List<Uri> loaded;

  ReelShapes shapes({double? aspect, bool fail = false}) {
    loaded = [];
    return ReelShapes(
      loadThumbnail: (url) async {
        loaded.add(url);
        if (fail) throw StateError('offline');
        return Uint8List(4);
      },
      readShape: (_) async => aspect,
    );
  }

  test(
    "a wide video's shape is learned from its thumbnail and announced",
    () async {
      final store = shapes(aspect: 16 / 9);
      var notified = 0;
      store.addListener(() => notified++);

      await store.learnReel(wide);

      expect(store.aspectOf(wide), 16 / 9);
      expect(notified, 1);
      expect(
        loaded.single.toString(),
        'https://i.ytimg.com/vi/I1bYtU4F2AQ/hqdefault.jpg',
      );
    },
  );

  test('a Short keeps the Short layout and is only checked once', () async {
    final store = shapes();
    var notified = 0;
    store.addListener(() => notified++);

    await store.learnReel(short);
    await store.learnReel(short);

    expect(store.aspectOf(short), isNull);
    expect(notified, 0);
    expect(loaded, hasLength(1));
  });

  test('reels from other platforms are never looked up', () async {
    final store = shapes(aspect: 16 / 9);
    const tiktok = _Media(SocialPlatform.tiktok, '7312345678');

    await store.learnReel(tiktok);

    expect(store.aspectOf(tiktok), isNull);
    expect(loaded, isEmpty);
  });

  test('a failed download stays unknown and is tried again later', () async {
    final store = shapes(fail: true);

    await store.learnReel(wide);
    await store.learnReel(wide);

    expect(store.aspectOf(wide), isNull);
    expect(loaded, hasLength(2));
  });

  test(
    'showing the same reel twice at once downloads its thumbnail once',
    () async {
      final store = shapes(aspect: 16 / 9);

      await Future.wait([store.learnReel(wide), store.learnReel(wide)]);

      expect(loaded, hasLength(1));
    },
  );
}
