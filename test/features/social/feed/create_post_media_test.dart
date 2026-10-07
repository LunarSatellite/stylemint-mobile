import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/feed_viewer_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/post_media_picker_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/create_post_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_post_card.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/shared/providers.dart';

import '../../../smoke/fake_api_client.dart';
import 'social_feed_fakes.dart';

// The post composer's photo/video attachments: picking (behind a fake
// picker), per-file upload progress and retry, and the media the post is
// finally created with.

const _photo1 = PickedPostMedia(
  path: '/picked/one.jpg',
  kind: PostMediaKind.image,
  width: 1080,
  height: 1350,
);
const _photo2 = PickedPostMedia(
  path: '/picked/two.jpg',
  kind: PostMediaKind.image,
  width: 1440,
  height: 1080,
);
const _clip = PickedPostMedia(
  path: '/picked/clip.mp4',
  kind: PostMediaKind.video,
  width: 1080,
  height: 1920,
  duration: Duration(seconds: 12),
);

class _FakePicker implements PostMediaPicker {
  List<PickedPostMedia> photos = const [];
  PickedPostMedia? camera;
  PickedPostMedia? video;
  PlatformException? error;
  int? lastLimit;

  @override
  Future<List<PickedPostMedia>> pickPhotos({required int limit}) async {
    if (error != null) throw error!;
    lastLimit = limit;
    return photos;
  }

  @override
  Future<PickedPostMedia?> takePhoto() async {
    if (error != null) throw error!;
    return camera;
  }

  @override
  Future<PickedPostMedia?> pickVideo() async {
    if (error != null) throw error!;
    return video;
  }
}

class _MediaFeedRepository extends FakeFeedRepository {
  final uploads = <String>[];
  final failPaths = <String>{};

  /// When set, uploads report 50% and then wait for it.
  Completer<void>? gate;

  int createCalls = 0;
  String? createdContent;
  List<UploadedPostMedia>? createdMedia;

  @override
  Future<Either<NetworkExceptions, UploadedPostMedia>> uploadPostMedia({
    required String path,
    required PostMediaKind kind,
    void Function(int sent, int total)? onProgress,
  }) async {
    uploads.add(path);
    onProgress?.call(50, 100);
    if (gate != null) await gate!.future;
    if (failPaths.contains(path)) {
      return left(
        const NetworkExceptions.validation(
          code: 'MEDIA_TOO_LARGE',
          message: 'Photos must be 10 MB or smaller.',
        ),
      );
    }
    onProgress?.call(100, 100);
    final isVideo = kind == PostMediaKind.video;
    return right(
      UploadedPostMedia(
        url: 'https://cdn.test/social-media/${uploads.length}'
            '.${isVideo ? 'mp4' : 'jpg'}',
        kind: kind,
        contentType: isVideo ? 'video/mp4' : 'image/jpeg',
        width: 999,
        height: 999,
        durationSeconds: isVideo ? 12 : null,
      ),
    );
  }

  @override
  Future<Either<NetworkExceptions, FeedPost>> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
    List<UploadedPostMedia>? media,
  }) async {
    createCalls++;
    createdContent = content;
    createdMedia = media;
    return right(
      samplePost(
        id: 'post-new',
        content: content,
        images: [for (final m in media ?? const <UploadedPostMedia>[]) m.url],
      ),
    );
  }
}

/// A launcher screen that opens the composer, so a successful post can be
/// seen to close it.
Widget _app(_MediaFeedRepository repository, _FakePicker picker) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(FakeApiClient()),
      feedRepositoryProvider.overrideWithValue(repository),
      feedViewerProvider.overrideWithValue(
        const FeedViewer(displayName: 'Sam Rai'),
      ),
      postMediaPickerProvider.overrideWithValue(picker),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CreatePostScreen()),
            ),
            child: const Text('open composer'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openComposer(WidgetTester tester) async {
  await tester.tap(find.text('open composer'));
  await tester.pumpAndSettle();
  expect(find.byType(CreatePostScreen), findsOneWidget);
}

Future<void> _tapAction(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
  await tester.pump();
}

ButtonStyleButton _actionButton(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );

ElevatedButton _postButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byKey(const Key('create-post-submit')));

void main() {
  late _MediaFeedRepository repository;
  late _FakePicker picker;

  setUp(() {
    repository = _MediaFeedRepository();
    picker = _FakePicker();
  });

  testWidgets('Photo attaches picked photos as removable thumbnails', (
    tester,
  ) async {
    picker.photos = const [_photo1, _photo2];
    await tester.pumpWidget(_app(repository, picker));
    await _openComposer(tester);

    expect(_postButton(tester).onPressed, isNull);
    await _tapAction(tester, 'create-post-add-photo');

    expect(picker.lastLimit, PostMediaLimits.maxPhotos);
    expect(find.byKey(const Key('composer-media-0')), findsOneWidget);
    expect(find.byKey(const Key('composer-media-1')), findsOneWidget);
    // Media alone is enough to post.
    expect(_postButton(tester).onPressed, isNotNull);
    // A photo post can't also take a video.
    expect(_actionButton(tester, 'create-post-add-video').onPressed, isNull);

    await tester.tap(find.byKey(const Key('composer-remove-0')));
    await tester.pump();
    expect(find.byKey(const Key('composer-media-0')), findsNothing);
    expect(find.byKey(const Key('composer-media-1')), findsOneWidget);
  });

  testWidgets('Video stands alone and shows its length', (tester) async {
    picker.video = _clip;
    await tester.pumpWidget(_app(repository, picker));
    await _openComposer(tester);

    await _tapAction(tester, 'create-post-add-video');

    expect(find.byKey(const Key('composer-video-preview')), findsOneWidget);
    expect(find.text('0:12'), findsOneWidget);
    expect(_actionButton(tester, 'create-post-add-photo').onPressed, isNull);
    expect(_actionButton(tester, 'create-post-add-camera').onPressed, isNull);
  });

  testWidgets('A video over 60 seconds is refused with a reason', (
    tester,
  ) async {
    picker.video = const PickedPostMedia(
      path: '/picked/long.mp4',
      kind: PostMediaKind.video,
      duration: Duration(seconds: 75),
    );
    await tester.pumpWidget(_app(repository, picker));
    await _openComposer(tester);

    await _tapAction(tester, 'create-post-add-video');

    expect(find.byKey(const Key('composer-video-preview')), findsNothing);
    expect(find.textContaining('up to 60 seconds'), findsOneWidget);
  });

  testWidgets('A refused photo permission says to turn it on in Settings', (
    tester,
  ) async {
    picker.error = PlatformException(code: 'photo_access_denied');
    await tester.pumpWidget(_app(repository, picker));
    await _openComposer(tester);

    await _tapAction(tester, 'create-post-add-photo');

    expect(find.textContaining('Turn it on in Settings'), findsOneWidget);
  });

  testWidgets('Post uploads each file, then creates the post with their URLs', (
    tester,
  ) async {
    picker.photos = const [_photo1, _photo2];
    await tester.pumpWidget(_app(repository, picker));
    await _openComposer(tester);

    await _tapAction(tester, 'create-post-add-photo');
    await tester.enterText(find.byType(TextFormField), 'Weekend fit');
    await tester.pump();
    await tester.tap(find.byKey(const Key('create-post-submit')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.uploads, [_photo1.path, _photo2.path]);
    expect(repository.createCalls, 1);
    expect(repository.createdContent, 'Weekend fit');
    final media = repository.createdMedia!;
    expect(media.map((m) => m.url), [
      'https://cdn.test/social-media/1.jpg',
      'https://cdn.test/social-media/2.jpg',
    ]);
    expect(media.every((m) => m.kind == PostMediaKind.image), isTrue);
    // The device's decoded size wins for photos (EXIF-rotated).
    expect(media.first.width, _photo1.width);
    expect(media.first.height, _photo1.height);
    expect(find.byType(CreatePostScreen), findsNothing);
  });

  testWidgets('Upload progress shows per file and holds the Post button', (
    tester,
  ) async {
    picker.photos = const [_photo1];
    repository.gate = Completer<void>();
    await tester.pumpWidget(_app(repository, picker));
    await _openComposer(tester);

    await _tapAction(tester, 'create-post-add-photo');
    await tester.tap(find.byKey(const Key('create-post-submit')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('composer-progress-0')), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(_postButton(tester).onPressed, isNull);
    // Mid-upload a tile can't be removed.
    expect(find.byKey(const Key('composer-remove-0')), findsNothing);

    repository.gate!.complete();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(repository.createCalls, 1);
  });

  testWidgets('A failed upload keeps everything; Post again re-sends only it', (
    tester,
  ) async {
    picker.photos = const [_photo1, _photo2];
    repository.failPaths.add(_photo2.path);
    await tester.pumpWidget(_app(repository, picker));
    await _openComposer(tester);

    await _tapAction(tester, 'create-post-add-photo');
    await tester.tap(find.byKey(const Key('create-post-submit')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.createCalls, 0);
    expect(find.byKey(const Key('create-post-error')), findsOneWidget);
    expect(find.byKey(const Key('composer-retry-1')), findsOneWidget);
    expect(find.byType(CreatePostScreen), findsOneWidget);

    repository.failPaths.clear();
    await tester.tap(find.byKey(const Key('create-post-submit')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.uploads, [_photo1.path, _photo2.path, _photo2.path]);
    expect(repository.createCalls, 1);
    expect(repository.createdMedia, hasLength(2));
  });

  testWidgets('A video post sends one video with its length', (tester) async {
    picker.video = _clip;
    await tester.pumpWidget(_app(repository, picker));
    await _openComposer(tester);

    await _tapAction(tester, 'create-post-add-video');
    await tester.tap(find.byKey(const Key('create-post-submit')));
    await tester.pump();
    await tester.pumpAndSettle();

    final media = repository.createdMedia!;
    expect(media, hasLength(1));
    expect(media.single.kind, PostMediaKind.video);
    expect(media.single.durationSeconds, 12);
    expect(media.single.url, endsWith('.mp4'));
  });

  testWidgets('A text-only post still goes out without media', (tester) async {
    await tester.pumpWidget(_app(repository, picker));
    await _openComposer(tester);

    await tester.enterText(find.byType(TextFormField), 'Just words');
    await tester.pump();
    await tester.tap(find.byKey(const Key('create-post-submit')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.uploads, isEmpty);
    expect(repository.createCalls, 1);
    expect(repository.createdMedia, isNull);
  });

  testWidgets('The feed card draws an .mp4 post as a tap-to-play video', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FeedPostCard(
              post: samplePost(
                images: const ['https://cdn.test/social-media/abc.mp4'],
              ),
              index: 0,
              onLikeToggle: () {},
              onComment: () {},
              onShare: () {},
              onTaggedProductTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('feed-post-video')), findsOneWidget);
    expect(find.byKey(const Key('post-video-play')), findsOneWidget);
  });

  test('isVideoMediaUrl reads the extension, ignoring query strings', () {
    expect(isVideoMediaUrl('https://cdn/x/abc.mp4'), isTrue);
    expect(isVideoMediaUrl('https://cdn/x/abc.MOV?sig=1'), isTrue);
    expect(isVideoMediaUrl('https://cdn/x/abc.jpg'), isFalse);
    expect(isVideoMediaUrl('https://cdn/x.mp4/abc'), isFalse);
    expect(isVideoMediaUrl(''), isFalse);
  });
}
