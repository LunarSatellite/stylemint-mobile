import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/data/models/evidence_answer_dto.dart';

import 'evidence_fixtures.dart';

void main() {
  group('evidenceAnswerFromJson', () {
    test('reads every field the contract defines', () {
      final answer = evidenceAnswerFromJson(
        answerJson(consequences: [consequenceJson()]),
      );

      expect(answer.schemaVersion, 1);
      expect(answer.query, 'Is this seller trustworthy?');
      expect(answer.asOfUtc, DateTime.utc(2026, 9, 19, 14, 30));
      expect(answer.evidence, hasLength(1));
      expect(answer.evidence.single.confidence, 0.95);
      expect(answer.evidence.single.validToUtc, isNull);
      expect(answer.consequences.single.evidenceFactIds, ['f-1']);
      expect(answer.hasEvidence, isTrue);
    });

    test('reads the product id out of a product subject key', () {
      final answer = evidenceAnswerFromJson(answerJson());
      expect(
        answer.evidence.single.productId,
        '11111111-1111-1111-1111-111111111111',
      );
    });

    test('a non-product subject key yields no product id', () {
      final answer = evidenceAnswerFromJson(
        answerJson(evidence: [factJson(subjectKey: 'vendor:abc')]),
      );
      expect(answer.evidence.single.productId, isNull);
    });

    test('a future schema version with unknown fields still parses', () {
      final json = answerJson(schemaVersion: 99)
        ..['somethingNobodyHasWrittenYet'] = {'a': 1}
        ..['evidence'] = [
          factJson()..['brandNewField'] = ['x'],
        ];

      final answer = evidenceAnswerFromJson(json);

      expect(answer.schemaVersion, 99);
      expect(answer.evidence, hasLength(1));
      expect(answer.hasEvidence, isTrue);
    });

    test('missing, null and wrongly-typed fields degrade, never throw', () {
      final answer = evidenceAnswerFromJson(<String, dynamic>{
        'schemaVersion': null,
        'asOfUtc': 'not-a-date',
        'answer': null,
        'evidence': 'not-a-list',
        'consequences': <dynamic>[42, 'nope'],
        'limitations': <dynamic>[1, null, 'A real caveat.'],
        'evidenceDigestSha256': 7,
      });

      expect(answer.schemaVersion, 0);
      expect(answer.asOfUtc, isNull);
      expect(answer.answer, '');
      expect(answer.evidence, isEmpty);
      expect(answer.consequences, isEmpty);
      expect(answer.limitations, ['A real caveat.']);
      expect(answer.evidenceDigestSha256, '');
      expect(answer.hasEvidence, isFalse);
    });

    test('an entirely empty payload parses to an evidence-free answer', () {
      final answer = evidenceAnswerFromJson(<String, dynamic>{});
      expect(answer.hasEvidence, isFalse);
      expect(answer.evidence, isEmpty);
    });

    test('a fact with a blank statement is not evidence', () {
      final answer = evidenceAnswerFromJson(
        answerJson(evidence: [factJson(statement: '   ')]),
      );
      expect(answer.evidence, isEmpty);
      expect(answer.hasEvidence, isFalse);
    });

    test('an absent confidence stays null and never becomes zero', () {
      final json = answerJson(evidence: [factJson()..remove('confidence')]);
      expect(evidenceAnswerFromJson(json).evidence.single.confidence, isNull);
    });

    test('a confidence the backend sent as zero survives as zero', () {
      final answer = evidenceAnswerFromJson(
        answerJson(evidence: [factJson(confidence: 0)]),
      );
      expect(answer.evidence.single.confidence, 0.0);
    });

    test('factsById returns only the facts a forecast named', () {
      final answer = evidenceAnswerFromJson(
        answerJson(
          evidence: [
            factJson(statement: 'First'),
            factJson(factId: 'f-2', statement: 'Second'),
          ],
          consequences: [
            consequenceJson(evidenceFactIds: ['f-2', 'f-missing']),
          ],
        ),
      );

      final rests = answer.factsById(
        answer.consequences.single.evidenceFactIds,
      );
      expect(rests.map((fact) => fact.statement), ['Second']);
    });
  });
}
