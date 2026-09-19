import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/feed_provenance.dart';

/// The feed used to stamp every cold-start item `Personalized` and give it a
/// descending `1.0 - (i * 0.01)` — list position wearing a relevance score's
/// clothes. Both are gone. These tests hold the client to the same standard:
/// an unknown label is never read as a personalisation claim, and a null score
/// never becomes a number.
void main() {
  group('FeedSlotKind.parse', () {
    test('reads the names the Discovery mapper emits', () {
      expect(FeedSlotKind.parse('Personalized'), FeedSlotKind.personalized);
      expect(FeedSlotKind.parse('Exploration'), FeedSlotKind.exploration);
      expect(FeedSlotKind.parse('Popular'), FeedSlotKind.popular);
      expect(FeedSlotKind.parse('NewIn'), FeedSlotKind.newIn);
    });

    test('reads the integer ordinals, should the encoding change', () {
      expect(FeedSlotKind.parse(1), FeedSlotKind.personalized);
      expect(FeedSlotKind.parse(2), FeedSlotKind.exploration);
      expect(FeedSlotKind.parse(3), FeedSlotKind.popular);
      expect(FeedSlotKind.parse(4), FeedSlotKind.newIn);
      expect(FeedSlotKind.parse('4'), FeedSlotKind.newIn);
    });

    test('an unknown future value degrades to unknown, never personalized', () {
      for (final raw in <Object?>[
        'Curated',
        'SponsoredForYou',
        5,
        99,
        -1,
        '',
        '   ',
        null,
        true,
        <String, dynamic>{},
      ]) {
        final kind = FeedSlotKind.parse(raw);
        expect(
          kind,
          FeedSlotKind.unknown,
          reason: '$raw must not resolve to a known slot kind',
        );
        expect(
          kind.isPersonal,
          isFalse,
          reason: 'an unknown slot kind may never claim personalisation',
        );
      }
    });

    test('only the two personal kinds claim a relationship to the reader', () {
      expect(FeedSlotKind.personalized.isPersonal, isTrue);
      expect(FeedSlotKind.exploration.isPersonal, isTrue);
      expect(FeedSlotKind.popular.isPersonal, isFalse);
      expect(FeedSlotKind.newIn.isPersonal, isFalse);
      expect(FeedSlotKind.unknown.isPersonal, isFalse);
    });

    test('generic labels carry no personalisation phrasing', () {
      const personalPhrases = [
        'for you',
        'your',
        'based on',
        'we thought',
        'picked',
        'because you',
        'recommended',
        'match',
      ];
      for (final kind in [
        FeedSlotKind.popular,
        FeedSlotKind.newIn,
        FeedSlotKind.unknown,
      ]) {
        final copy = '${kind.label} ${kind.spokenLabel}'.toLowerCase();
        for (final phrase in personalPhrases) {
          expect(
            copy,
            isNot(contains(phrase)),
            reason: '${kind.name} copy must not imply personalisation',
          );
        }
      }
    });
  });

  group('FeedProvenance.fromJson', () {
    test('keeps a real score and a missing score apart', () {
      expect(
        FeedProvenance.fromJson(const {
          'slotKind': 'Popular',
          'score': 12.5,
        }).score,
        12.5,
      );
      expect(
        FeedProvenance.fromJson(const {
          'slotKind': 'NewIn',
          'score': null,
        }).score,
        isNull,
      );
      expect(
        FeedProvenance.fromJson(const {'slotKind': 'NewIn'}).score,
        isNull,
      );
    });

    test('a zero score is a score, not an absence', () {
      final provenance = FeedProvenance.fromJson(const {
        'slotKind': 'Popular',
        'score': 0,
      });
      expect(provenance.score, 0);
      expect(provenance.score, isNotNull);
    });

    test('a missing slotKind degrades to unknown', () {
      expect(
        FeedProvenance.fromJson(const {}).kind,
        FeedSlotKind.unknown,
      );
    });
  });

  group('FeedProvenance.rankAll', () {
    test('ranks scored items highest first, 1-based', () {
      final ranked = FeedProvenance.rankAll(const [
        FeedProvenance(kind: FeedSlotKind.popular, score: 3),
        FeedProvenance(kind: FeedSlotKind.popular, score: 9),
        FeedProvenance(kind: FeedSlotKind.popular, score: 5),
      ]);
      expect(ranked.map((p) => p.rank), [3, 1, 2]);
    });

    test('an unranked item gets no rank — not zero, not last', () {
      final ranked = FeedProvenance.rankAll(const [
        FeedProvenance(kind: FeedSlotKind.newIn),
        FeedProvenance(kind: FeedSlotKind.popular, score: 9),
        FeedProvenance(kind: FeedSlotKind.newIn),
        FeedProvenance(kind: FeedSlotKind.popular, score: 4),
      ]);
      expect(ranked[0].rank, isNull);
      expect(ranked[2].rank, isNull);
      expect(ranked[0].isRanked, isFalse);
      expect(ranked[0].rankLabel, isNull);
      expect(ranked[0].spokenRank, isNull);
      // The scored pair keeps 1 and 2; nothing was pushed to the bottom to
      // make room for the unranked ones.
      expect(ranked[1].rank, 1);
      expect(ranked[3].rank, 2);
      expect(ranked.map((p) => p.rank), isNot(contains(0)));
    });

    test('a page where nothing was ranked stays entirely unranked', () {
      final ranked = FeedProvenance.rankAll(const [
        FeedProvenance(kind: FeedSlotKind.newIn),
        FeedProvenance(kind: FeedSlotKind.newIn),
      ]);
      expect(ranked.every((p) => p.rank == null), isTrue);
    });

    test('ties keep their original order', () {
      final ranked = FeedProvenance.rankAll(const [
        FeedProvenance(kind: FeedSlotKind.popular, score: 5),
        FeedProvenance(kind: FeedSlotKind.popular, score: 5),
      ]);
      expect(ranked.map((p) => p.rank), [1, 2]);
    });

    test('an empty page ranks nothing', () {
      expect(FeedProvenance.rankAll(const []), isEmpty);
    });
  });
}
