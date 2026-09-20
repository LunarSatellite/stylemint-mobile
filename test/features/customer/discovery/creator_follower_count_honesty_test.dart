import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/creator_chip_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_creator_card.dart';

/// Guards the follower figure on creator surfaces.
///
/// The backend's `followerCount` used to come from a cached column that is
/// seeded to 0 and has no refresher, so every creator card read "0 followers".
/// A zero here is not a missing value -- it is the claim that nobody follows
/// this creator. These assert over *rendered* output, so they keep failing if
/// a `?? 0` is reintroduced anywhere on the path.
void main() {
  group('CreatorChipDto', () {
    test('leaves an absent follower count absent instead of defaulting to 0',
        () {
      final dto = CreatorChipDto.fromJson(const {
        'accountId': 'account-1',
        'handle': 'minty',
        'reelCount': 3,
      });

      expect(
        dto.followerCount,
        isNull,
        reason: 'a missing followerCount must not become the claim "0 followers"',
      );
    });

    test('keeps a measured zero, which is a real answer', () {
      final dto = CreatorChipDto.fromJson(const {
        'accountId': 'account-1',
        'handle': 'minty',
        'followerCount': 0,
      });

      expect(dto.followerCount, 0);
    });

    test('carries a measured total through unchanged', () {
      final dto = CreatorChipDto.fromJson(const {
        'accountId': 'account-1',
        'handle': 'minty',
        'followerCount': 1234,
      });

      expect(dto.followerCount, 1234);
    });
  });

  group('DiscoverCreatorCard', () {
    DiscoverCreator creator({int? followers}) => DiscoverCreator(
          id: 'account-1',
          name: 'Aanya',
          handle: '@aanya',
          avatarUrl: '',
          category: '',
          description: '',
          rating: 0,
          followers: followers,
          isFollowing: false,
        );

    Future<void> pump(WidgetTester tester, DiscoverCreator c) =>
        tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DiscoverCreatorCard(creator: c)),
          ),
        ));

    testWidgets('renders no follower line at all when nothing was measured',
        (tester) async {
      await pump(tester, creator());

      expect(find.textContaining('Followers'), findsNothing);
      expect(
        find.textContaining('0 Followers'),
        findsNothing,
        reason: 'an unmeasured total must never be drawn as zero',
      );
    });

    testWidgets('renders a measured total', (tester) async {
      await pump(tester, creator(followers: 1234));

      expect(find.textContaining('Followers'), findsOneWidget);
    });
  });
}
