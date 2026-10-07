import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/stories_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';

import 'stories_fakes.dart';

Widget _app(FakeStoriesRepository repository) => ProviderScope(
  overrides: [
    storiesRepositoryProvider.overrideWithValue(repository),
    storiesCurrentUserProvider.overrideWithValue(
      const StoriesCurrentUser(accountId: 'me'),
    ),
  ],
  child: const MaterialApp(home: StoriesScreen()),
);

void main() {
  testWidgets('empty standalone Stories route renders a useful page', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FakeStoriesRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Stories'), findsOneWidget);
    expect(find.byKey(const Key('stories-tray')), findsOneWidget);
    expect(find.byKey(const Key('stories-tray-your-story')), findsOneWidget);
    expect(find.text('No active stories yet.'), findsOneWidget);
    expect(find.text('Add Story'), findsOneWidget);
  });

  testWidgets('Add Story opens the camera / gallery choice, not a stub', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FakeStoriesRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Story'));
    await tester.pumpAndSettle();

    expect(find.text('Add to your story'), findsOneWidget);
    expect(find.byKey(const Key('story-source-camera')), findsOneWidget);
    expect(find.byKey(const Key('story-source-gallery')), findsOneWidget);
    expect(find.text('Posting a story is coming soon.'), findsNothing);
  });

  testWidgets('each person with a story gets a tile, your own first', (
    tester,
  ) async {
    final repository = FakeStoriesRepository(
      groups: [
        fakeGroup('a', [fakeStory('a1', userId: 'a', watched: true)]),
        fakeGroup('me', [fakeStory('m1', userId: 'me', watched: true)]),
        fakeGroup('b', [fakeStory('b1', userId: 'b')]),
      ],
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    final mine = tester.getTopLeft(find.byKey(const ValueKey('stories-tile-me')));
    final b = tester.getTopLeft(find.byKey(const ValueKey('stories-tile-b')));
    expect(mine.dx, lessThan(b.dx), reason: 'yours, then new ones');
    expect(find.byKey(const ValueKey('stories-tile-a'), skipOffstage: false), findsOneWidget);
    expect(find.text('No active stories yet.'), findsNothing);
  });
}
