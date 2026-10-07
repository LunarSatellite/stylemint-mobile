import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/story_composer_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';

import 'stories_fakes.dart';

const _share = Key('story-composer-share');
const _mediaPath = 'picked/story.jpg';

/// Pushes the composer the way the launcher does and records what it pops.
Future<List<bool?>> _openComposer(
  WidgetTester tester,
  FakeStoriesRepository repository,
) async {
  final results = <bool?>[];
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
                onPressed: () async {
                  final posted = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) =>
                          const StoryComposerScreen(mediaPath: _mediaPath),
                    ),
                  );
                  results.add(posted);
                },
                child: const Text('compose'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('compose'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return results;
}

void main() {
  testWidgets('Share to story posts the photo with its caption and closes', (
    tester,
  ) async {
    final repository = FakeStoriesRepository();
    final results = await _openComposer(tester, repository);

    expect(find.text('Share to story'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('story-composer-caption')),
      '  New drop  ',
    );
    await tester.tap(find.byKey(_share));
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    expect(repository.created.single.mediaFile, _mediaPath);
    expect(repository.created.single.caption, 'New drop');
    expect(find.byType(StoryComposerScreen), findsNothing);
    expect(results, [true]);
  });

  testWidgets('an empty caption is sent as no caption', (tester) async {
    final repository = FakeStoriesRepository();
    await _openComposer(tester, repository);

    await tester.tap(find.byKey(_share));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.created.single.caption, isNull);
  });

  testWidgets('a failed post stays put, says why and can be retried', (
    tester,
  ) async {
    final repository = FakeStoriesRepository()
      ..createResult = left(
        const NetworkExceptions.validation(
          code: 'stories.media_too_large',
          message: 'That photo is larger than 5 MB. Pick a smaller one.',
        ),
      );
    final results = await _openComposer(tester, repository);

    await tester.tap(find.byKey(_share));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(StoryComposerScreen), findsOneWidget);
    expect(find.byKey(const Key('story-composer-error')), findsOneWidget);
    expect(
      find.textContaining('larger than 5 MB'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(results, isEmpty);

    repository.createResult = null;
    await tester.tap(find.byKey(_share));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.created, hasLength(2));
    expect(results, [true]);
  });
}
