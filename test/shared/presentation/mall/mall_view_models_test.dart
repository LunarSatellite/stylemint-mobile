import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

MallProductVm _product(
  double price, {
  double? was,
  String wasCurrency = 'NPR',
}) => MallProductVm(
  id: 'p',
  name: 'Item',
  price: Money(amount: price, currency: 'NPR'),
  compareAtPrice: was == null
      ? null
      : Money(amount: was, currency: wasCurrency),
);

void main() {
  group('MallProductVm discount', () {
    test('rounds down so a discount is never overstated', () {
      expect(_product(3499, was: 4999).discountPercent, 30);
      expect(_product(66.67, was: 100).discountPercent, 33);
    });

    test('is null without a higher original in the same currency', () {
      expect(_product(100).discountPercent, isNull);
      expect(_product(100, was: 90).discountPercent, isNull);
      expect(_product(100, was: 100).discountPercent, isNull);
      expect(
        _product(80, was: 100, wasCurrency: 'USD').discountPercent,
        isNull,
      );
      expect(_product(80, was: 100, wasCurrency: 'USD').isOnSale, isFalse);
    });

    test('is null when the saving rounds below 1%', () {
      expect(_product(99.5, was: 100).isOnSale, isTrue);
      expect(_product(99.5, was: 100).discountPercent, isNull);
    });
  });

  group('MallStrings defaults', () {
    const strings = MallStrings.english;

    test('pluralise counts', () {
      expect(strings.taggedProducts(1), '1 product');
      expect(strings.taggedProducts(3), '3 products');
      expect(strings.itemCount(1), '1 item');
      expect(strings.followers(1), '1 follower');
      expect(strings.likes(12400), '12.4K likes');
    });

    test('compose spoken prices and positions', () {
      expect(strings.discountBadge(30), '-30%');
      expect(strings.percentOff(30), '30% off');
      expect(strings.wasPrice('Rs 4,999'), 'was Rs 4,999');
      expect(strings.rating(4.56), 'Rated 4.6 out of 5');
      expect(strings.slideOf(2, 3), 'Slide 2 of 3');
    });
  });

  test('priceDigits shows paisa only when present', () {
    expect(
      MallMetrics.priceDigits(const Money(amount: 3499, currency: 'NPR')),
      0,
    );
    expect(
      MallMetrics.priceDigits(const Money(amount: 3499.5, currency: 'NPR')),
      2,
    );
  });
}
