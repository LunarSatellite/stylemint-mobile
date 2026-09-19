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
/// ## Scope: all of `lib/`
///
/// This guard used to walk a hand-written list of four "browse journey"
/// directories. That list is how the gap happened: the Buy-It-Again rail
/// lives under `lib/features/customer/orders/presentation`, which was not on
/// it, so an `Image.network` of a product sat there undetected for days. A
/// directory list only ever describes the app as it was on the day someone
/// wrote the list. So the guard now walks **every** `.dart` file under `lib/`
/// and carves out named exemptions, each of which carries its reason below.
///
/// ## Where the line is drawn
///
/// The directive is about **product** imagery, not about image widgets. The
/// app legitimately draws plenty of pictures that are not a product
/// photograph: reel posters and story frames, avatars, brand logos, creator
/// cover strips, campaign and category artwork, collection covers, review
/// photos, return and parcel-seal evidence, and the document captures in
/// vendor KYC and product authoring. Banning `Image.network` everywhere would
/// catch all of those and teach the team to route around the guard.
///
/// So the rule keys on the **subject** of the image rather than the widget:
/// it fires only when the URL is read off a *product* — `product.imageUrl`,
/// `item.thumbnailUrl`, `productImageUrl`, `heroImageUrl` and the rest of
/// [_productPhotoExpression]. `reel.thumbnailUrl`, `campaign.imageUrl`,
/// `category.imageUrl`, `collection.coverImageUrl`, `story.mediaUrl`,
/// `review.images[i]`, `seal.sealPhotoUrl` and a bare local `avatar` / `logo`
/// / `poster` all read as "not a product" and are not exempted anywhere —
/// they simply never match.
///
/// A wardrobe item the buyer already owns (`asset.image` on the lifecycle
/// steward) is deliberately not a product either: it is the buyer's own
/// garment, not a catalogue offer.

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

/// One carve-out from the product-photo rule, with the reason it exists.
///
/// [path] is a file, or a directory when it ends in `/`. Every entry is
/// checked for existence by a test below, so an exemption cannot quietly
/// outlive the code it was written for.
class _Exemption {
  const _Exemption(this.path, this.reason);

  final String path;
  final String reason;

  bool covers(String filePath) =>
      path.endsWith('/') ? filePath.startsWith(path) : filePath == path;
}

/// Every surface allowed to draw a product's photograph, and why.
///
/// Read this list as the answer to "who is looking at this picture, and what
/// are they deciding?". A buyer choosing what to buy gets the Mall's video
/// first tiles. Everyone else — the buyer confirming goods they have already
/// chosen, the seller working their own stock, the creator tagging a reel —
/// is identifying a specific item, and a thumbnail is the honest way to do
/// that.
const List<_Exemption> _productPhotoExemptions = [
  // ---------------------------------------------------------------------
  // 1. The sanctioned place, and the kit that implements it.
  // ---------------------------------------------------------------------
  _Exemption(
    'lib/shared/presentation/mall/mall_product_card.dart',
    'The kit defines MallProductCard, the one product-photo card. Its own '
        'source must render the photo; the guard instead controls where the '
        'card may be built (see the photo-card test).',
  ),
  _Exemption(
    'lib/shared/presentation/mall/mall_spotlight.dart',
    'MallSpotlight is the detail-adjacent counter block and shares '
        'MallProductCard\'s media panel. Same reasoning as the card.',
  ),
  _Exemption(
    'lib/features/customer/discovery/presentation/widgets/product_image_carousel.dart',
    'The product detail gallery. This *is* the sanctioned place — the '
        'directive says product photos live on product detail.',
  ),
  _Exemption(
    'lib/features/customer/discovery/presentation/screens/product_detail_screen.dart',
    'Product detail itself.',
  ),
  _Exemption(
    'lib/features/customer/discovery/presentation/widgets/related_products_rail.dart',
    'The "You may also like" rail belongs to product detail and is built '
        'from MallProductCard by the photo-card allowlist above.',
  ),

  // ---------------------------------------------------------------------
  // 2. Goods the buyer has already chosen — not browse, not discovery.
  //    The decision is already made; the thumbnail answers "is this the
  //    right item?", which is identification, not merchandising.
  // ---------------------------------------------------------------------
  _Exemption(
    'lib/features/customer/cart/presentation/widgets/cart_item_tile.dart',
    'A cart line. The buyer picked this item already; the photo confirms '
        'which variant is in the bag. Not a browse surface. NOTE: this file '
        'is also owned by another agent (branch: the Basket Insights card '
        'work under lib/features/customer/cart/) and was not edited here.',
  ),
  _Exemption(
    'lib/features/customer/checkout/presentation/screens/checkout_screen.dart',
    'Checkout line items — the order being confirmed, not a catalogue.',
  ),
  _Exemption(
    'lib/features/social/group_cart/presentation/widgets/group_cart_item_tile.dart',
    'A shared-cart line. Same reasoning as the cart line above, and the '
        'photo is how a friend tells whose item is whose.',
  ),
  _Exemption(
    'lib/features/customer/orders/presentation/screens/order_detail_screen.dart',
    'Post-purchase. Order line items, parcel-seal photos and delivery '
        'evidence. The buyer is checking goods in hand against what shipped.',
  ),
  _Exemption(
    'lib/features/customer/orders/presentation/widgets/order_care_card.dart',
    'Post-purchase care for an item already delivered.',
  ),
  _Exemption(
    'lib/features/customer/orders/presentation/screens/my_returns_screen.dart',
    'A return is raised against one specific delivered item; the photo is '
        'how the buyer picks the right one. Post-purchase, not discovery.',
  ),
  _Exemption(
    'lib/features/customer/orders/presentation/screens/return_detail_screen.dart',
    'The returned item plus the buyer\'s own evidence photos.',
  ),
  _Exemption(
    'lib/features/vendor/orders/presentation/screens/vendor_order_detail_screen.dart',
    'The seller fulfilling one order, matching line items to stock.',
  ),

  // ---------------------------------------------------------------------
  // 3. Non-buyer surfaces. The seller studio and the creator studio ship in
  //    the same binary but are not the Mall: nobody is shopping there. A
  //    seller scanning their own catalogue and a creator tagging products
  //    onto a reel both need to recognise a specific SKU at a glance, and
  //    a typographic tile of a product they did not name is no help.
  //
  //    These are role-scoped, not feature-scoped: they cover the whole of
  //    the two studios because the *reason* covers the whole of the two
  //    studios. Nothing a buyer sees is inside them.
  // ---------------------------------------------------------------------
  _Exemption(
    'lib/features/vendor/',
    'The seller studio: inventory, analytics, in-store codes, product '
        'authoring and KYC capture. The seller is managing their own goods, '
        'not browsing a catalogue. The video-first directive governs the '
        'buyer\'s Mall.',
  ),
  _Exemption(
    'lib/features/creator/',
    'The creator studio: reel import, product tagging, partnership and '
        'analytics screens. A creator picking which product a reel sells is '
        'authoring, not shopping, and needs to identify the exact item.',
  ),
];

/// Reads the URL of a **product's** photograph.
///
/// Deliberately keyed on the receiver: a product, a line item, a variant or
/// a SKU. `reel.`, `campaign.`, `category.`, `collection.`, `story.`,
/// `review.`, `post.`, `session.`, `asset.`, `brand.`, `creator.` and bare
/// locals (`avatar`, `logo`, `cover`, `poster`, `url`) are not products and
/// never match, so none of them needs an exemption.
final RegExp _productPhotoExpression = RegExp(
  r'(?:\b(?:product|products\[[^\]]*\]|item|items\[[^\]]*\]|p|variant|sku|'
  r'listing|widget\.product|r\.product)\s*[?!]?\s*\.\s*'
  r'(?:imageUrl|imageUrls|heroImageUrl|thumbnailUrl|images)\b)'
  r'|\bproductImageUrl\b'
  // Bare `heroImageUrl`, carried over from the original guard. On a render
  // line it has only ever meant a product; `MallCampaignVm.imageUrl` and the
  // delivery-story chapter also hold a field of this name, which is why the
  // hand-off check below uses the receiver-qualified form instead.
  r'|\bheroImageUrl\b',
);

/// The same subject test, minus the bare `heroImageUrl` alternative.
///
/// Hand-off sites are named arguments, and `imageUrl: heroImageUrl` is how a
/// *campaign* hero is mapped into `MallCampaignVm` — artwork, not a product.
/// A product's hero still matches through the `product.` receiver.
final RegExp _productPhotoHandOff = RegExp(
  r'(?:\b(?:product|products\[[^\]]*\]|item|items\[[^\]]*\]|p|variant|sku|'
  r'listing|widget\.product|r\.product)\s*[?!]?\s*\.\s*'
  r'(?:imageUrl|imageUrls|heroImageUrl|thumbnailUrl|images)\b)'
  r'|\bproductImageUrl\b',
);

/// The widgets that put pixels on screen from a URL.
const List<String> _imageWidgets = [
  'MallNetworkImage(',
  'CachedNetworkImage(',
  'Image.network(',
  'NetworkImage(',
];

/// Named arguments that mean "draw this picture". A product photo handed to
/// another widget through one of these is the same violation one indirection
/// away — that is how `ReelRailProductTile(imageUrl: product.imageUrl)` drew
/// a product photo over a reel without tripping the old render-site check.
final RegExp _imageArgument = RegExp(
  r'\b(?:imageUrl|imageUrls|url|posterUrl|photoUrl|thumbnailUrl)\s*:',
);

Iterable<File> _dartFilesUnder(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _posix(String path) => path.replaceAll(r'\', '/');

bool _isExempt(String path) =>
    _productPhotoExemptions.any((e) => e.covers(path));

/// Generated code and the data/domain layers are out of scope: a DTO field
/// named `imageUrl` carries the value, it does not draw it. The directive is
/// about what is rendered.
bool _isPresentation(String path) =>
    !path.endsWith('.g.dart') &&
    !path.endsWith('.freezed.dart') &&
    (path.contains('/presentation/') || path.contains('/presentation.dart'));

/// Strips `//` comments so a line explaining the rule cannot trip it.
String _code(String line) {
  final slash = line.indexOf('//');
  return slash == -1 ? line : line.substring(0, slash);
}

/// `MallProductVm` carries `imageUrl` on purpose — product detail reads it.
/// Mapping a domain product into the view model is not drawing a photo.
bool _isViewModelMapping(List<String> lines, int index) {
  final indent = lines[index].length - lines[index].trimLeft().length;
  for (var i = index - 1; i >= 0 && i > index - 40; i--) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;
    final lineIndent = line.length - line.trimLeft().length;
    if (lineIndent < indent) {
      return line.contains('MallProductVm(') ||
          line.contains('MallProductVm.') ||
          line.contains('copyWith(');
    }
  }
  return false;
}

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

  test('no surface in lib/ renders a product image url', () {
    final offenders = <String>[];
    for (final file in _dartFilesUnder('lib')) {
      final path = _posix(file.path);
      if (!_isPresentation(path) || _isExempt(path)) continue;
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = _code(lines[i]);
        final rendersImage = _imageWidgets.any(line.contains);
        // The same statement, or the two argument lines after it.
        final window = [
          line,
          if (i + 1 < lines.length) _code(lines[i + 1]),
          if (i + 2 < lines.length) _code(lines[i + 2]),
        ].join(' ');
        if (rendersImage && _productPhotoExpression.hasMatch(window)) {
          offenders.add('$path:${i + 1}');
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

  test('no surface in lib/ hands a product image url to another widget', () {
    final offenders = <String>[];
    for (final file in _dartFilesUnder('lib')) {
      final path = _posix(file.path);
      if (!_isPresentation(path) || _isExempt(path)) continue;
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = _code(lines[i]);
        if (!_imageArgument.hasMatch(line)) continue;
        if (!_productPhotoHandOff.hasMatch(line)) continue;
        if (_isViewModelMapping(lines, i)) continue;
        offenders.add('$path:${i + 1}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A product photograph passed to a widget to draw. Wrapping the '
          'render in another widget does not change the directive: use '
          'MallTypeGround, MallProductTile or MallResultRow.',
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

  test('every exemption names a path that still exists and gives a reason', () {
    final stale = <String>[];
    for (final exemption in _productPhotoExemptions) {
      final exists = exemption.path.endsWith('/')
          ? Directory(exemption.path).existsSync()
          : File(exemption.path).existsSync();
      if (!exists) stale.add('${exemption.path} (no such file or directory)');
      if (exemption.reason.trim().length < 20) {
        stale.add('${exemption.path} (no reason given)');
      }
    }
    for (final path in _photoCardAllowlist) {
      if (!File(path).existsSync()) stale.add('$path (no such file)');
    }

    expect(
      stale,
      isEmpty,
      reason:
          'An exemption outlived the code it was written for. Delete it — a '
          'stale carve-out is how the rule gets widened by accident.',
    );
  });
}
