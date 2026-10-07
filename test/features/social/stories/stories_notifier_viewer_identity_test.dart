import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/notifiers/stories_notifier.dart';

import 'stories_fakes.dart';

// The create-story response used to carry no author name or photo, so the
// story handed back to the composer read "StyleMint user". The notifier now
// fills it from the signed-in viewer.

const StoryViewerIdentity _ramesh = (
  displayName: 'Ramesh',
  avatarUrl: 'https://cdn.test/ramesh.jpg',
);

Story _anonymousStory() => fakeStory(
  'new',
  userId: 'me',
).copyWith(userName: unknownStoryAuthorName, userAvatarUrl: '');

Future<StoriesNotifier> _notifier(
  FakeStoriesRepository repository, {
  StoryViewerIdentity? viewer = _ramesh,
}) async {
  final notifier = StoriesNotifier(repository, readViewer: () => viewer);
  // The constructor starts loading the tray; let it land.
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

void main() {
  test('createStory fills a missing author from the viewer', () async {
    final repository = FakeStoriesRepository()
      ..createResult = right(_anonymousStory());
    final notifier = await _notifier(repository);

    final either = await notifier.createStory(mediaFile: 'picked/story.jpg');

    final story = either.getOrElse((_) => throw StateError('failed'));
    expect(story.userName, 'Ramesh');
    expect(story.userAvatarUrl, 'https://cdn.test/ramesh.jpg');
    notifier.dispose();
  });

  test('createStory keeps the name the server sent', () async {
    // fakeStory names its author "Friend <userId>".
    final notifier = await _notifier(FakeStoriesRepository());

    final either = await notifier.createStory(mediaFile: 'picked/story.jpg');

    final story = either.getOrElse((_) => throw StateError('failed'));
    expect(story.userName, 'Friend me');
    // The photo was missing, so it is still filled.
    expect(story.userAvatarUrl, 'https://cdn.test/ramesh.jpg');
    notifier.dispose();
  });

  test('createStory without a known viewer leaves the stand-in', () async {
    final repository = FakeStoriesRepository()
      ..createResult = right(_anonymousStory());
    final notifier = await _notifier(repository, viewer: null);

    final either = await notifier.createStory(mediaFile: 'picked/story.jpg');

    final story = either.getOrElse((_) => throw StateError('failed'));
    expect(story.userName, unknownStoryAuthorName);
    notifier.dispose();
  });
}
