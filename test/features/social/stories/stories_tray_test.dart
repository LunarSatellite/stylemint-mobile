import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/story_viewer_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/stories_tray.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';

import 'stories_fakes.dart';

const _tray = Key('stories-tray');
const _yourStory = Key('stories-tray-your-story');

Future<void> _pumpTray(
  WidgetTester tester,
  FakeStoriesRepository repository, {
  StoriesTrayStyle style = StoriesTrayStyle.surface,
  bool hideWhenEmpty = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storiesRepositoryProvider.overrideWithValue(repository),
        storiesCurrentUserProvider.overrideWithValue(
          const StoriesCurrentUser(accountId: 'me', displayName: 'Me'),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: StoriesTray(style: style, hideWhenEmpty: hideWhenEmpty),
        ),
      ),
    ),
  );
  // Fixed pumps: the loading placeholders shimmer for as long as they show.
  await tester.pump();
  await tester.pump();
}

double _left(WidgetTester tester, String userId) => tester
    .getTopLeft(find.byKey(ValueKey('stories-tray-bubble-$userId')))
    .dx;

void main() {
  group('hideWhenEmpty', () {
    testWidgets('nobody on stories: no tray at all', (tester) async {
      await _pumpTray(tester, FakeStoriesRepository(), hideWhenEmpty: true);

      expect(find.byKey(_tray), findsNothing);
    });

    testWidgets('a failed load: no tray at all', (tester) async {
      final repository = FakeStoriesRepository()
        ..groupsResult = left(const NetworkExceptions.server('boom'));
      await _pumpTray(tester, repository, hideWhenEmpty: true);

      expect(find.byKey(_tray), findsNothing);
    });

    testWidgets('someone on stories: the tray shows', (tester) async {
      final repository = FakeStoriesRepository(
        groups: [
          fakeGroup('a', [fakeStory('a1', userId: 'a')]),
        ],
      );
      await _pumpTray(tester, repository, hideWhenEmpty: true);

      expect(find.byKey(_tray), findsOneWidget);
      expect(find.byKey(_yourStory), findsOneWidget);
    });
  });

  testWidgets('without hideWhenEmpty, "Your story" is always there', (
    tester,
  ) async {
    await _pumpTray(tester, FakeStoriesRepository());

    expect(find.byKey(_tray), findsOneWidget);
    expect(find.byKey(_yourStory), findsOneWidget);
    expect(find.text('Your story'), findsOneWidget);
  });

  testWidgets('a failed load keeps "Your story" and offers a retry', (
    tester,
  ) async {
    final repository = FakeStoriesRepository()
      ..groupsResult = left(const NetworkExceptions.server('boom'));
    await _pumpTray(tester, repository);

    expect(find.byKey(_yourStory), findsOneWidget);
    expect(repository.groupCalls, 1);

    repository.groupsResult = right(const []);
    await tester.tap(find.byKey(const Key('stories-tray-retry')));
    await tester.pump();

    expect(repository.groupCalls, 2);
  });

  testWidgets('new stories come before seen ones; yours is not repeated', (
    tester,
  ) async {
    final repository = FakeStoriesRepository(
      groups: [
        fakeGroup('seen', [fakeStory('s1', userId: 'seen', watched: true)]),
        fakeGroup('me', [fakeStory('m1', userId: 'me', watched: true)]),
        fakeGroup('fresh', [fakeStory('f1', userId: 'fresh')]),
      ],
    );
    await _pumpTray(tester, repository);

    final yourStory = tester.getTopLeft(find.byKey(_yourStory)).dx;
    expect(yourStory, lessThan(_left(tester, 'fresh')));
    expect(_left(tester, 'fresh'), lessThan(_left(tester, 'seen')));
    expect(
      find.byKey(const ValueKey('stories-tray-bubble-me')),
      findsNothing,
    );
  });

  testWidgets('the overlay tray stays compact over a reel', (tester) async {
    final repository = FakeStoriesRepository(
      groups: [
        fakeGroup('a', [fakeStory('a1', userId: 'a')]),
      ],
    );
    await _pumpTray(
      tester,
      repository,
      style: StoriesTrayStyle.overlay,
      hideWhenEmpty: true,
    );

    final height = tester.getSize(find.byKey(_tray)).height;
    expect(height, inInclusiveRange(96, 104));
  });

  testWidgets('tapping a bubble opens the viewer on that person and marks '
      'their story seen', (tester) async {
    final repository = FakeStoriesRepository(
      groups: [
        fakeGroup('a', [fakeStory('a1', userId: 'a', caption: 'From A')]),
        fakeGroup('b', [fakeStory('b1', userId: 'b', caption: 'From B')]),
      ],
    );
    await _pumpTray(tester, repository);

    await tester.tap(find.byKey(const ValueKey('stories-tray-bubble-b')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(StoryViewerScreen), findsOneWidget);
    expect(find.text('Friend b'), findsWidgets);
    expect(find.text('From B'), findsOneWidget);
    expect(repository.viewed, ['b1']);
  });

  testWidgets('"Your story" with nothing posted opens the composer choice', (
    tester,
  ) async {
    await _pumpTray(tester, FakeStoriesRepository());

    await tester.tap(find.byKey(_yourStory));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('story-source-camera')), findsOneWidget);
    expect(find.byKey(const Key('story-source-gallery')), findsOneWidget);
  });

  testWidgets('"Your story" with stories up opens them; the + still adds', (
    tester,
  ) async {
    final repository = FakeStoriesRepository(
      groups: [
        fakeGroup('me', [fakeStory('m1', userId: 'me', watched: true, views: 3)]),
      ],
    );
    await _pumpTray(tester, repository);

    await tester.tap(find.byKey(const Key('stories-tray-add-story')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('story-source-gallery')), findsOneWidget);

    // Dismiss the sheet, then open your own stories.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Your story'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(StoryViewerScreen), findsOneWidget);
    expect(find.text('3 views'), findsOneWidget);
    expect(repository.viewed, isEmpty, reason: 'own views are not counted');
  });
}
