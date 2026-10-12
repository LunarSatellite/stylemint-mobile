import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/datasources/profile_remote_datasource.dart';

Map<String, dynamic> _page(List<Object?> states) => {
  'items': [
    for (final s in states) {'orderNumber': 'SM-$s', 'state': s},
  ],
  'totalCount': states.length,
};

void main() {
  group('ongoingOrderCount', () {
    test('counts placed, paid and fulfilling orders only', () {
      // 1 Placed, 2 Paid, 3 Fulfilling, 4 Completed, 5 Cancelled.
      expect(ongoingOrderCount(_page([1, 2, 3, 4, 5, 4, 3])), 4);
    });

    test('is zero when every order is completed or cancelled', () {
      expect(ongoingOrderCount(_page([4, 5, 4])), 0);
    });

    test('ignores totalCount, which counts every order', () {
      final page = _page([4, 1])..['totalCount'] = 37;
      expect(ongoingOrderCount(page), 1);
    });

    test('reads state names as well as numbers', () {
      expect(
        ongoingOrderCount(_page(['Placed', 'Fulfilling', 'Completed'])),
        2,
      );
    });

    test('an unexpected body counts as none rather than throwing', () {
      expect(ongoingOrderCount(null), 0);
      expect(ongoingOrderCount(<String, dynamic>{}), 0);
      expect(ongoingOrderCount({'items': 'nope'}), 0);
      expect(ongoingOrderCount(_page([null, 'Shipped', 9])), 0);
    });
  });
}
