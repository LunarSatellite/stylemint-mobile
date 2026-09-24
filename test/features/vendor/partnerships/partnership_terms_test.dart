import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/partnership_terms.dart';

void main() {
  group('PartnershipTerms.isPublishable', () {
    test('needs a heading and a line in both sections', () {
      const empty = PartnershipTerms();
      expect(empty.isPublishable, isFalse);

      const halfDone = PartnershipTerms(whoCanJoin: ['Anyone']);
      expect(halfDone.isPublishable, isFalse);

      const done = PartnershipTerms(
        whoCanJoin: ['Anyone'],
        reelRules: ['Tag a product'],
      );
      expect(done.isPublishable, isTrue);
    });

    test('whitespace is not a line', () {
      const blank = PartnershipTerms(
        whoCanJoin: ['   '],
        reelRules: ['Tag a product'],
      );
      expect(blank.isPublishable, isFalse);
    });

    test('a blanked-out heading blocks publishing', () {
      const headless = PartnershipTerms(
        whoCanJoinHeading: '  ',
        whoCanJoin: ['Anyone'],
        reelRules: ['Tag a product'],
      );
      expect(headless.isPublishable, isFalse);
    });
  });

  group('PartnershipTerms.toJson', () {
    test('matches the PublishTermsVm shape', () {
      const terms = PartnershipTerms(
        whoCanJoin: ['Anyone'],
        reelRules: ['Tag a product'],
      );

      expect(terms.toJson(), {
        'whoCanJoin': {
          'heading': 'Who Can Join',
          'bullets': ['Anyone'],
        },
        'reelContentRules': {
          'heading': 'Reel Content Rules',
          'bullets': [
            {'text': 'Tag a product', 'inlineLinks': <Map<String, dynamic>>[]},
          ],
        },
      });
    });

    // A row the vendor left empty is somebody who stopped typing, not an
    // error — but the server rejects a blank bullet outright.
    test('drops blank rows and trims the rest', () {
      const terms = PartnershipTerms(
        whoCanJoinHeading: '  Who  ',
        whoCanJoin: ['  Anyone  ', '', '   '],
        reelRules: ['  Tag a product  ', ''],
      );

      final json = terms.toJson();
      expect(json['whoCanJoin'], {
        'heading': 'Who',
        'bullets': ['Anyone'],
      });
      expect(
        (json['reelContentRules']! as Map<String, dynamic>)['bullets'],
        [
          {'text': 'Tag a product', 'inlineLinks': <Map<String, dynamic>>[]},
        ],
      );
    });
  });
}
