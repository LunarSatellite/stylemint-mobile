import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/size_chart.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/measurement_rules.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/size_variant_matcher.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

SizeChart _chart(
  GarmentType type,
  List<SizeChartRow> rows, {
  MeasurementUnit unit = MeasurementUnit.cm,
  String? note,
}) => SizeChart(garmentType: type, unit: unit, rows: rows, fitNote: note);

SizeChartRow _row(String label, [Map<SizeMeasure, double> v = const {}]) =>
    SizeChartRow(sizeLabel: label, values: v);

void main() {
  group('SizeChartRules.validate', () {
    test('a complete top chart passes', () {
      final c = _chart(GarmentType.top, [
        _row('S', {SizeMeasure.chest: 90}),
        _row('M', {SizeMeasure.chest: 96}),
      ]);
      expect(SizeChartRules.validate(c), isEmpty);
    });

    test('rows 1..20', () {
      expect(
        SizeChartRules.validate(_chart(GarmentType.accessory, [])),
        isNotEmpty,
      );
      final many = [for (var i = 0; i < 21; i++) _row('S$i')];
      expect(
        SizeChartRules.validate(
          _chart(GarmentType.accessory, many),
        ).map((e) => e.message),
        contains('A size chart can have at most 20 sizes.'),
      );
    });

    test('labels: required, ≤16 chars, unique case-insensitively', () {
      final issues = SizeChartRules.validate(
        _chart(GarmentType.accessory, [
          _row(''),
          _row('x' * 17),
          _row('M'),
          _row(' m '),
        ]),
      );
      expect(issues.map((e) => e.row), [0, 1, 3]);
      expect(issues.last.message, contains('listed twice'));
    });

    test('required measurements per garment type', () {
      List<SizeMeasure?> missing(GarmentType t) => SizeChartRules.validate(
        _chart(t, [_row('M')]),
      ).map((e) => e.measure).toList();
      expect(missing(GarmentType.top), [SizeMeasure.chest]);
      expect(missing(GarmentType.outerwear), [SizeMeasure.chest]);
      expect(missing(GarmentType.bottom), [SizeMeasure.waist]);
      expect(missing(GarmentType.dress), [
        SizeMeasure.chest,
        SizeMeasure.waist,
      ]);
      expect(
        missing(GarmentType.fullBody),
        [SizeMeasure.chest, SizeMeasure.waist],
      );
      expect(missing(GarmentType.footwear), [SizeMeasure.footLength]);
      expect(missing(GarmentType.accessory), isEmpty);
    });

    test('values > 0 and ≤ 300 cm / 120 inch', () {
      expect(
        SizeChartRules.validate(
          _chart(GarmentType.top, [
            _row('M', {SizeMeasure.chest: 301}),
          ]),
        ),
        hasLength(1),
      );
      expect(
        SizeChartRules.validate(
          _chart(GarmentType.top, [
            _row('M', {SizeMeasure.chest: 121}),
          ], unit: MeasurementUnit.inch),
        ),
        hasLength(1),
      );
      expect(
        SizeChartRules.validate(
          _chart(GarmentType.top, [
            _row('M', {SizeMeasure.chest: 0}),
          ]),
        ),
        hasLength(1),
      );
      expect(
        SizeChartRules.validate(
          _chart(GarmentType.top, [
            _row('M', {SizeMeasure.chest: 120}),
          ], unit: MeasurementUnit.inch),
        ),
        isEmpty,
      );
    });

    test('fit note ≤ 300', () {
      final c = _chart(
        GarmentType.accessory,
        [_row('One size')],
        note: 'x' * 301,
      );
      expect(SizeChartRules.validate(c), hasLength(1));
    });

    test('bottoms get advice, not a block, without hips/inseam', () {
      final c = _chart(GarmentType.bottom, [
        _row('30', {SizeMeasure.waist: 76}),
      ]);
      expect(SizeChartRules.validate(c), isEmpty);
      expect(SizeChartRules.recommendations(c), hasLength(1));
    });
  });

  test('MeasurementRules ranges', () {
    expect(MeasurementRules.validate({BodyField.height: 170}), isEmpty);
    final e = MeasurementRules.validate({
      BodyField.height: null,
      BodyField.weight: 10,
      BodyField.chest: 300,
      BodyField.footLength: 50,
    });
    expect(e.keys, {
      BodyField.height,
      BodyField.weight,
      BodyField.chest,
      BodyField.footLength,
    });
  });

  test('inch/cm conversion', () {
    expect(inchToCm(10), closeTo(25.4, 1e-9));
    expect(cmToInch(25.4), closeTo(10, 1e-9));
  });

  group('TryOnImageRules.inspect', () {
    Uint8List png({required int w, required int h, required int colorType}) {
      final b = Uint8List(33);
      b.setAll(0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      b.setAll(8, [0, 0, 0, 13]);
      b.setAll(12, 'IHDR'.codeUnits);
      b.setAll(16, [w >> 24, (w >> 16) & 255, (w >> 8) & 255, w & 255]);
      b.setAll(20, [h >> 24, (h >> 16) & 255, (h >> 8) & 255, h & 255]);
      b[24] = 8;
      b[25] = colorType;
      return b;
    }

    test('RGBA PNG of 800x1000 passes', () {
      final c = TryOnImageRules.inspect(png(w: 800, h: 1000, colorType: 6));
      expect(c.ok, isTrue);
      expect(c.format, TryOnImageFormat.png);
      expect((c.width, c.height, c.hasAlpha), (800, 1000, true));
    });

    test('RGB PNG has no transparency', () {
      final c = TryOnImageRules.inspect(png(w: 800, h: 1000, colorType: 2));
      expect(c.hasAlpha, isFalse);
      expect(c.problems.single, contains('no transparency'));
    });

    test('too small and too big', () {
      final c = TryOnImageRules.inspect(
        png(w: 500, h: 1000, colorType: 6),
        fileSize: 6 * 1024 * 1024,
      );
      expect(c.problems, hasLength(2));
    });

    test('JPEG is refused', () {
      final c = TryOnImageRules.inspect(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(40, 0)]),
      );
      expect(c.format, TryOnImageFormat.other);
      expect(c.ok, isFalse);
    });

    test('WebP VP8X with the alpha flag', () {
      final b = Uint8List(30);
      b.setAll(0, 'RIFF'.codeUnits);
      b.setAll(8, 'WEBP'.codeUnits);
      b.setAll(12, 'VP8X'.codeUnits);
      b[20] = 0x10;
      // width-1 = 799, height-1 = 999 (24-bit little endian)
      b.setAll(24, [799 & 255, 799 >> 8, 0, 999 & 255, 999 >> 8, 0]);
      final c = TryOnImageRules.inspect(b);
      expect(
        (c.format, c.width, c.height, c.hasAlpha),
        (TryOnImageFormat.webp, 800, 1000, true),
      );
      expect(c.ok, isTrue);
    });

    test('transparent share bounds', () {
      Uint8List rgba(int transparent, int total) {
        final b = Uint8List(total * 4);
        for (var i = 0; i < total; i++) {
          b[i * 4 + 3] = i < transparent ? 0 : 255;
        }
        return b;
      }

      expect(TryOnImageRules.transparentShare(rgba(50, 100)), 0.5);
      expect(TryOnImageRules.transparencyProblem(0.5), isNull);
      expect(TryOnImageRules.transparencyProblem(0.1), isNotNull);
      expect(TryOnImageRules.transparencyProblem(0.99), isNotNull);
    });
  });

  test('isSizedApparel', () {
    expect(isSizedApparel(categoryName: "Men's T-Shirts"), isTrue);
    expect(isSizedApparel(categoryName: 'Footwear'), isTrue);
    expect(isSizedApparel(categoryName: 'Dresses'), isTrue);
    expect(
      isSizedApparel(categoryName: 'Electronics', productName: 'Laptop'),
      isFalse,
    );
    expect(isSizedApparel(), isFalse);
  });

  group('variantIdForSize', () {
    ProductDetail product({
      List<ProductOption> options = const [],
      List<ProductVariantOption> variants = const [],
      List<ProductVariant> legacy = const [],
    }) => ProductDetail(
      id: 'p',
      name: 'Tee',
      description: '',
      images: const [],
      price: const Money(amount: 100, currency: 'NPR'),
      rating: 0,
      reviewCount: 0,
      vendorId: 'v',
      vendorName: 'V',
      vendorAvatarUrl: '',
      isInStock: true,
      variants: legacy,
      specifications: const {},
      shippingInfo: '',
      isSaved: false,
      isInCart: false,
      options: options,
      optionVariants: variants,
    );

    const sizes = ProductOption(
      id: 'size',
      name: 'Size',
      kind: ProductOptionKind.size,
      values: [
        ProductOptionValue(id: 's', value: 'S'),
        ProductOptionValue(id: 'm', value: 'M'),
      ],
    );

    test('matches the size option, preferring the kept colour and stock', () {
      final p = product(
        options: const [sizes],
        variants: const [
          ProductVariantOption(variantId: 'v-s', optionValueIds: {'s', 'red'}),
          ProductVariantOption(
            variantId: 'v-m-red-out',
            optionValueIds: {'m', 'red'},
          ),
          ProductVariantOption(
            variantId: 'v-m-blue',
            optionValueIds: {'m', 'blue'},
            quantityOnHand: 3,
          ),
          ProductVariantOption(
            variantId: 'v-m-red',
            optionValueIds: {'m', 'red'},
            quantityOnHand: 2,
          ),
        ],
      );
      expect(variantIdForSize(p, ' m ', keepValueIds: {'red'}), 'v-m-red');
      expect(variantIdForSize(p, 'M'), 'v-m-blue');
      expect(variantIdForSize(p, 'XL'), isNull);
    });

    test('falls back to legacy SKU chips', () {
      final p = product(
        legacy: const [
          ProductVariant(
            id: 'g',
            name: 'Size',
            values: ['S', 'M'],
            type: 'sku',
            optionVariantIds: {'S': 'sku-s', 'M': 'sku-m'},
          ),
        ],
      );
      expect(variantIdForSize(p, 'm'), 'sku-m');
    });
  });
}
