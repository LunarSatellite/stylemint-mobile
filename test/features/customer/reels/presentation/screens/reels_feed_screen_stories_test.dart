import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reels_feed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reels_pager.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/repositories/stories_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/stories_tray.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';

import '../../../mall_home/mall_test_support.dart';

class _MockCartRepository extends Mock implements CartRepository {}

class _FakeFollowApi implements FollowApi {
  @override
  Future<void> follow(String followeeAccountId) async {}

  @override
  Future<void> unfollow(String followeeAccountId) async {}

  @override
  Future<List<String>> followingIds({int pageSize = 200}) async =>
      const <String>[];

  @override
  Future<FollowStats> stats(String accountId) => throw UnimplementedError();
}

class _FakeReelsRepository implements ReelsRepository {
  List<Reel> reels = [_reel('r-1'), _reel('r-2'), _reel('r-3')];
  int feedCalls = 0;

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getReelsFeed({
    int limit = 20,
    String? cursor,
  }) async {
    feedCalls++;
    return right(ReelsFeedPage(reels: reels, nextCursor: null));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers the story groups it is given and counts how often it was asked.
class _FakeStoriesRepository implements StoriesRepository {
  Either<NetworkExceptions, List<StoryGroup>> groups = right(const []);
  int groupCalls = 0;

  @override
  Future<Either<NetworkExceptions, List<StoryGroup>>> getStoryGroups() async {
    groupCalls++;
    return groups;
  }

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

/// Instagram without media: shows its poster, no WebView needed.
Reel _reel(String id) => Reel(
  id: id,
  sourceUrl: 'https://www.instagram.com/reel/$id/',
  thumbnailUrl: '',
  creatorId: 'creator-$id',
  creatorName: 'Creator $id',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: const [],
  likeCount: 3,
  commentCount: 1,
  shareCount: 0,
  createdAt: DateTime(2026, 9, 15),
);

StoryGroup _group(String userId) => StoryGroup(
  userId: userId,
  userName: 'Friend $userId',
  userAvatarUrl: '',
  stories: [
    Story(
      id: 'story-$userId',
      userId: userId,
      userName: 'Friend $userId',
      userAvatarUrl: '',
      mediaUrl: '',
      mediaType: 'image',
      taggedProductIds: const [],
      // Still up whenever the test runs, should anything filter on expiry.
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 12)),
      viewCount: 0,
      hasWatched: false,
    ),
  ],
  hasUnwatched: true,
);

const _zero = Money(amount: 0, currency: 'NPR');

void main() {
  late _FakeReelsRepository reels;
  late _FakeStoriesRepository stories;
  late _MockCartRepository cart;

  setUp(() {
    ReelsPager.debugHostEmbedPlayers = false;
    reels = _FakeReelsRepository();
    stories = _FakeStoriesRepository();
    cart = _MockCartRepository();
    when(() => cart.getCart()).thenAnswer(
      (_) async => right(
        const Cart(
          id: 'cart',
          items: [],
          subtotal: _zero,
          shippingTotal: _zero,
          taxTotal: _zero,
          total: _zero,
        ),
      ),
    );
  });

  tearDown(() => ReelsPager.debugHostEmbedPlayers = true);

  /// Lets a page snap and the strip's own motion finish. Fixed pumps rather
  /// than pumpAndSettle: the tray is free to animate its rings forever. The
  /// strip only starts to move once the page has come to rest, so this waits
  /// out the snap first and the strip after it.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<ProviderContainer> pumpFeed(WidgetTester tester) async {
    await pumpMallApp(
      tester,
      location: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const ReelsFeedScreen()),
      ],
      overrides: [
        mallViewerSignedInProvider.overrideWithValue(false),
        reelsRepositoryProvider.overrideWithValue(reels),
        storiesRepositoryProvider.overrideWithValue(stories),
        cartRepositoryProvider.overrideWithValue(cart),
        followApiProvider.overrideWithValue(_FakeFollowApi()),
      ],
    );
    // The stories may answer after the reels, and the strip then opens with
    // its usual motion.
    await settle(tester);
    return ProviderScope.containerOf(
      tester.element(find.byType(ReelsFeedScreen)),
    );
  }

  final tray = find.byKey(ReelsFeedScreen.storiesTrayKey);

  /// Whether the strip is open: taking room and taking touches. Closed, it
  /// must both give all its height back and let every touch through.
  bool stripOpen(WidgetTester tester) {
    final ignoring = tester.widget<IgnorePointer>(tray).ignoring;
    final height = tester.getSize(tray).height;
    expect(ignoring, height == 0, reason: 'closed and untouchable together');
    return !ignoring;
  }

  /// The strip sits above [below], sharing no pixel with it.
  void expectStripAbove(WidgetTester tester, Finder below) {
    final strip = tester.getRect(tray);
    expect(strip.height, greaterThan(ReelsFeedScreen.storiesTrayExtent));
    expect(
      strip.bottom,
      lessThanOrEqualTo(tester.getRect(below).top),
      reason: 'the strip ends where the content below it begins',
    );
  }

  Future<void> swipe(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(PageView), Offset(0, dy));
    await settle(tester);
  }

  /// The page the pager rests on, read off the PageView itself.
  double? pagerPage(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView)).controller?.page;

  testWidgets('with someone on stories, the strip sits above the first reel', (
    tester,
  ) async {
    stories.groups = right([_group('a'), _group('b')]);
    await pumpFeed(tester);

    expect(find.byType(ReelsPager), findsOneWidget);
    expect(tray, findsOneWidget);
    expect(stripOpen(tester), isTrue);

    final storiesTray = tester.widget<StoriesTray>(
      find.descendant(of: tray, matching: find.byType(StoriesTray)).first,
    );
    expect(storiesTray.style, StoriesTrayStyle.surface);
    expect(storiesTray.hideWhenEmpty, isTrue);

    // Above the pager, and above the first reel: nothing of the strip lies
    // over the video any more.
    expectStripAbove(tester, find.byType(PageView));
    // Only the reel on screen is found; its neighbours are built offstage.
    expectStripAbove(tester, find.byType(ReelCard));
    expect(
      tester.getRect(find.byType(ReelCard)).bottom,
      tester.getRect(find.byType(ReelsFeedScreen)).bottom,
      reason: 'the first reel takes the rest of the screen',
    );
  });

  testWidgets('with nobody on stories there is no strip and a full reel', (
    tester,
  ) async {
    await pumpFeed(tester);

    expect(find.byType(ReelsPager), findsOneWidget);
    expect(tray, findsNothing);
    expect(
      tester.getRect(find.byType(ReelCard)),
      tester.getRect(find.byType(ReelsFeedScreen)),
      reason: 'the first reel is full height, exactly as before stories',
    );
  });

  testWidgets('a stories failure never puts a strip above the reels', (
    tester,
  ) async {
    stories.groups = left(const NetworkExceptions.server('boom'));
    await pumpFeed(tester);

    expect(find.byType(ReelsPager), findsOneWidget);
    expect(tray, findsNothing);
    expect(
      tester.getRect(find.byType(ReelCard)),
      tester.getRect(find.byType(ReelsFeedScreen)),
    );
  });

  testWidgets('the strip collapses past the first reel and returns to it', (
    tester,
  ) async {
    stories.groups = right([_group('a')]);
    await pumpFeed(tester);
    expect(stripOpen(tester), isTrue);

    await swipe(tester, -600);
    expect(
      tester.widget<ReelCard>(find.byType(ReelCard)).reel.id,
      'r-2',
      reason: 'the swipe landed on the second reel',
    );
    expect(stripOpen(tester), isFalse);
    expect(tester.getSize(tray).height, 0);
    // Closed, nothing of the strip can be touched.
    expect(
      find
          .descendant(of: tray, matching: find.byType(StoriesTray))
          .hitTestable(),
      findsNothing,
    );
    // The pager grew into the strip's room without leaving its page, and the
    // second reel has the whole screen.
    expect(pagerPage(tester), closeTo(1, 0.001));
    expect(
      tester.getRect(find.byType(ReelCard)),
      tester.getRect(find.byType(ReelsFeedScreen)),
      reason: 'later reels are full height',
    );

    await swipe(tester, 600);
    expect(tester.widget<ReelCard>(find.byType(ReelCard)).reel.id, 'r-1');
    expect(stripOpen(tester), isTrue);
    expect(pagerPage(tester), closeTo(0, 0.001));
    expectStripAbove(tester, find.byType(ReelCard));
  });

  testWidgets('re-tapping Home refreshes stories and brings the strip back', (
    tester,
  ) async {
    stories.groups = right([_group('a')]);
    final container = await pumpFeed(tester);
    expect(stories.groupCalls, 1);

    await swipe(tester, -600);
    expect(stripOpen(tester), isFalse);

    container.read(homeTabReselectedProvider.notifier).state++;
    await settle(tester);

    expect(reels.feedCalls, 2);
    expect(stories.groupCalls, 2);
    expect(stripOpen(tester), isTrue);
    expectStripAbove(tester, find.byType(ReelCard));
  });

  testWidgets('pulling down on the first reel refreshes stories too', (
    tester,
  ) async {
    stories.groups = right([_group('a')]);
    await pumpFeed(tester);
    expect(stories.groupCalls, 1);

    // Well past the pager's pull-to-refresh threshold, from the first reel.
    await tester.drag(find.byType(PageView), const Offset(0, 400));
    await settle(tester);

    expect(stories.groupCalls, 2);
    expect(stripOpen(tester), isTrue);
    expectStripAbove(tester, find.byType(ReelCard));
  });

  testWidgets('an empty feed still shows who has a story', (tester) async {
    reels.reels = [];
    stories.groups = right([_group('a')]);
    await pumpFeed(tester);

    expect(find.byType(SmEmptyState), findsOneWidget);
    expect(tray, findsOneWidget);
    expect(stripOpen(tester), isTrue);
    expectStripAbove(tester, find.byType(SmEmptyState));
  });
}
