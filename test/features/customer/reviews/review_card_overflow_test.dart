import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/review_card.dart';

/// A verified review with a helpful count — the two rows that overflowed at
/// 320dp x 1.3 before the fix (238px on the "Verified Purchase" row, 15px on
/// the "found helpful" row).
final _review = Review(
  id: 'r1',
  userId: 'u1',
  userName: 'Sushmita Shrestha',
  userAvatarUrl: 'https://example.test/a.jpg',
  rating: 5,
  comment: 'Beautifully made and warm.',
  createdAt: DateTime.utc(2026, 9),
  images: const [],
  helpfulCount: 1284,
  isVerifiedPurchase: true,
);

void main() {
  testWidgets('ReviewCard does not overflow at 320dp with text at 1.3x', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 1200),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SingleChildScrollView(child: ReviewCard(review: _review)),
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(tester.takeException(), isNull);
    // Both wrap rather than truncate, so neither reads as something else.
    expect(find.text('Verified Purchase'), findsOneWidget);
    expect(find.text('1284 found helpful'), findsOneWidget);
  });
}
