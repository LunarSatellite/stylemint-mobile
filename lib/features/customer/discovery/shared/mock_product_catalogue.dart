import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Static product catalogue — matches every product ID used in [kMockReels].
/// Both the mock discovery repository (PDP) and mock cart repository (item
/// lookup) share this map so the same data appears end-to-end.
const _shipping = 'Free shipping on orders over Rs 1,500. Standard delivery 3–5 days.';

const kMockProductCatalogue = <String, ProductDetail>{
  // ── Skincare ─────────────────────────────────────────────────────────────
  'p_sk01': ProductDetail(
    id: 'p_sk01',
    name: 'Hydra Boost Serum',
    description:
        'A lightweight, fast-absorbing serum infused with hyaluronic acid and '
        'niacinamide. Deeply hydrates, plumps fine lines, and strengthens the '
        'skin barrier — perfect for dry skin in winter.',
    images: [
      'https://picsum.photos/seed/serum01/600/600',
      'https://picsum.photos/seed/serum01b/600/600',
      'https://picsum.photos/seed/serum01c/600/600',
    ],
    price: Money(amount: 1299, currency: 'NPR'),
    compareAtPrice: Money(amount: 1599, currency: 'NPR'),
    rating: 4.7,
    reviewCount: 218,
    soldCount: 1042,
    vendorId: 'v_glow',
    vendorName: 'Glow Lab Nepal',
    vendorAvatarUrl: 'https://picsum.photos/seed/glowlab/80/80',
    isInStock: true,
    stockCount: 12,
    variants: [
      ProductVariant(id: 'pv_sk01_a', name: 'Size', values: ['30 ml', '50 ml', '100 ml'], type: 'size'),
    ],
    specifications: {
      'Volume': '30 ml',
      'Key Ingredient': 'Hyaluronic Acid, Niacinamide',
      'Skin Type': 'All / Dry',
      'Cruelty Free': 'Yes',
    },
    shippingInfo: _shipping,
    isSaved: false,
    isInCart: false,
  ),

  'p_sk02': ProductDetail(
    id: 'p_sk02',
    name: 'Vitamin C Moisturiser',
    description:
        'Brightening day moisturiser with 10% pure Vitamin C and SPF 20. '
        'Fades dark spots, evens skin tone and protects against UV damage — '
        'your morning routine in one step.',
    images: [
      'https://picsum.photos/seed/moisturiser01/600/600',
      'https://picsum.photos/seed/moisturiser01b/600/600',
    ],
    price: Money(amount: 899, currency: 'NPR'),
    compareAtPrice: Money(amount: 1100, currency: 'NPR'),
    rating: 4.5,
    reviewCount: 134,
    soldCount: 763,
    vendorId: 'v_glow',
    vendorName: 'Glow Lab Nepal',
    vendorAvatarUrl: 'https://picsum.photos/seed/glowlab/80/80',
    isInStock: true,
    stockCount: 5,
    variants: [
      ProductVariant(id: 'pv_sk02_a', name: 'Size', values: ['50 ml', '100 ml'], type: 'size'),
    ],
    specifications: {
      'Volume': '50 ml',
      'Vitamin C': '10%',
      'SPF': '20',
      'Skin Type': 'Normal / Combination',
    },
    shippingInfo: _shipping,
    isSaved: false,
    isInCart: false,
  ),

  // ── Fashion ───────────────────────────────────────────────────────────────
  'p_fa01': ProductDetail(
    id: 'p_fa01',
    name: 'Linen Blazer – Cream',
    description:
        'Effortlessly chic unstructured blazer crafted from 100% natural '
        'linen. Oversized silhouette, notched lapels, two patch pockets. '
        'Breathable enough for long days, polished enough for any occasion.',
    images: [
      'https://picsum.photos/seed/blazer01/600/600',
      'https://picsum.photos/seed/blazer01b/600/600',
      'https://picsum.photos/seed/blazer01c/600/600',
    ],
    price: Money(amount: 2499, currency: 'NPR'),
    compareAtPrice: Money(amount: 3200, currency: 'NPR'),
    rating: 4.8,
    reviewCount: 89,
    soldCount: 312,
    vendorId: 'v_moda',
    vendorName: 'Moda Collective',
    vendorAvatarUrl: 'https://picsum.photos/seed/modacol/80/80',
    isInStock: true,
    stockCount: 8,
    variants: [
      ProductVariant(id: 'pv_fa01_a', name: 'Size', values: ['XS', 'S', 'M', 'L', 'XL'], type: 'size'),
      ProductVariant(id: 'pv_fa01_b', name: 'Color', values: ['Cream', 'Sand', 'White'], type: 'color'),
    ],
    specifications: {
      'Material': '100% Linen',
      'Fit': 'Oversized',
      'Care': 'Hand wash / Dry clean',
      'Origin': 'Made in Nepal',
    },
    shippingInfo: _shipping,
    isSaved: true,
    isInCart: false,
  ),

  // ── Fitness ───────────────────────────────────────────────────────────────
  'p_fi01': ProductDetail(
    id: 'p_fi01',
    name: 'Performance Dry-Fit Tee',
    description:
        'Ultra-lightweight moisture-wicking tee engineered for high-intensity '
        'workouts. Anti-odour finish, flat-lock seams to prevent chafing, '
        'and a 4-way stretch fabric that moves with you.',
    images: [
      'https://picsum.photos/seed/tee01/600/600',
      'https://picsum.photos/seed/tee01b/600/600',
    ],
    price: Money(amount: 799, currency: 'NPR'),
    rating: 4.6,
    reviewCount: 201,
    soldCount: 1870,
    vendorId: 'v_flex',
    vendorName: 'FlexWear Nepal',
    vendorAvatarUrl: 'https://picsum.photos/seed/flexwear/80/80',
    isInStock: true,
    stockCount: 20,
    variants: [
      ProductVariant(id: 'pv_fi01_a', name: 'Size', values: ['S', 'M', 'L', 'XL', 'XXL'], type: 'size'),
      ProductVariant(id: 'pv_fi01_b', name: 'Color', values: ['Black', 'White', 'Navy', 'Red'], type: 'color'),
    ],
    specifications: {
      'Material': '92% Polyester, 8% Spandex',
      'Technology': 'Dry-Fit, Anti-Odour',
      'Fit': 'Regular',
    },
    shippingInfo: _shipping,
    isSaved: false,
    isInCart: false,
  ),

  'p_fi02': ProductDetail(
    id: 'p_fi02',
    name: 'Flex Shorts – Black',
    description:
        'Training shorts with a 7-inch inseam, built-in compression liner '
        'and zippered pocket. Lightweight and sweat-wicking — from the gym '
        'to the track without missing a beat.',
    images: [
      'https://picsum.photos/seed/shorts01/600/600',
      'https://picsum.photos/seed/shorts01b/600/600',
    ],
    price: Money(amount: 1099, currency: 'NPR'),
    compareAtPrice: Money(amount: 1299, currency: 'NPR'),
    rating: 4.4,
    reviewCount: 97,
    soldCount: 543,
    vendorId: 'v_flex',
    vendorName: 'FlexWear Nepal',
    vendorAvatarUrl: 'https://picsum.photos/seed/flexwear/80/80',
    isInStock: true,
    stockCount: 14,
    variants: [
      ProductVariant(id: 'pv_fi02_a', name: 'Size', values: ['S', 'M', 'L', 'XL'], type: 'size'),
    ],
    specifications: {
      'Material': '88% Polyester, 12% Spandex',
      'Inseam': '7 inch',
      'Pocket': 'Zippered side pocket',
    },
    shippingInfo: _shipping,
    isSaved: false,
    isInCart: false,
  ),

  // ── Travel / Fashion ─────────────────────────────────────────────────────
  'p_tr01': ProductDetail(
    id: 'p_tr01',
    name: 'Oversized Linen Shirt',
    description:
        'Breezy and versatile, this oversized linen shirt transitions from '
        'beach to brunch. Slightly dropped shoulders, relaxed cuffs, and a '
        'subtle texture that only gets better with each wash.',
    images: [
      'https://picsum.photos/seed/linen01/600/600',
      'https://picsum.photos/seed/linen01b/600/600',
      'https://picsum.photos/seed/linen01c/600/600',
    ],
    price: Money(amount: 1599, currency: 'NPR'),
    rating: 4.6,
    reviewCount: 73,
    soldCount: 289,
    vendorId: 'v_moda',
    vendorName: 'Moda Collective',
    vendorAvatarUrl: 'https://picsum.photos/seed/modacol/80/80',
    isInStock: true,
    stockCount: 7,
    variants: [
      ProductVariant(id: 'pv_tr01_a', name: 'Size', values: ['XS', 'S', 'M', 'L', 'XL'], type: 'size'),
      ProductVariant(id: 'pv_tr01_b', name: 'Color', values: ['White', 'Beige', 'Sky Blue'], type: 'color'),
    ],
    specifications: {
      'Material': '100% Linen',
      'Fit': 'Oversized',
      'Care': 'Machine wash cold',
    },
    shippingInfo: _shipping,
    isSaved: true,
    isInCart: false,
  ),

  // ── Street Style ──────────────────────────────────────────────────────────
  'p_ss01': ProductDetail(
    id: 'p_ss01',
    name: 'Cargo Pants – Olive',
    description:
        'Utility-inspired cargo pants with six pockets, adjustable ankle '
        'tabs and a relaxed tapered silhouette. Built from a durable '
        'cotton-twill blend — your all-day streetwear staple.',
    images: [
      'https://picsum.photos/seed/cargo01/600/600',
      'https://picsum.photos/seed/cargo01b/600/600',
    ],
    price: Money(amount: 1899, currency: 'NPR'),
    compareAtPrice: Money(amount: 2299, currency: 'NPR'),
    rating: 4.7,
    reviewCount: 156,
    soldCount: 674,
    vendorId: 'v_street',
    vendorName: 'StreetCo',
    vendorAvatarUrl: 'https://picsum.photos/seed/streetco/80/80',
    isInStock: true,
    stockCount: 9,
    variants: [
      ProductVariant(id: 'pv_ss01_a', name: 'Size', values: ['28', '30', '32', '34', '36'], type: 'size'),
      ProductVariant(id: 'pv_ss01_b', name: 'Color', values: ['Olive', 'Black', 'Khaki'], type: 'color'),
    ],
    specifications: {
      'Material': '65% Cotton, 35% Polyester',
      'Fit': 'Relaxed Tapered',
      'Pockets': '6',
      'Rise': 'Mid-rise',
    },
    shippingInfo: _shipping,
    isSaved: false,
    isInCart: false,
  ),

  'p_ss02': ProductDetail(
    id: 'p_ss02',
    name: 'Graphic Tee – Black',
    description:
        'Heavy-weight 240 GSM cotton tee with a bold screen-printed graphic. '
        'Pre-washed for softness, boxy fit with dropped shoulders — '
        'the kind of tee that anchors any outfit.',
    images: [
      'https://picsum.photos/seed/graphictee01/600/600',
      'https://picsum.photos/seed/graphictee01b/600/600',
    ],
    price: Money(amount: 699, currency: 'NPR'),
    rating: 4.3,
    reviewCount: 312,
    soldCount: 2140,
    vendorId: 'v_street',
    vendorName: 'StreetCo',
    vendorAvatarUrl: 'https://picsum.photos/seed/streetco/80/80',
    isInStock: true,
    stockCount: 25,
    variants: [
      ProductVariant(id: 'pv_ss02_a', name: 'Size', values: ['S', 'M', 'L', 'XL', 'XXL'], type: 'size'),
    ],
    specifications: {
      'Material': '100% Cotton',
      'Weight': '240 GSM',
      'Fit': 'Boxy',
      'Print': 'Screen-printed',
    },
    shippingInfo: _shipping,
    isSaved: false,
    isInCart: false,
  ),

  // ── Tech Accessories ─────────────────────────────────────────────────────
  'p_te01': ProductDetail(
    id: 'p_te01',
    name: 'Magnetic Phone Mount',
    description:
        'Universal magnetic car/desk mount with a 360° adjustable arm. '
        'N52-strength neodymium magnet securely holds any phone up to 350 g — '
        'one-hand mount, zero fumbling.',
    images: [
      'https://picsum.photos/seed/mount01/600/600',
      'https://picsum.photos/seed/mount01b/600/600',
    ],
    price: Money(amount: 499, currency: 'NPR'),
    rating: 4.5,
    reviewCount: 429,
    soldCount: 3280,
    vendorId: 'v_tech',
    vendorName: 'TechNest Nepal',
    vendorAvatarUrl: 'https://picsum.photos/seed/technest/80/80',
    isInStock: true,
    stockCount: 30,
    variants: [],
    specifications: {
      'Magnet': 'N52 Neodymium',
      'Rotation': '360°',
      'Compatibility': 'Universal (up to 350 g)',
      'Mount Type': 'Adhesive / Vent clip',
    },
    shippingInfo: _shipping,
    isSaved: false,
    isInCart: false,
  ),

  // ── Nike ─────────────────────────────────────────────────────────────────
  'p_nk01': ProductDetail(
    id: 'p_nk01',
    name: 'Nike Air Max 270',
    description:
        'The Nike Air Max 270 delivers a bold look with a large Max Air heel '
        'unit — the biggest Air unit yet — for all-day cushioning. '
        'A foam midsole and mesh upper keep the ride lightweight and breathable. '
        'A streetwear icon built for everyday wear.',
    images: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=600&fit=crop&q=80',
      'https://images.unsplash.com/photo-1600269452121-4f2416e55c28?w=600&h=600&fit=crop&q=80',
      'https://images.unsplash.com/photo-1584735175315-9d5df23be2a6?w=600&h=600&fit=crop&q=80',
    ],
    price: Money(amount: 12999, currency: 'NPR'),
    compareAtPrice: Money(amount: 15999, currency: 'NPR'),
    rating: 4.8,
    reviewCount: 1842,
    soldCount: 9340,
    vendorId: 'v_nike',
    vendorName: 'Nike Nepal Official',
    vendorAvatarUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=80&h=80&fit=crop&q=80',
    isInStock: true,
    stockCount: 18,
    variants: [
      ProductVariant(
        id: 'pv_nk01_sz',
        name: 'Size (UK)',
        values: ['6', '7', '8', '9', '10', '11', '12'],
        type: 'size',
      ),
      ProductVariant(
        id: 'pv_nk01_col',
        name: 'Color',
        values: ['Black/White', 'Triple White', 'University Red', 'Volt'],
        type: 'color',
      ),
    ],
    specifications: {
      'Upper': 'Mesh + synthetic overlays',
      'Midsole': 'Foam + Max Air 270 heel unit',
      'Outsole': 'Waffle-pattern rubber',
      'Fit': 'True to size',
      'Closure': 'Lace-up',
      'Country': 'Vietnam',
    },
    shippingInfo: 'Free shipping on all Nike orders. Standard delivery 3–5 days. '
        'Easy 30-day returns on unworn items.',
    isSaved: false,
    isInCart: false,
  ),

  'p_nk02': ProductDetail(
    id: 'p_nk02',
    name: 'Nike Tech Fleece Hoodie',
    description:
        'The Nike Tech Fleece Hoodie blends the warmth of traditional fleece '
        'with a sleek, modern silhouette. A double-knit spacer fabric traps body '
        'heat while keeping the hoodie light and breathable — no bulk, '
        'just clean lines and all-day comfort.',
    images: [
      'https://images.unsplash.com/photo-1556821840-3a63f15732ce?w=600&h=600&fit=crop&q=80',
      'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=600&h=600&fit=crop&q=80',
      'https://images.unsplash.com/photo-1509942774463-acf339cf87d5?w=600&h=600&fit=crop&q=80',
    ],
    price: Money(amount: 9499, currency: 'NPR'),
    compareAtPrice: Money(amount: 11999, currency: 'NPR'),
    rating: 4.9,
    reviewCount: 3210,
    soldCount: 14200,
    vendorId: 'v_nike',
    vendorName: 'Nike Nepal Official',
    vendorAvatarUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=80&h=80&fit=crop&q=80',
    isInStock: true,
    stockCount: 23,
    variants: [
      ProductVariant(
        id: 'pv_nk02_sz',
        name: 'Size',
        values: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
        type: 'size',
      ),
      ProductVariant(
        id: 'pv_nk02_col',
        name: 'Color',
        values: ['Black', 'Dark Grey Heather', 'Navy', 'Cargo Khaki'],
        type: 'color',
      ),
    ],
    specifications: {
      'Material': '66% Cotton, 34% Polyester (spacer fleece)',
      'Fit': 'Slim',
      'Pockets': 'Two zip side pockets + kangaroo pocket',
      'Hood': 'Fitted, no drawcord',
      'Care': 'Machine wash cold, tumble dry low',
      'Country': 'Vietnam',
    },
    shippingInfo: 'Free shipping on all Nike orders. Standard delivery 3–5 days. '
        'Easy 30-day returns on unworn items.',
    isSaved: true,
    isInCart: false,
  ),

  'p_nk03': ProductDetail(
    id: 'p_nk03',
    name: 'Nike Dri-FIT T-Shirt',
    description:
        'The go-to training tee. Nike Dri-FIT technology moves sweat away '
        'from your skin and pushes it to the surface so it can evaporate faster, '
        'keeping you dry and comfortable through every rep. '
        'Classic crew neck, dropped hem, standard fit.',
    images: [
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600&h=600&fit=crop&q=80',
      'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600&h=600&fit=crop&q=80',
      'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=600&h=600&fit=crop&q=80',
    ],
    price: Money(amount: 2499, currency: 'NPR'),
    compareAtPrice: Money(amount: 2999, currency: 'NPR'),
    rating: 4.6,
    reviewCount: 5870,
    soldCount: 38400,
    vendorId: 'v_nike',
    vendorName: 'Nike Nepal Official',
    vendorAvatarUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=80&h=80&fit=crop&q=80',
    isInStock: true,
    stockCount: 60,
    variants: [
      ProductVariant(
        id: 'pv_nk03_sz',
        name: 'Size',
        values: ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'],
        type: 'size',
      ),
      ProductVariant(
        id: 'pv_nk03_col',
        name: 'Color',
        values: ['White', 'Black', 'Dark Grey', 'Navy', 'Royal Blue', 'Red'],
        type: 'color',
      ),
    ],
    specifications: {
      'Material': '100% Polyester (Dri-FIT)',
      'Fit': 'Standard',
      'Neck': 'Crew',
      'Technology': 'Dri-FIT moisture-wicking',
      'Care': 'Machine wash',
      'Country': 'Indonesia',
    },
    shippingInfo: 'Free shipping on all Nike orders. Standard delivery 3–5 days. '
        'Easy 30-day returns on unworn items.',
    isSaved: false,
    isInCart: false,
  ),
};

/// Related products shown at the bottom of a PDP — 3 items from the same
/// catalogue, excluding the current product.
List<RelatedProduct> kRelatedFor(String productId) {
  return kMockProductCatalogue.entries
      .where((e) => e.key != productId)
      .take(3)
      .map((e) => RelatedProduct(
            id: e.value.id,
            name: e.value.name,
            imageUrl: e.value.images.first,
            price: e.value.price,
            rating: e.value.rating,
          ))
      .toList();
}
