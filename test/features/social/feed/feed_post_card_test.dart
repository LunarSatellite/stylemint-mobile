import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_formatters.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_post_card.dart';

import 'social_feed_fakes.dart';

class _Calls {
  int likes = 0;
  int comments = 0;
  int shares = 0;
  final products = <String>[];
}

Widget _card(FeedPost post, _Calls calls) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: FeedPostCard(
          post: post,
          index: 0,
          onLikeToggle: () => calls.likes++,
          onComment: () => calls.comments++,
          onShare: () => calls.shares++,
          onTaggedProductTap: calls.products.add,
        ),
      ),
    ),
  );
}

/// The card is taller than the 800x600 test viewport, so anything below the
/// media needs scrolling into view first — and the scroll has to settle before
/// the tap, or it is dispatched against the old layout and hits the
/// SingleChildScrollView rather than the target.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(kDoubleTapMinTime);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('reads like an Instagram post', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_card(samplePost(), calls));

    expect(find.text('Asha Gurung'), findsOneWidget);
    expect(find.text('  •  2h'), findsOneWidget);
    expect(find.text('12 likes'), findsOneWidget);
    expect(find.text('View all 3 comments'), findsOneWidget);
    // The caption leads with the author's name.
    expect(
      find.text('Asha Gurung  Loving this jacket from the weekend drop!'),
      findsOneWidget,
    );
  });

  testWidgets('double-tap on the media likes and pops a heart', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(_card(samplePost(), calls));

    await _doubleTap(tester, find.byType(AspectRatio));

    expect(calls.likes, 1);
    expect(find.byKey(const Key('feed-post-heart-pop')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('feed-post-heart-pop')), findsNothing);
  });

  testWidgets('double-tap never unlikes a post you already like', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(_card(samplePost(isLiked: true), calls));

    await _doubleTap(tester, find.byType(AspectRatio));

    expect(calls.likes, 0);
    expect(find.byKey(const Key('feed-post-heart-pop')), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('action row likes, comments and shares', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_card(samplePost(), calls));

    await _tap(tester, find.byKey(const Key('post-action-like')));
    await _tap(tester, find.byKey(const Key('post-action-comment')));
    await _tap(tester, find.byKey(const Key('post-action-share')));
    await _tap(tester, find.byKey(const Key('feed-post-view-comments')));

    expect(calls.likes, 1);
    expect(calls.comments, 2);
    expect(calls.shares, 1);
    expect(find.bySemanticsLabel('Like post'), findsOneWidget);
  });

  testWidgets('several photos become a carousel with dots and a counter', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _card(samplePost(images: const ['', '', '']), calls),
    );

    expect(find.byKey(const Key('feed-post-dots')), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('feed-post-carousel-post-1')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('a single photo has no dots', (tester) async {
    await tester.pumpWidget(_card(samplePost(), _Calls()));

    expect(find.byKey(const Key('feed-post-dots')), findsNothing);
  });

  testWidgets('tagged products are Shop chips that open the product', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _card(samplePost(taggedProducts: const [sampleProduct]), calls),
    );

    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Denim Jacket'), findsOneWidget);

    await _tap(tester, find.byKey(const Key('feed-post-product-prod-42')));

    expect(calls.products, ['prod-42']);
  });

  testWidgets('a long caption folds behind "more"', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _card(samplePost(content: List.filled(80, 'lovely').join(' ')), calls),
    );

    final more = find.byKey(const Key('feed-post-caption-more'));
    expect(more, findsOneWidget);

    await _tap(tester, more);

    expect(more, findsNothing);
  });

  testWidgets('quiet posts invite the first like and comment', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(samplePost(likeCount: 0, commentCount: 0), _Calls()),
    );

    expect(find.text('Be the first to like this'), findsOneWidget);
    expect(find.text('Add a comment…'), findsOneWidget);
  });

  testWidgets('a text-only post shows its words in place of media', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _card(samplePost(images: const [], content: 'Big sale today'), calls),
    );

    expect(find.byType(AspectRatio), findsNothing);
    expect(find.text('Big sale today'), findsOneWidget);

    await _doubleTap(tester, find.text('Big sale today'));
    expect(calls.likes, 1);
    await tester.pump(const Duration(seconds: 1));
  });

  group('formatters', () {
    test('feedCount groups thousands and abbreviates large counts', () {
      expect(feedCount(7), '7');
      expect(feedCount(1234), '1,234');
      expect(feedCount(12345), '12.3K');
      expect(feedCount(20000), '20K');
      expect(feedCount(4500000), '4.5M');
    });

    test('feedTimeAgo is short, Instagram-style', () {
      final now = DateTime(2026, 10, 7, 12);
      expect(feedTimeAgo(now, now: now), 'now');
      expect(
        feedTimeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5m',
      );
      expect(
        feedTimeAgo(now.subtract(const Duration(hours: 2)), now: now),
        '2h',
      );
      expect(
        feedTimeAgo(now.subtract(const Duration(days: 3)), now: now),
        '3d',
      );
      expect(
        feedTimeAgo(now.subtract(const Duration(days: 14)), now: now),
        '2w',
      );
    });
  });
}
