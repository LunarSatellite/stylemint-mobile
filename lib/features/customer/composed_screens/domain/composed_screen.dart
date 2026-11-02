import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';

/// The screens the composer can build (`GET v1/customer/screens/{screen}`).
enum ComposedScreenName {
  mallHome('mall_home'),
  productDetail('product_detail'),
  discovery('discovery'),
  cartCrossSell('cart_cross_sell'),
  creatorsForYou('creators_for_you'),
  shopsForYou('shops_for_you'),
  brandsForYou('brands_for_you');

  const ComposedScreenName(this.wire);

  final String wire;

  /// The engagement `surface` for items tapped on this screen.
  String get surface => 'screen:$wire';
}

/// What a section holds. Unknown kinds are dropped while parsing.
enum ComposedSectionKind {
  products('products'),
  reels('reels'),
  creators('creators'),
  vendors('vendors'),
  brands('brands');

  const ComposedSectionKind(this.wire);

  final String wire;

  static ComposedSectionKind? parse(Object? raw) {
    if (raw is! String) return null;
    final value = raw.trim().toLowerCase();
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// One hydrated item: [card] is a [HomeProduct], [HomeReel], [HomeCreator]
/// or [HomeBrand], matching the section's kind.
class ComposedItem {
  const ComposedItem({
    required this.id,
    required this.position,
    required this.card,
    this.score,
    this.reasonKey,
    this.reasonParams = const {},
  });

  final String id;

  /// 0-based place within its section, as the composer ranked it.
  final int position;
  final Object card;
  final double? score;
  final String? reasonKey;
  final Map<String, String> reasonParams;
}

class ComposedSection {
  const ComposedSection({
    required this.sectionId,
    required this.kind,
    required this.title,
    required this.items,
    this.titleKey,
    this.titleParams = const {},
    this.reasonKey,
    this.source,
  });

  final String sectionId;
  final ComposedSectionKind kind;
  final String title;
  final String? titleKey;
  final Map<String, String> titleParams;
  final String? reasonKey;

  /// The model or rule behind it; for logs only, never shown.
  final String? source;
  final List<ComposedItem> items;
}

/// An optional ask-once preference question (mall_home only).
class ScreenQuestion {
  const ScreenQuestion({
    required this.key,
    required this.label,
    required this.values,
    this.department,
  });

  final String key;
  final String? department;
  final String label;
  final List<String> values;
}

class ComposedScreen {
  const ComposedScreen({
    required this.requestId,
    required this.screen,
    required this.sections,
    this.fallback = false,
    this.nextCursor,
    this.question,
  });

  final String? requestId;
  final String screen;
  final bool fallback;
  final List<ComposedSection> sections;
  final String? nextCursor;
  final ScreenQuestion? question;

  bool get isEmpty => sections.isEmpty && question == null;
}
