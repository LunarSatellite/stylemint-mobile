import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Product photos appear on the product detail page and nowhere else.**
/// Owner directive, 2026-09-16; the Mall kit's README states the same rule.
///
/// Photos re-entered the browse journey twice before this guard existed:
/// once through a `photoCards` flag on the Mall home's rails that every call
/// site set to true, and once through screens that reached for
/// `MallNetworkImage(url: product.imageUrl)` directly. A widget test catches
/// one screen at a time; this reads the tree, so a new screen cannot slip a
/// photo in unnoticed.
///
/// The two photo-bearing widgets are `MallProductCard` and its saved-list
/// wrapper `SaveableMallProductCard`. They may be built only on product
/// detail and the rails that belong to it.
const Set<String> _photoCardAllowlist = {
  // The kit itself.
  'lib/shared/presentation/mall/mall_product_card.dart',
  'lib/shared/presentation/mall/mall_product_grid.dart',
  'lib/shared/presentation/mall/mall_tile_text.dart',
  'lib/shared/presentation/mall/mall_spotlight.dart',
  'lib/shared/presentation/mall/sm_skeleton.dart',
  // The wrapper's own definition.
  'lib/features/customer/saved_items/presentation/widgets/saveable_product_card.dart',
  // Product detail, and the "You may also like" rail that belongs to it.
  'lib/features/customer/discovery/presentation/screens/product_detail_screen.dart',
  'lib/features/customer/discovery/presentation/widgets/related_products_rail.dart',
};

/// Screens that legitimately draw a product's own photograph.
const Set<String> _productImageAllowlist = {
  'lib/features/customer/discovery/presentation/widgets/product_image_carousel.dart',
};

/// The browse and discovery journey: the surfaces this guard exists for.
const List<String> _browseJourney = [
  'lib/features/customer/discovery/presentation',
  'lib/features/customer/mall_home/presentation',
  'lib/features/customer/storefront/presentation',
  'lib/features/customer/brand_storefront/presentation',
];

Iterable<File> _dartFilesUnder(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _posix(String path) => path.replaceAll(r'\', '/');

void main() {
  test('the photo card is built only on product detail and its rails', () {
    final offenders = <String>[];
    for (final file in _dartFilesUnder('lib')) {
      final path = _posix(file.path);
      if (_photoCardAllowlist.contains(path)) continue;
      final source = file.readAsStringSync();
      for (final widget in const [
        'MallProductCard(',
        'SaveableMallProductCard(',
      ]) {
        if (source.contains(widget)) offenders.add('$path builds $widget');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'The Mall is video-first: build MallProductTile (or MallResultRow '
          'in a list) instead. Product photos belong to the product details '
          'page — owner directive, 2026-09-16.',
    );
  });

  test('no browse surface renders a product image url', () {
    final offenders = <String>[];
    for (final root in _browseJourney) {
      for (final file in _dartFilesUnder(root)) {
        final path = _posix(file.path);
        if (_productImageAllowlist.contains(path)) continue;
        final lines = file.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final rendersImage =
              line.contains('MallNetworkImage(') ||
              line.contains('CachedNetworkImage(') ||
              line.contains('Image.network(');
          // The same statement, or the argument line right after it.
          final window = [
            line,
            if (i + 1 < lines.length) lines[i + 1],
          ].join(' ');
          if (rendersImage &&
              (window.contains('product.imageUrl') ||
                  window.contains('heroImageUrl') ||
                  window.contains('product.heroImageUrl'))) {
            offenders.add('$path:${i + 1}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A product photograph outside product detail. Use MallTypeGround, '
          'MallProductTile or MallResultRow.',
    );
  });

  test('the Mall home rails carry no photo-card escape hatch', () {
    final source = File(
      'lib/features/customer/mall_home/presentation/widgets/mall_home_section.dart',
    ).readAsStringSync();

    // `photoCards: true` on every call site is how the directive was undone
    // the first time. The flag is gone; it must not come back as a default.
    expect(source.contains('photoCards'), isFalse);
  });
}
