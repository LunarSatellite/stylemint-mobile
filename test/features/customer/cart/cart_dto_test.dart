import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';

void main() {
  test('maps the backend promo and saved-for-later Cart fields', () {
    final cart = CartDto.fromJson(<String, dynamic>{
      'accountId': 'account-1',
      'lines': const <dynamic>[],
      'subtotalAmount': 1000,
      'shippingAmount': 0,
      'taxAmount': 130,
      'discountAmount': 100,
      'grandTotalAmount': 1030,
      'appliedPromoCode': <String, dynamic>{
        'code': 'WELCOME10',
        'discountAmount': 100,
        'discountAmountCurrency': 'NPR',
      },
      'savedForLater': <dynamic>[
        <String, dynamic>{
          'id': 'saved-1',
          'productTitleSnapshot': 'Everyday backpack',
          'variantLabelSnapshot': 'Black',
          'thumbnailUrlSnapshot': 'https://example.test/backpack.jpg',
          'quantity': 2,
          'unitPriceAmount': 500,
          'unitPriceCurrency': 'NPR',
        },
      ],
    }).toDomain();

    expect(cart.discount.amount, 100);
    expect(cart.appliedPromoCode?.code, 'WELCOME10');
    expect(cart.appliedPromoCode?.discount.amount, 100);
    expect(cart.savedForLater, hasLength(1));
    expect(cart.savedForLater.single.productName, 'Everyday backpack');
    expect(cart.savedForLater.single.quantity, 2);
  });
}
