import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_option_chooser.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import 'product_option_fixtures.dart';

void main() {
  group('preselect', () {
    test("opens on the default variant's values", () {
      final chooser = ProductOptionChooser.forProduct(optionedProduct());

      expect(chooser.value.picked, {
        'opt-size': 'size-m',
        'opt-colour': 'col-emerald',
      });
      expect(chooser.value.isComplete, isTrue);
      expect(chooser.value.resolvedVariant?.variantId, 'var-m-emerald');
      expect(chooser.value.unavailableReason, isNull);
    });

    test('a product with no options selects nothing and changes nothing', () {
      final product = plainProduct();
      final chooser = ProductOptionChooser.forProduct(product);

      expect(chooser.value.isEmpty, isTrue);
      final applied = chooser.value.applyTo(product);
      expect(applied.price.amount, product.price.amount);
      expect(applied.isInStock, product.isInStock);
      expect(applied.stockCount, product.stockCount);
      expect(applied.defaultVariantId, product.defaultVariantId);
    });
  });

  group('selection', () {
    test('resolves the variant carrying every picked value', () {
      final chooser = ProductOptionChooser.forProduct(optionedProduct())
        ..select('opt-size', 'size-l');

      expect(chooser.value.resolvedVariant?.variantId, 'var-l-emerald');
      expect(chooser.value.resolvedVariant?.optionLabel, 'L / Emerald');
    });

    test('price, stock and the cart variant follow the picked variant', () {
      final product = optionedProduct();
      final chooser = ProductOptionChooser.forProduct(product)
        ..select('opt-size', 'size-l');

      final chosen = chooser.value.applyTo(product);
      expect(chosen.price, const Money(amount: 2699, currency: 'NPR'));
      expect(chosen.defaultVariantId, 'var-l-emerald');
      expect(chosen.isInStock, isTrue);
      expect(chosen.stockCount, 2);
      // A flash-sale compare-at price belongs to the default variant only.
      expect(chosen.compareAtPrice, isNull);
    });

    test('notifies once per real change', () {
      final chooser = ProductOptionChooser.forProduct(optionedProduct());
      var notifications = 0;
      chooser
        ..addListener(() => notifications++)
        ..select('opt-size', 'size-l')
        ..select('opt-size', 'size-l');

      expect(notifications, 1);
    });
  });

  group('availability', () {
    test('a combination no variant sells is unavailable', () {
      final chooser = ProductOptionChooser.forProduct(optionedProduct())
        ..select('opt-colour', 'col-sand');

      // Sand is sold in M only.
      expect(
        chooser.value.availabilityOf('opt-size', 'size-l'),
        OptionValueAvailability.unavailable,
      );
      expect(
        chooser.value.availabilityOf('opt-size', 'size-l').reason,
        'Not available',
      );
      expect(
        chooser.value.availabilityOf('opt-size', 'size-l').isSelectable,
        isFalse,
      );
    });

    test('a variant with no stock left reads as out of stock', () {
      final chooser = ProductOptionChooser.forProduct(optionedProduct())
        ..select('opt-colour', 'col-ink');

      expect(
        chooser.value.availabilityOf('opt-size', 'size-l'),
        OptionValueAvailability.outOfStock,
      );
      expect(
        chooser.value.availabilityOf('opt-size', 'size-l').reason,
        'Out of stock',
      );
    });

    test('picking an out-of-stock combination blocks add to cart', () {
      final product = optionedProduct();
      final chooser = ProductOptionChooser.forProduct(product)
        ..select('opt-colour', 'col-ink')
        ..select('opt-size', 'size-l');

      expect(chooser.value.resolvedVariant?.variantId, 'var-l-ink');
      expect(
        chooser.value.unavailableReason,
        'This combination is out of stock',
      );
      expect(chooser.value.applyTo(product).isInStock, isFalse);
    });

    test('an unsold combination blocks add to cart with a reason', () {
      final product = optionedProduct();
      final chooser = ProductOptionChooser.forProduct(product)
        ..select('opt-colour', 'col-sand')
        ..select('opt-size', 'size-l');

      expect(chooser.value.resolvedVariant, isNull);
      expect(
        chooser.value.unavailableReason,
        'This combination is not available',
      );
      final chosen = chooser.value.applyTo(product);
      expect(chosen.isInStock, isFalse);
    });

    test('the picked value itself stays selectable', () {
      final chooser = ProductOptionChooser.forProduct(optionedProduct());

      expect(
        chooser.value.availabilityOf('opt-size', 'size-m'),
        OptionValueAvailability.available,
      );
    });
  });

  test('a sale price survives on the default variant', () {
    final product = optionedProduct(
      price: const Money(amount: 1999, currency: 'NPR'),
      compareAtPrice: const Money(amount: 2499, currency: 'NPR'),
    );
    final chooser = ProductOptionChooser.forProduct(product);

    final chosen = chooser.value.applyTo(product);
    expect(chosen.price.amount, 1999);
    expect(chosen.compareAtPrice?.amount, 2499);
  });
}

ProductDetail plainProduct() =>
    baseProduct(defaultVariantId: 'sku-1', stockCount: 5);
