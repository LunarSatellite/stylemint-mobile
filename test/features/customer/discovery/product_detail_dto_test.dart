import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_detail_dto.dart';

void main() {
  test('maps backend SKU choices to the matching cart variant IDs', () {
    final product = ProductDetailDto(
      id: 'product-1',
      vendorAccountId: 'vendor-1',
      name: 'Sample product',
      variants: const [
        ProductVariantDto(id: 'sku-small', sku: 'Small', isDefault: true),
        ProductVariantDto(id: 'sku-large', sku: 'Large'),
      ],
    ).toDomain();

    expect(product.defaultVariantId, 'sku-small');
    expect(product.variants, hasLength(1));
    expect(product.variants.single.values, ['Small', 'Large']);
    expect(product.variants.single.optionVariantIds, {
      'Small': 'sku-small',
      'Large': 'sku-large',
    });
  });
}
