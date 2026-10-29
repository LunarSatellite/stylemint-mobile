import 'package:flutter/widgets.dart';

/// Strings for the server's `size_advice.*` keys, for every locale the app
/// declares in `supportedLocales` (en, ne, hi, es, zh). English is the
/// fallback for an unknown locale. An unknown key resolves to null so the
/// line is never drawn with a raw key.
abstract final class SizeAdviceStrings {
  static const Map<String, Map<String, String>> _byLocale = {
    'en': {
      'size_advice.runs_small': 'Runs small — many shoppers chose one size up',
      'size_advice.runs_large':
          'Runs large — many shoppers chose one size down',
      'size_advice.basis.product': 'Based on returns for this product',
      'size_advice.basis.brand_category':
          'Based on returns for this brand and category',
      'size_advice.dismiss': 'Dismiss size advice',
    },
    'ne': {
      'size_advice.runs_small': 'साइज सानो छ — धेरै ग्राहकले एक साइज ठूलो रोजे',
      'size_advice.runs_large': 'साइज ठूलो छ — धेरै ग्राहकले एक साइज सानो रोजे',
      'size_advice.basis.product': 'यस उत्पादनको फिर्तीमा आधारित',
      'size_advice.basis.brand_category':
          'यस ब्रान्ड र श्रेणीको फिर्तीमा आधारित',
      'size_advice.dismiss': 'साइज सल्लाह हटाउनुहोस्',
    },
    'hi': {
      'size_advice.runs_small':
          'साइज़ छोटा है — कई खरीदारों ने एक साइज़ बड़ा चुना',
      'size_advice.runs_large':
          'साइज़ बड़ा है — कई खरीदारों ने एक साइज़ छोटा चुना',
      'size_advice.basis.product': 'इस उत्पाद की वापसी पर आधारित',
      'size_advice.basis.brand_category':
          'इस ब्रांड और श्रेणी की वापसी पर आधारित',
      'size_advice.dismiss': 'साइज़ सलाह हटाएँ',
    },
    'es': {
      'size_advice.runs_small':
          'Talla pequeña — muchos compradores eligieron una talla más',
      'size_advice.runs_large':
          'Talla grande — muchos compradores eligieron una talla menos',
      'size_advice.basis.product': 'Según las devoluciones de este producto',
      'size_advice.basis.brand_category':
          'Según las devoluciones de esta marca y categoría',
      'size_advice.dismiss': 'Descartar consejo de talla',
    },
    'zh': {
      'size_advice.runs_small': '尺码偏小 — 许多买家选择了大一码',
      'size_advice.runs_large': '尺码偏大 — 许多买家选择了小一码',
      'size_advice.basis.product': '基于该商品的退货数据',
      'size_advice.basis.brand_category': '基于该品牌和品类的退货数据',
      'size_advice.dismiss': '关闭尺码建议',
    },
  };

  /// Every key, for tests that check each locale is complete.
  static Iterable<String> get locales => _byLocale.keys;
  static Map<String, String> table(String languageCode) =>
      _byLocale[languageCode] ?? const {};

  static String? resolve(String key, Locale? locale) {
    final table = _byLocale[locale?.languageCode] ?? _byLocale['en']!;
    return table[key] ?? _byLocale['en']![key];
  }

  static String? of(BuildContext context, String key) =>
      resolve(key, Localizations.maybeLocaleOf(context));
}
