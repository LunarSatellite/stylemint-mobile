import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';

/// A row exactly as `GET /v1/customer/reorder-suggestions` sends it today.
Map<String, dynamic> _json({bool withConfidence = true}) => {
  'productId': 'p-1',
  'productName': 'Aloe Face Wash',
  'thumbnailUrl': null,
  'suggestedQuantity': 2,
  'reason':
      "Based on your typical 30-day restock cycle — you're likely "
      'running low',
  'price': 450.0,
  'currency': 'NPR',
  'daysUntilExpected': 4,
  if (withConfidence) 'confidence': 0.72,
};

void main() {
  group('ReorderSuggestionDto tolerates a payload with no confidence', () {
    test('a payload omitting the field entirely still parses', () {
      final dto = ReorderSuggestionDto.fromJson(_json(withConfidence: false));

      expect(dto.productId, 'p-1');
      expect(dto.productName, 'Aloe Face Wash');
      expect(dto.suggestedQuantity, 2);
      expect(dto.daysUntilExpected, 4);
      expect(dto.price, 450.0);
      expect(dto.currency, 'NPR');
    });

    test('an absent confidence is null, and never a default', () {
      final dto = ReorderSuggestionDto.fromJson(_json(withConfidence: false));

      expect(dto.confidence, isNull);
      // The specific failure this guards: a `?? 0` that turns "the server
      // sent nothing" into "the model is certain this is wrong".
      expect(dto.confidence, isNot(0.0));
    });

    test('an explicit null confidence parses as null', () {
      final json = _json()..['confidence'] = null;

      expect(ReorderSuggestionDto.fromJson(json).confidence, isNull);
    });

    test('a confidence the backend still sends is parsed, not dropped', () {
      // Tolerating absence must not mean silently discarding a present
      // value — the field stays readable until the backend stops sending it.
      expect(ReorderSuggestionDto.fromJson(_json()).confidence, 0.72);
    });

    test('a confidence sent as an int survives as a double', () {
      final json = _json()..['confidence'] = 1;

      expect(ReorderSuggestionDto.fromJson(json).confidence, 1.0);
    });

    test('a zero the backend actually sent survives as zero', () {
      final json = _json()..['confidence'] = 0;

      expect(ReorderSuggestionDto.fromJson(json).confidence, 0.0);
    });

    test('every other field is still required', () {
      final json = _json()..remove('productName');

      expect(() => ReorderSuggestionDto.fromJson(json), throwsA(anything));
    });
  });
}
