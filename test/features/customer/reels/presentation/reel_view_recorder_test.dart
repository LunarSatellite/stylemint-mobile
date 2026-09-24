import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/reel_view_recorder.dart';

class _RecordingRepository implements ReelsRepository {
  final List<(String, bool)> views = [];

  @override
  Future<Either<NetworkExceptions, Unit>> recordView(
    String reelId, {
    required bool completed,
  }) async {
    views.add((reelId, completed));
    return right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Every call fails, the way it does for a guest — the endpoint needs a
/// signed-in viewer.
class _FailingRepository implements ReelsRepository {
  int calls = 0;

  @override
  Future<Either<NetworkExceptions, Unit>> recordView(
    String reelId, {
    required bool completed,
  }) async {
    calls++;
    return left(const NetworkExceptions.auth());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Reel _reel(String id, {int? durationSeconds}) => Reel(
  id: id,
  sourceUrl: 'https://www.tiktok.com/@maker/video/$id',
  thumbnailUrl: '',
  creatorId: 'creator',
  creatorName: 'maker',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: const [],
  likeCount: 0,
  commentCount: 0,
  shareCount: 0,
  createdAt: DateTime(2026),
  durationSeconds: durationSeconds,
);

void main() {
  group('reelViewCompleted', () {
    test('needs 90% of a known duration', () {
      expect(reelViewCompleted(const Duration(seconds: 8), 10), isFalse);
      expect(reelViewCompleted(const Duration(seconds: 9), 10), isTrue);
      expect(reelViewCompleted(const Duration(seconds: 30), 10), isTrue);
    });

    test('an unknown or zero length is never completed', () {
      expect(reelViewCompleted(const Duration(minutes: 5), null), isFalse);
      expect(reelViewCompleted(const Duration(minutes: 5), 0), isFalse);
    });
  });

  group('ReelViewRecorder', () {
    test('a swipe straight past does not count as a view', () {
      final repo = _RecordingRepository();
      ReelViewRecorder(repo).recordDwell(
        _reel('r1', durationSeconds: 10),
        const Duration(milliseconds: 400),
      );
      expect(repo.views, isEmpty);
    });

    test('a watch counts once, and counts as incomplete when it is', () {
      final repo = _RecordingRepository();
      final recorder = ReelViewRecorder(repo);
      final reel = _reel('r1', durationSeconds: 10);

      recorder
        ..recordDwell(reel, const Duration(seconds: 3))
        ..recordDwell(reel, const Duration(seconds: 3));

      expect(repo.views, [('r1', false)]);
    });

    // The plain view already went; the completed one still says something
    // the first did not, so it is worth the second call.
    test('a reel watched to the end later is upgraded exactly once', () {
      final repo = _RecordingRepository();
      final recorder = ReelViewRecorder(repo);
      final reel = _reel('r1', durationSeconds: 10);

      recorder
        ..recordDwell(reel, const Duration(seconds: 3))
        ..recordDwell(reel, const Duration(seconds: 10))
        ..recordDwell(reel, const Duration(seconds: 10));

      expect(repo.views, [('r1', false), ('r1', true)]);
    });

    test('a failed view is swallowed', () {
      final repo = _FailingRepository();
      ReelViewRecorder(repo).recordDwell(
        _reel('r1', durationSeconds: 10),
        const Duration(seconds: 3),
      );
      expect(repo.calls, 1);
    });

    test('a reel with no id is not reported', () {
      final repo = _RecordingRepository();
      ReelViewRecorder(repo).recordDwell(
        _reel('', durationSeconds: 10),
        const Duration(seconds: 3),
      );
      expect(repo.views, isEmpty);
    });
  });
}
