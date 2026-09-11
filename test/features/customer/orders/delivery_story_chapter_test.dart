import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';

void main() {
  test('maps the Delivery Story Mode chapter contract', () {
    final chapter = DeliveryStoryChapter.fromJson(const {
      'sequence': 3,
      'kind': 6,
      'title': 'Out for delivery',
      'subtitleMarkdown': 'Your courier is nearby.',
      'occurredUtc': '2026-09-08T10:15:00Z',
    });

    expect(chapter.sequence, 3);
    expect(chapter.kind, DeliveryStoryChapterKind.outForDelivery);
    expect(chapter.title, 'Out for delivery');
    expect(chapter.subtitle, 'Your courier is nearby.');
    expect(chapter.occurredUtc.toUtc(), DateTime.utc(2026, 9, 8, 10, 15));
  });
}
