import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/feed_provenance.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/feed_provenance_badge.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';

import '../../../shared/presentation/mall/mall_harness.dart';

/// AI features contract v1.0 §2.2: each feed item may carry the server's own
/// one-line `explanation` and an `explanationKind`. The card shows it only
/// where the slot backs it — a sentence about the viewer needs a personal
/// slot — and an older server (no explanation) shows the slot label as
/// before.
class _FeedApiClient extends ApiClient {
  _FeedApiClient(this.body) : super(dio: Dio());

  final Map<String, dynamic> body;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => body;
}

Map<String, dynamic> _item(
  String id,
  String slotKind, {
  Object? explanation,
  Object? explanationKind,
}) => {
  'kind': 'Reel',
  'slotKind': slotKind,
  'score': 0.5,
  'explanation': explanation,
  'explanationKind': explanationKind,
  'reel': {'reelId': id, 'externalUrl': 'https://example.test/$id'},
};

void main() {
  test('explanation and its kind are read off the item envelope', () async {
    final page =
        await ReelsRemoteDataSource(
          apiClient: _FeedApiClient({
            'items': [
              _item(
                'r1',
                'Personalized',
                explanation: ' Because you watched @mira ',
                explanationKind: 'becauseYouWatched',
              ),
              _item('r2', 'Popular'),
              _item(
                'r3',
                'Popular',
                explanation: 'Trending now',
                explanationKind: 'trending',
              ),
            ],
          }),
        ).getReelsFeed(limit: 10);

    final first = page.reels[0].provenance!;
    expect(first.explanation, 'Because you watched @mira');
    expect(first.explanationKind, FeedExplanationKind.becauseYouWatched);
    expect(first.shownExplanation, 'Because you watched @mira');
    // The explanation survives the page's ranking pass.
    expect(first.rank, isNotNull);
    expect(page.reels[1].provenance!.shownExplanation, isNull);
    expect(page.reels[2].provenance!.shownExplanation, 'Trending now');
  });

  group('shownExplanation', () {
    FeedProvenance p(
      FeedSlotKind kind,
      String? text, [
      FeedExplanationKind? about,
    ]) => FeedProvenance(
      kind: kind,
      explanation: text,
      explanationKind: about,
    );

    test('a sentence about the viewer needs a personal slot', () {
      const line = 'Because you like Kathmandu Weaves';
      expect(
        p(
          FeedSlotKind.personalized,
          line,
          FeedExplanationKind.brandAffinity,
        ).shownExplanation,
        line,
      );
      for (final kind in [
        FeedSlotKind.popular,
        FeedSlotKind.newIn,
        FeedSlotKind.unknown,
      ]) {
        expect(
          p(kind, line, FeedExplanationKind.brandAffinity).shownExplanation,
          isNull,
          reason: '$kind may not wear a personal sentence',
        );
      }
    });

    test('an unknown or absent kind is treated as about the viewer', () {
      expect(p(FeedSlotKind.popular, 'Something odd').shownExplanation, isNull);
      expect(
        p(FeedSlotKind.exploration, 'Something new to explore')
            .shownExplanation,
        'Something new to explore',
      );
      expect(FeedExplanationKind.parse('notAKind'), isNull);
    });

    test('content-only lines may sit on any slot', () {
      expect(
        p(
          FeedSlotKind.newIn,
          'New in',
          FeedExplanationKind.newIn,
        ).shownExplanation,
        'New in',
      );
    });
  });

  group('FeedProvenanceBadge', () {
    testWidgets('shows the server line in place of the slot label', (
      tester,
    ) async {
      await pumpMall(
        tester,
        const FeedProvenanceBadge(
          provenance: FeedProvenance(
            kind: FeedSlotKind.personalized,
            explanation: 'From @mira, who you follow',
            explanationKind: FeedExplanationKind.followedCreator,
          ),
        ),
      );

      expect(find.text('From @mira, who you follow'), findsOneWidget);
      expect(find.text(FeedSlotKind.personalized.label), findsNothing);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('no explanation (older server): the slot label as before', (
      tester,
    ) async {
      await pumpMall(
        tester,
        const FeedProvenanceBadge(
          provenance: FeedProvenance(kind: FeedSlotKind.popular),
        ),
      );

      expect(find.text('Popular right now'), findsOneWidget);
      expect(find.byKey(FeedProvenanceBadge.explanationKey), findsNothing);
    });

    testWidgets('a personal line on a trending slot is not drawn', (
      tester,
    ) async {
      await pumpMall(
        tester,
        const FeedProvenanceBadge(
          provenance: FeedProvenance(
            kind: FeedSlotKind.popular,
            explanation: 'Because you watched @mira',
            explanationKind: FeedExplanationKind.becauseYouWatched,
          ),
        ),
      );

      expect(find.text('Because you watched @mira'), findsNothing);
      expect(find.text('Popular right now'), findsOneWidget);
    });
  });
}
