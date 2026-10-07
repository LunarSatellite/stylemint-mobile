import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/story_viewer_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';

import 'stories_fakes.dart';

/// Opens the viewer from a plain page, the way the tray does, so closing it
/// has somewhere to return to.
Future<void> _openViewer(
  WidgetTester tester,
  FakeStoriesRepository repository,
  List<StoryGroup> groups, {
  int initialGroupIndex = 0,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storiesRepositoryProvider.overrideWithValue(repository),
        storiesCurrentUserProvider.overrideWithValue(
          const StoriesCurrentUser(accountId: 'me'),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => StoryViewerScreen.open(
                  context,
                  groups: groups,
                  initialGroupIndex: initialGroupIndex,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tapRight(WidgetTester tester) async {
  final size = tester.getSize(find.byType(StoryViewerScreen));
  await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tapLeft(WidgetTester tester) async {
  final size = tester.getSize(find.byType(StoryViewerScreen));
  await tester.tapAt(Offset(size.width * 0.1, size.height / 2));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late FakeStoriesRepository repository;

  setUp(() => repository = FakeStoriesRepository());

  testWidgets('header shows who and how long ago; tap right / left steps '
      'through stories and on to the next person', (tester) async {
    await _openViewer(tester, repository, [
      fakeGroup('a', [
        fakeStory('a1', userId: 'a', caption: 'first'),
        fakeStory('a2', userId: 'a', caption: 'second'),
      ]),
      fakeGroup('b', [fakeStory('b1', userId: 'b', caption: 'from b')]),
    ]);

    expect(find.text('Friend a'), findsOneWidget);
    expect(find.text('12h'), findsOneWidget);
    expect(find.text('first'), findsOneWidget);

    await _tapRight(tester);
    expect(find.text('second'), findsOneWidget);

    await _tapLeft(tester);
    expect(find.text('first'), findsOneWidget);

    await _tapRight(tester);
    await _tapRight(tester);
    expect(find.text('Friend b'), findsOneWidget);
    expect(find.text('from b'), findsOneWidget);
    expect(repository.viewed, ['a1', 'a2', 'b1']);
  });

  testWidgets('media that will not load shows a placeholder and moves on', (
    tester,
  ) async {
    await _openViewer(tester, repository, [
      fakeGroup('a', [
        fakeStory('a1', userId: 'a', caption: 'first'),
        fakeStory('a2', userId: 'a', caption: 'second'),
      ]),
    ]);

    expect(find.text("This story couldn't load."), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('starts at the first story not yet seen', (tester) async {
    await _openViewer(tester, repository, [
      fakeGroup('a', [
        fakeStory('a1', userId: 'a', caption: 'old', watched: true),
        fakeStory('a2', userId: 'a', caption: 'new'),
      ]),
    ]);

    expect(find.text('new'), findsOneWidget);
    expect(repository.viewed, ['a2']);
  });

  testWidgets('close button and the end of the last story both close it', (
    tester,
  ) async {
    await _openViewer(tester, repository, [
      fakeGroup('a', [fakeStory('a1', userId: 'a')]),
    ]);

    await tester.tap(find.byKey(const Key('story-viewer-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(StoryViewerScreen), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _tapRight(tester);
    expect(find.byType(StoryViewerScreen), findsNothing);
  });

  testWidgets('swiping down closes it', (tester) async {
    await _openViewer(tester, repository, [
      fakeGroup('a', [fakeStory('a1', userId: 'a')]),
    ]);

    await tester.drag(
      find.byType(StoryViewerScreen),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(StoryViewerScreen), findsNothing);
  });

  testWidgets('your own story shows its views and can be deleted', (
    tester,
  ) async {
    await _openViewer(tester, repository, [
      fakeGroup('me', [
        fakeStory('m1', userId: 'me', watched: true, views: 1),
        fakeStory('m2', userId: 'me', watched: true, views: 7),
      ]),
    ]);

    expect(find.text('Your story'), findsOneWidget);
    expect(find.text('1 view'), findsOneWidget);

    await tester.tap(find.byKey(const Key('story-viewer-more')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('story-viewer-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Delete this story?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('story-viewer-delete-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.deleted, ['m1']);
    expect(find.text('7 views'), findsOneWidget);
    expect(repository.viewed, isEmpty);

    // Let the confirmation snackbar run out before the test ends.
    await tester.pump(const Duration(seconds: 3));
  });
}
