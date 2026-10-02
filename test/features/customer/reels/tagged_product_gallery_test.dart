import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

TaggedProductEntity _product({
  String imageUrl = '',
  List<String> imageUrls = const <String>[],
}) => TaggedProductEntity(
  id: 'product-1',
  name: 'Linen shirt',
  imageUrl: imageUrl,
  imageUrls: imageUrls,
  price: const Money(amount: 1200, currency: 'NPR'),
  quantity: 1,
);

/// The tagged-product card cycles `gallery()`. It reconciles two fields
/// because the server sends both: `imageUrls` (the whole set, added for this)
/// and `imageUrl` (the lead picture, which older builds and the snapshot-only
/// path still send on its own).
void main() {
  group('TaggedProductEntity.gallery', () {
    test('returns every uploaded image in the order given', () {
      final product = _product(
        imageUrl: 'https://cdn/a.jpg',
        imageUrls: const [
          'https://cdn/a.jpg',
          'https://cdn/b.jpg',
          'https://cdn/c.jpg',
        ],
      );
      expect(product.gallery(), [
        'https://cdn/a.jpg',
        'https://cdn/b.jpg',
        'https://cdn/c.jpg',
      ]);
    });

    test('does not duplicate the lead image into the set', () {
      // imageUrl is imageUrls.first, so adding it again would show the first
      // photo twice per cycle.
      final product = _product(
        imageUrl: 'https://cdn/a.jpg',
        imageUrls: const ['https://cdn/a.jpg', 'https://cdn/b.jpg'],
      );
      expect(product.gallery(), hasLength(2));
    });

    test('falls back to the lead image when the set is absent', () {
      // A server that predates imageUrls, so the card still shows a photo
      // rather than the typographic ground.
      final product = _product(imageUrl: 'https://cdn/only.jpg');
      expect(product.gallery(), ['https://cdn/only.jpg']);
    });

    test('is empty when the product has no photo at all', () {
      expect(_product().gallery(), isEmpty);
    });

    test('drops blank entries so isEmpty means "no photo"', () {
      final product = _product(imageUrls: const ['', '   ']);
      expect(product.gallery(), isEmpty);
    });

    test('ignores a blank lead image', () {
      final product = _product(imageUrl: '   ');
      expect(product.gallery(), isEmpty);
    });

    test('is unmodifiable, so a caller cannot reorder the shared entity', () {
      final gallery = _product(imageUrl: 'https://cdn/a.jpg').gallery();
      expect(() => gallery.add('https://cdn/x.jpg'), throwsUnsupportedError);
    });
  });
}
