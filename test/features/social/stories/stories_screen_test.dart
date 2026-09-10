import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/repositories/stories_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/stories_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';

class _EmptyStoriesRepository implements StoriesRepository {
  @override
  Future<Either<NetworkExceptions, List<StoryGroup>>> getStoryGroups() async =>
      right(const <StoryGroup>[]);

  @override
  Future<Either<NetworkExceptions, List<Story>>> getStories(
    String userId,
  ) async => right(const <Story>[]);

  @override
  Future<Either<NetworkExceptions, Story>> createStory({
    required String mediaFile,
    String? caption,
    List<String>? taggedProductIds,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, Unit>> deleteStory(String storyId) async =>
      right(unit);

  @override
  Future<Either<NetworkExceptions, Unit>> viewStory(String storyId) async =>
      right(unit);
}

void main() {
  testWidgets('empty standalone Stories route renders a useful page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storiesRepositoryProvider.overrideWithValue(
            _EmptyStoriesRepository(),
          ),
        ],
        child: const MaterialApp(home: StoriesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('No active stories yet.'), findsOneWidget);
    expect(find.text('Add Story'), findsOneWidget);

    await tester.tap(find.text('Add Story'));
    await tester.pump();

    expect(find.text('Posting a story is coming soon.'), findsOneWidget);
  });
}
