import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/content_freshness.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/content_freshness_banner.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

final _now = DateTime.utc(2026, 9, 14, 15, 22);
final _fetched = DateTime.utc(2026, 9, 14, 15, 10);

Future<void> _pump(
  WidgetTester tester, {
  required ContentFreshness freshness,
  SocialPlatform platform = SocialPlatform.instagram,
  VoidCallback? onReconnect,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ContentFreshnessBanner(
        freshness: freshness,
        platform: platform,
        onReconnect: onReconnect ?? () {},
        clock: () => _now,
      ),
    ),
  ),
);

ContentFreshness _saved(String? code, {DateTime? retryAfter}) =>
    ContentFreshness(
      servedFromCache: true,
      fetchedUtc: _fetched,
      providerStatus: code == null
          ? null
          : ContentProviderStatus(code: code, retryAfterUtc: retryAfter),
    );

void main() {
  group('ContentFreshnessBanner', () {
    testWidgets('renders nothing for a live page', (tester) async {
      await _pump(tester, freshness: ContentFreshness(fetchedUtc: _now));

      expect(
        find.textContaining(ContentFreshnessCopy.savedReels),
        findsNothing,
      );
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('saved reels show when they were updated', (tester) async {
      await _pump(tester, freshness: _saved(null));

      expect(
        find.text('Showing saved reels · updated 12 min ago'),
        findsOneWidget,
      );
      expect(find.byKey(ContentFreshnessBanner.reconnectKey), findsNothing);
    });

    testWidgets('saved reels without a fetch time omit the age', (
      tester,
    ) async {
      await _pump(
        tester,
        freshness: const ContentFreshness(servedFromCache: true),
      );

      expect(find.text('Showing saved reels'), findsOneWidget);
    });

    testWidgets('rate limited names the platform and the retry time', (
      tester,
    ) async {
      await _pump(
        tester,
        platform: SocialPlatform.tiktok,
        freshness: _saved(
          'RATE_LIMITED',
          retryAfter: _now.add(const Duration(minutes: 18)),
        ),
      );

      expect(
        find.text('Showing saved reels · updated 12 min ago'),
        findsOneWidget,
      );
      expect(
        find.text('TikTok is limiting requests right now'),
        findsOneWidget,
      );
      expect(find.textContaining('Try again at '), findsOneWidget);
      expect(find.byKey(ContentFreshnessBanner.reconnectKey), findsNothing);
    });

    testWidgets('a retry time in the past is not shown', (tester) async {
      await _pump(
        tester,
        freshness: _saved(
          'RATE_LIMITED',
          retryAfter: _now.subtract(const Duration(minutes: 1)),
        ),
      );

      expect(find.textContaining('Try again at '), findsNothing);
    });

    testWidgets('provider unavailable says it is not responding', (
      tester,
    ) async {
      await _pump(
        tester,
        platform: SocialPlatform.youtube,
        freshness: _saved('PROVIDER_UNAVAILABLE'),
      );

      expect(find.text("YouTube isn't responding"), findsOneWidget);
      expect(find.byKey(ContentFreshnessBanner.reconnectKey), findsNothing);
    });

    for (final code in [
      'TOKEN_INVALID',
      'TOKEN_EXPIRED',
      'INVALID_GRANT',
      'SCOPE_NARROWED',
    ]) {
      testWidgets('$code asks to reconnect and offers the action', (
        tester,
      ) async {
        var reconnects = 0;
        await _pump(
          tester,
          freshness: _saved(code),
          onReconnect: () => reconnects++,
        );

        expect(find.text('Reconnect Instagram to refresh'), findsOneWidget);
        await tester.tap(find.byKey(ContentFreshnessBanner.reconnectKey));
        expect(reconnects, 1);
      });
    }

    testWidgets('permission missing asks for permission with reconnect', (
      tester,
    ) async {
      var reconnects = 0;
      await _pump(
        tester,
        platform: SocialPlatform.facebook,
        freshness: _saved('PERMISSION_MISSING'),
        onReconnect: () => reconnects++,
      );

      expect(find.text('Facebook needs permission again'), findsOneWidget);
      expect(find.text(ContentFreshnessCopy.reconnectLabel), findsOneWidget);
      await tester.tap(find.byKey(ContentFreshnessBanner.reconnectKey));
      expect(reconnects, 1);
    });

    testWidgets('a provider problem on a live list shows only the reason', (
      tester,
    ) async {
      await _pump(
        tester,
        freshness: const ContentFreshness(
          providerStatus: ContentProviderStatus(code: 'RATE_LIMITED'),
        ),
      );

      expect(
        find.textContaining(ContentFreshnessCopy.savedReels),
        findsNothing,
      );
      expect(
        find.text('Instagram is limiting requests right now'),
        findsOneWidget,
      );
    });
  });

  group('ContentFreshnessCopy', () {
    test('ago uses short plain units', () {
      expect(ContentFreshnessCopy.ago(_now, _now), 'just now');
      expect(
        ContentFreshnessCopy.ago(
          _now.subtract(const Duration(minutes: 12)),
          _now,
        ),
        '12 min ago',
      );
      expect(
        ContentFreshnessCopy.ago(_now.subtract(const Duration(hours: 3)), _now),
        '3 hr ago',
      );
      expect(
        ContentFreshnessCopy.ago(_now.subtract(const Duration(days: 1)), _now),
        '1 day ago',
      );
      expect(
        ContentFreshnessCopy.ago(_now.subtract(const Duration(days: 4)), _now),
        '4 days ago',
      );
    });

    test('blocked refresh message names the platform and time', () {
      final message = ContentFreshnessCopy.refreshBlocked(
        ContentProviderIssue.rateLimited,
        SocialPlatform.instagram,
        _now.add(const Duration(minutes: 5)),
        _now,
      );

      expect(message, startsWith('Instagram is limiting requests right now.'));
      expect(message, contains('Try again at '));
      expect(message, isNot(contains('!')));
    });

    test('unknown provider codes are not issues', () {
      expect(ContentProviderIssue.fromCode('validation.required'), isNull);
      expect(ContentProviderIssue.fromCode(null), isNull);
      expect(
        ContentProviderIssue.fromCode('rate_limited'),
        ContentProviderIssue.rateLimited,
      );
    });
  });
}
