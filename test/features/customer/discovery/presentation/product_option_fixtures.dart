import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_option.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A product page product with nothing option-related set.
ProductDetail baseProduct({
  List<ProductOption> options = const <ProductOption>[],
  List<ProductVariantOption> optionVariants = const <ProductVariantOption>[],
  Money? price,
  Money? compareAtPrice,
  String? defaultVariantId,
  int? stockCount,
}) => ProductDetail(
  id: 'p-1',
  name: 'Linen shirt',
  description: 'Breathable',
  images: const <String>[],
  price: price ?? const Money(amount: 2499, currency: 'NPR'),
  compareAtPrice: compareAtPrice,
  rating: 4.5,
  reviewCount: 8,
  vendorId: 'v-1',
  vendorName: 'Kathmandu Atelier',
  vendorAvatarUrl: '',
  isInStock: true,
  stockCount: stockCount,
  variants: const <ProductVariant>[],
  specifications: const <String, String>{},
  shippingInfo: '',
  isSaved: false,
  isInCart: false,
  defaultVariantId: defaultVariantId ?? 'var-m-emerald',
  options: options,
  optionVariants: optionVariants,
);

/// Size (M, L) × Colour (Emerald, Ink, Sand), where:
/// - Emerald is sold in M (4 left) and L (2 left),
/// - Ink is sold in M (1 left) and L (none left),
/// - Sand is sold in M only.
List<ProductOption> sampleOptions() => const [
  ProductOption(
    id: 'opt-size',
    name: 'Size',
    kind: ProductOptionKind.size,
    values: [
      ProductOptionValue(id: 'size-m', value: 'M'),
      ProductOptionValue(id: 'size-l', value: 'L', sortOrder: 1),
    ],
  ),
  ProductOption(
    id: 'opt-colour',
    name: 'Colour',
    kind: ProductOptionKind.colour,
    sortOrder: 1,
    values: [
      ProductOptionValue(
        id: 'col-emerald',
        value: 'Emerald',
        swatchHex: '#0F7B5A',
      ),
      ProductOptionValue(
        id: 'col-ink',
        value: 'Ink',
        sortOrder: 1,
        swatchHex: '#1B1B2F',
      ),
      ProductOptionValue(
        id: 'col-sand',
        value: 'Sand',
        sortOrder: 2,
        swatchHex: '#D8C3A5',
      ),
    ],
  ),
];

List<ProductVariantOption> sampleVariants() => const [
  ProductVariantOption(
    variantId: 'var-m-emerald',
    optionValueIds: {'size-m', 'col-emerald'},
    optionLabel: 'M / Emerald',
    priceAmount: 2499,
    quantityOnHand: 4,
    isDefault: true,
  ),
  ProductVariantOption(
    variantId: 'var-l-emerald',
    optionValueIds: {'size-l', 'col-emerald'},
    optionLabel: 'L / Emerald',
    priceAmount: 2699,
    quantityOnHand: 2,
  ),
  ProductVariantOption(
    variantId: 'var-m-ink',
    optionValueIds: {'size-m', 'col-ink'},
    optionLabel: 'M / Ink',
    priceAmount: 2499,
    quantityOnHand: 1,
  ),
  ProductVariantOption(
    variantId: 'var-l-ink',
    optionValueIds: {'size-l', 'col-ink'},
    optionLabel: 'L / Ink',
    priceAmount: 2699,
  ),
  ProductVariantOption(
    variantId: 'var-m-sand',
    optionValueIds: {'size-m', 'col-sand'},
    optionLabel: 'M / Sand',
    priceAmount: 2599,
    quantityOnHand: 6,
  ),
];

ProductDetail optionedProduct({Money? price, Money? compareAtPrice}) =>
    baseProduct(
      options: sampleOptions(),
      optionVariants: sampleVariants(),
      price: price,
      compareAtPrice: compareAtPrice,
      stockCount: 4,
    );
