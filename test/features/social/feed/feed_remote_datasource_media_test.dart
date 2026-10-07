import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/datasources/feed_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';

// The request shapes behind post photos/videos: the staging upload
// (`POST /v1/social/media`) and `CreatePostVm.Media` on `POST /v1/posts`.

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({this.postResponse, this.uploadResponse})
    : super(dio: Dio());

  final dynamic postResponse;
  final dynamic uploadResponse;

  String? postUri;
  dynamic postData;

  String? uploadUri;
  File? uploadFile;
  String? uploadFieldName;
  String? uploadFilename;
  Options? uploadOptions;

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    return postResponse;
  }

  @override
  Future<dynamic> postFile(
    String uri, {
    required File file,
    String fieldName = 'file',
    String? filename,
    Map<String, dynamic>? fields,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    uploadUri = uri;
    uploadFile = file;
    uploadFieldName = fieldName;
    uploadFilename = filename;
    uploadOptions = options;
    onSendProgress?.call(3, 3);
    return uploadResponse;
  }
}

const _createdPost = <String, dynamic>{
  'id': 'post-id',
  'authorAccountId': 'account-id',
  'body': 'Weekend fit',
  'createdUtc': '2026-10-07T00:00:00Z',
  'images': ['https://cdn.test/social-media/a.jpg'],
};

void main() {
  group('createPost', () {
    test('a photo post is type 2 and lists each staged photo in order', () async {
      final api = _RecordingApiClient(postResponse: _createdPost);
      final datasource = FeedRemoteDataSource(apiClient: api);

      final post = await datasource.createPost(
        content: 'Weekend fit',
        media: const [
          UploadedPostMedia(
            url: 'https://cdn.test/social-media/a.jpg',
            kind: PostMediaKind.image,
            contentType: 'image/jpeg',
            width: 1080,
            height: 1350,
          ),
          UploadedPostMedia(
            url: 'https://cdn.test/social-media/b.png',
            kind: PostMediaKind.image,
            contentType: 'image/png',
          ),
        ],
        idempotencyKey: 'key',
      );

      expect(api.postUri, '/v1/posts');
      expect(api.postData, <String, dynamic>{
        'type': 2,
        'visibility': 1,
        'body': 'Weekend fit',
        'media': [
          <String, dynamic>{
            'displayOrder': 0,
            'mediaUrl': 'https://cdn.test/social-media/a.jpg',
            'mediaContentType': 'image/jpeg',
            'widthPx': 1080,
            'heightPx': 1350,
          },
          // Unknown size: the API needs positive numbers, so 1×1.
          <String, dynamic>{
            'displayOrder': 1,
            'mediaUrl': 'https://cdn.test/social-media/b.png',
            'mediaContentType': 'image/png',
            'widthPx': 1,
            'heightPx': 1,
          },
        ],
      });
      expect(post.images, ['https://cdn.test/social-media/a.jpg']);
    });

    test('a single video is a type 3 VideoPost carrying its length', () async {
      final api = _RecordingApiClient(postResponse: _createdPost);
      final datasource = FeedRemoteDataSource(apiClient: api);

      await datasource.createPost(
        content: '',
        media: const [
          UploadedPostMedia(
            url: 'https://cdn.test/social-media/v.mp4',
            kind: PostMediaKind.video,
            contentType: 'video/mp4',
            width: 1080,
            height: 1920,
            durationSeconds: 42,
          ),
        ],
        taggedProductIds: const ['product-id'],
        idempotencyKey: 'key',
      );

      final body = api.postData as Map<String, dynamic>;
      expect(body['type'], 3);
      expect(body['media'], [
        <String, dynamic>{
          'displayOrder': 0,
          'mediaUrl': 'https://cdn.test/social-media/v.mp4',
          'mediaContentType': 'video/mp4',
          'widthPx': 1080,
          'heightPx': 1920,
          'durationSeconds': 42,
        },
      ]);
      // Tagged products still ride along as attachments.
      expect(body['attachments'], [
        <String, dynamic>{
          'kind': 1,
          'referenceId': 'product-id',
          'displayOrder': 0,
        },
      ]);
    });

    test('no media keeps the plain Status post shape', () async {
      final api = _RecordingApiClient(postResponse: _createdPost);
      final datasource = FeedRemoteDataSource(apiClient: api);

      await datasource.createPost(
        content: 'Just words',
        media: const [],
        idempotencyKey: 'key',
      );

      expect(api.postData, <String, dynamic>{
        'type': 1,
        'visibility': 1,
        'body': 'Just words',
      });
    });
  });

  group('uploadPostMedia', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('post_media_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('sends the file as part "file" with a key and reports progress', () async {
      final photo = File('${dir.path}/IMG_0042.JPG')..writeAsBytesSync([1, 2, 3]);
      final api = _RecordingApiClient(
        uploadResponse: <String, dynamic>{
          'url': 'https://cdn.test/social-media/abc.jpg',
          'mediaType': 1,
          'contentType': 'image/jpeg',
          'sizeBytes': 3,
          'width': 1440,
          'height': 1080,
          'durationSeconds': null,
          'thumbnailUrl': null,
        },
      );
      final datasource = FeedRemoteDataSource(apiClient: api);
      final progress = <double>[];

      final dto = await datasource.uploadPostMedia(
        path: photo.path,
        kind: PostMediaKind.image,
        idempotencyKey: 'upload-key',
        onProgress: (sent, total) => progress.add(sent / total),
      );

      expect(api.uploadUri, '/v1/social/media');
      expect(api.uploadFieldName, 'file');
      expect(api.uploadFile?.path, photo.path);
      expect(api.uploadFilename, 'photo.jpg');
      expect(api.uploadOptions?.headers?['Idempotency-Key'], 'upload-key');
      expect(progress, [1.0]);
      final media = dto.toDomain();
      expect(media.url, 'https://cdn.test/social-media/abc.jpg');
      expect(media.kind, PostMediaKind.image);
      expect(media.width, 1440);
      expect(media.height, 1080);
    });

    test('a video keeps its container in the upload name', () async {
      final clip = File('${dir.path}/clip.MOV')..writeAsBytesSync([0]);
      final api = _RecordingApiClient(
        uploadResponse: <String, dynamic>{
          'url': 'https://cdn.test/social-media/abc.mov',
          'mediaType': 2,
          'contentType': 'video/quicktime',
          'durationSeconds': 9,
        },
      );

      final dto = await FeedRemoteDataSource(apiClient: api).uploadPostMedia(
        path: clip.path,
        kind: PostMediaKind.video,
        idempotencyKey: 'k',
      );

      expect(api.uploadFilename, 'video.mov');
      expect(dto.kind, PostMediaKind.video);
      expect(dto.durationSeconds, 9);
    });

    test('a photo over 10 MB is refused before anything is sent', () async {
      final big = File('${dir.path}/big.jpg');
      big.openSync(mode: FileMode.write)
        ..setPositionSync(PostMediaLimits.maxPhotoBytes)
        ..writeByteSync(0)
        ..closeSync();
      final api = _RecordingApiClient();

      await expectLater(
        FeedRemoteDataSource(apiClient: api).uploadPostMedia(
          path: big.path,
          kind: PostMediaKind.image,
          idempotencyKey: 'k',
        ),
        throwsA(
          isA<NetworkExceptions>().having(
            (e) => e.validationCode,
            'code',
            'social_media.too_large',
          ),
        ),
      );
      expect(api.uploadUri, isNull);
    });

    test('a file that is gone says so instead of failing oddly', () async {
      final api = _RecordingApiClient();

      await expectLater(
        FeedRemoteDataSource(apiClient: api).uploadPostMedia(
          path: '${dir.path}/vanished.jpg',
          kind: PostMediaKind.image,
          idempotencyKey: 'k',
        ),
        throwsA(
          isA<NetworkExceptions>().having(
            (e) => e.validationCode,
            'code',
            'social_media.missing',
          ),
        ),
      );
      expect(api.uploadUri, isNull);
    });
  });
}
