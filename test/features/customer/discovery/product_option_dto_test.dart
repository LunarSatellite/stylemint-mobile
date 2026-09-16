import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_option_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_option.dart';

/// The detail payload of catalog contract §8, abridged.
Map<String, dynamic> _detail({
  List<Map<String, dynamic>>? options,
  List<Map<String, dynamic>>? variants,
}) => <String, dynamic>{
  'id': '5d0c',
  'vendorAccountId': 'a1f2',
  'name': 'Linen shirt',
  'state': 2,
  'options':
      options ??
      [
        {
          'id': '22bb',
          'productId': '5d0c',
          'name': 'Colour',
          'kind': 2,
          'sortOrder': 1,
          'values': [
            {
              'id': 'bb01',
              'productOptionId': '22bb',
              'value': 'Emerald',
              'sortOrder': 0,
              'swatchHex': '#0F7B5A',
            },
          ],
        },
        {
          'id': '11aa',
          'productId': '5d0c',
          'name': 'Size',
          'kind': 1,
          'sortOrder': 0,
          'values': [
            {
              'id': 'aa02',
              'productOptionId': '11aa',
              'value': 'L',
              'sortOrder': 1,
              'swatchHex': null,
            },
            {
              'id': 'aa01',
              'productOptionId': '11aa',
              'value': 'M',
              'sortOrder': 0,
              'swatchHex': null,
            },
          ],
        },
      ],
  'variants':
      variants ??
      [
        {
          'id': 'var-m',
          'sku': 'LINEN-M-EM',
          'isDefault': true,
          'priceAmount': 2499.00,
          'priceCurrency': 'NPR',
          'trackInventory': true,
          'quantityOnHand': 4,
          'optionValueIds': ['aa01', 'bb01'],
          'optionLabel': 'M / Emerald',
        },
        {
          'id': 'var-l',
          'sku': 'LINEN-L-EM',
          'isDefault': false,
          'priceAmount': 2699.00,
          'priceCurrency': 'NPR',
          'trackInventory': true,
          'quantityOnHand': 0,
          'optionValueIds': ['aa02', 'bb01'],
          'optionLabel': 'L / Emerald',
        },
      ],
};

void main() {
  test('parses options ordered by sortOrder, with their values', () {
    final dto = ProductOptionsDto.fromJson(_detail());

    expect(dto.isEmpty, isFalse);
    expect(dto.options.map((o) => o.name), ['Size', 'Colour']);
    expect(dto.options.first.kind, ProductOptionKind.size);
    expect(dto.options.first.isSwatch, isFalse);
    expect(dto.options.first.values.map((v) => v.value), ['M', 'L']);
    expect(dto.options.last.kind, ProductOptionKind.colour);
    expect(dto.options.last.isSwatch, isTrue);
  });

  test('a colour value carries its swatch; other kinds do not', () {
    final dto = ProductOptionsDto.fromJson(_detail());
    final colour = dto.options.last.values.single;
    final size = dto.options.first.values.first;

    expect(colour.swatchHex, '#0F7B5A');
    expect(colour.swatchColor, const Color(0xFF0F7B5A));
    expect(size.swatchHex, isNull);
    expect(size.swatchColor, isNull);
  });

  test('variants carry their option value ids and label', () {
    final dto = ProductOptionsDto.fromJson(_detail());

    final byId = {for (final v in dto.variants) v.variantId: v};
    expect(byId.keys, ['var-m', 'var-l']);
    expect(byId['var-m']!.optionValueIds, {'aa01', 'bb01'});
    expect(byId['var-m']!.optionLabel, 'M / Emerald');
    expect(byId['var-m']!.isDefault, isTrue);
    expect(byId['var-m']!.isBuyable, isTrue);
    expect(byId['var-l']!.optionLabel, 'L / Emerald');
    // trackInventory with nothing on hand.
    expect(byId['var-l']!.isBuyable, isFalse);
  });

  test('untracked inventory is always buyable', () {
    final dto = ProductOptionsDto.fromJson(
      _detail(
        variants: [
          {
            'id': 'var-m',
            'isDefault': true,
            'trackInventory': false,
            'quantityOnHand': 0,
            'optionValueIds': ['aa01', 'bb01'],
          },
        ],
      ),
    );

    expect(dto.variants.single.isBuyable, isTrue);
  });

  test('a product with no options parses to empty, detail still maps', () {
    final json = _detail(
      options: [],
      variants: [
        {
          'id': 'sku-1',
          'sku': 'LINEN',
          'isDefault': true,
          'priceAmount': 2499.00,
          'priceCurrency': 'NPR',
          'quantityOnHand': 3,
        },
      ],
    );

    final dto = ProductOptionsDto.fromJson(json);
    expect(dto.isEmpty, isTrue);
    expect(dto.options, isEmpty);
    expect(dto.variants, isEmpty);

    // The existing product page mapping is untouched.
    final product = ProductDetailDto.fromJson(json).toDomain();
    expect(product.defaultVariantId, 'sku-1');
    expect(product.price.amount, 2499.00);
    expect(product.isInStock, isTrue);
    expect(product.options, isEmpty);
  });

  test('list rows send options: [] and a null optionLabel', () {
    final dto = ProductOptionsDto.fromJson({
      'id': '5d0c',
      'options': <dynamic>[],
      'variants': [
        {'id': 'sku-1', 'isDefault': true, 'optionLabel': null},
      ],
    });

    expect(dto.isEmpty, isTrue);
  });

  test('an unknown option kind falls back to other', () {
    final dto = ProductOptionsDto.fromJson(
      _detail(
        options: [
          {
            'id': '33cc',
            'name': 'Finish',
            'kind': 7,
            'sortOrder': 0,
            'values': [
              {'id': 'cc01', 'value': 'Matte', 'sortOrder': 0},
            ],
          },
        ],
        variants: [
          {
            'id': 'var-1',
            'isDefault': true,
            'optionValueIds': ['cc01'],
          },
        ],
      ),
    );

    expect(dto.options.single.kind, ProductOptionKind.other);
    expect(dto.options.single.isSwatch, isFalse);
  });
}
