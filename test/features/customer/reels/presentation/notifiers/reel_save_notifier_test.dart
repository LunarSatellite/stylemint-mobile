import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reel_save_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_save_notifier.dart';

class _FakeReelSaveApi implements ReelSaveApi {
  Exception? error;
  int? serverCount;
  Completer<void>? gate;
  final List<String> saves = [];
  final List<String> unsaves = [];

  @override
  Future<ReelSaveResult> save(String reelId) async {
    saves.add(reelId);
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    return ReelSaveResult(reelId: reelId, saved: true, saveCount: serverCount);
  }

  @override
  Future<ReelSaveResult> unsave(String reelId) async {
    unsaves.add(reelId);
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    return ReelSaveResult(reelId: reelId, saved: false, saveCount: serverCount);
  }
}

const _unsaved = ReelSaveState(saved: false, count: 4);

void main() {
  late _FakeReelSaveApi api;
  late ReelSaveNotifier notifier;

  setUp(() {
    api = _FakeReelSaveApi();
    notifier = ReelSaveNotifier(() => api);
  });

  test('saving bookmarks at once, then takes the server count', () async {
    api
      ..gate = Completer<void>()
      ..serverCount = 18;

    final pending = notifier.toggle('r-1', fallback: _unsaved);
    expect(notifier.state['r-1'], const ReelSaveState(saved: true, count: 5));

    api.gate!.complete();
    expect(await pending, isTrue);
    expect(api.saves, ['r-1']);
    expect(notifier.state['r-1'], const ReelSaveState(saved: true, count: 18));
  });

  test('unsaving a seeded reel lowers the count', () async {
    notifier.seed('r-1', saved: true, count: 1);

    expect(await notifier.toggle('r-1', fallback: _unsaved), isTrue);
    expect(api.unsaves, ['r-1']);
    expect(notifier.state['r-1'], const ReelSaveState(saved: false, count: 0));
  });

  test('a failed save rolls back', () async {
    api.error = Exception('500');

    expect(await notifier.toggle('r-1', fallback: _unsaved), isFalse);
    expect(notifier.state['r-1'], _unsaved);
  });

  test('a tap while the request runs is ignored', () async {
    api.gate = Completer<void>();

    final first = notifier.toggle('r-1', fallback: _unsaved);
    expect(await notifier.toggle('r-1', fallback: _unsaved), isTrue);
    api.gate!.complete();
    await first;

    expect(api.saves, ['r-1']);
    expect(api.unsaves, isEmpty);
  });

  test('a snapshot cannot overwrite a reel the viewer toggled', () async {
    await notifier.toggle('r-1', fallback: _unsaved);
    notifier.seed('r-1', saved: false, count: 0);

    expect(notifier.state['r-1']?.saved, isTrue);
  });
}
