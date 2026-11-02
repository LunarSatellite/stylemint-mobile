import 'package:flutter/widgets.dart';

/// Strings for the composer's `why.*` reason keys and the personalisation
/// copy around them, for every locale the app declares (en, ne, hi, es, zh),
/// following `SizeAdviceStrings`. English is the fallback for an unknown
/// locale; an unknown key resolves to null so a raw key is never shown.
///
/// No string names a declared value: a reason only says what kind of signal
/// was used, never which religion, budget or other personal fact it was.
abstract final class WhyStrings {
  /// The fixed reason list of the screen composer contract.
  static const List<String> reasonKeys = [
    'why.declared_festival',
    'why.declared_diet',
    'why.matches_style',
    'why.matches_budget',
    'why.bought_together',
    'why.visually_similar',
    'why.reorder_due',
    'why.followed_creator',
    'why.popular_near_you',
    'why.trending',
    'why.new_arrival',
    'why.complete_the_look',
    'why.price_drop',
    'why.back_in_stock',
    'why.season',
    'why.weather',
    'why.gift_for',
    'why.explore',
  ];

  /// UI keys used by the personalised screens and the preference centre.
  static const List<String> uiKeys = [
    'why.title',
    'why.unknown',
    'why.manage',
    'prefs.privacy',
    'prefs.sensitive_note',
    'ask.dismiss',
  ];

  static const Map<String, Map<String, String>> _byLocale = {
    'en': {
      'why.declared_festival':
          'Because you told us which festivals you celebrate',
      'why.declared_diet': 'Because it fits the food preferences you set',
      'why.matches_style': 'Because it matches your style',
      'why.matches_budget': 'Because it fits the price range you usually shop',
      'why.bought_together': 'Often bought together with items you have',
      'why.visually_similar': 'Looks similar to things you viewed',
      'why.reorder_due': 'You may be running low — time to reorder',
      'why.followed_creator': 'From a creator you follow',
      'why.popular_near_you': 'Popular with shoppers near you',
      'why.trending': 'Trending on StyleMint right now',
      'why.new_arrival': 'New arrival',
      'why.complete_the_look': 'Completes a look you started',
      'why.price_drop': 'The price dropped on something you saved',
      'why.back_in_stock': 'Back in stock',
      'why.season': 'Right for the season',
      'why.weather': 'Suited to the weather where you are',
      'why.gift_for': 'Ideas for the gift you are shopping for',
      'why.explore': 'Something new to explore',
      'why.title': 'Why am I seeing this?',
      'why.unknown': 'From the Mall',
      'why.manage': 'Manage your preferences',
      'prefs.privacy':
          'Only you see these. Shops never see them. Used to show you relevant items, never to change prices.',
      'prefs.sensitive_note':
          'Optional and private. We only use this if you choose to set it, and it is never inferred.',
      'ask.dismiss': 'Not now',
    },
    'ne': {
      'why.declared_festival': 'तपाईंले मनाउने चाडपर्व बताउनुभएकाले',
      'why.declared_diet': 'तपाईंले सेट गर्नुभएको खानाको रोजाइ अनुसार',
      'why.matches_style': 'तपाईंको शैलीसँग मिल्ने भएकाले',
      'why.matches_budget': 'तपाईंले सामान्यतया किन्ने मूल्य दायरामा पर्ने',
      'why.bought_together': 'तपाईंसँग भएका सामानसँगै प्रायः किनिने',
      'why.visually_similar': 'तपाईंले हेर्नुभएका सामानजस्तै देखिने',
      'why.reorder_due': 'सकिन लागेको हुनसक्छ — फेरि अर्डर गर्ने बेला',
      'why.followed_creator': 'तपाईंले फलो गर्नुभएको क्रिएटरबाट',
      'why.popular_near_you': 'तपाईं नजिकका ग्राहकमाझ लोकप्रिय',
      'why.trending': 'अहिले StyleMint मा ट्रेन्डिङ',
      'why.new_arrival': 'नयाँ आगमन',
      'why.complete_the_look': 'तपाईंले सुरु गर्नुभएको लुक पूरा गर्छ',
      'why.price_drop': 'तपाईंले सेभ गर्नुभएको सामानको मूल्य घट्यो',
      'why.back_in_stock': 'फेरि स्टकमा',
      'why.season': 'यो मौसमका लागि उपयुक्त',
      'why.weather': 'तपाईंको ठाउँको मौसम अनुसार',
      'why.gift_for': 'तपाईंले खोजिरहनुभएको उपहारका लागि सुझाव',
      'why.explore': 'हेर्नलायक केही नयाँ',
      'why.title': 'मैले यो किन देखिरहेको छु?',
      'why.unknown': 'StyleMint ले तपाईंका लागि रोजेको',
      'why.manage': 'आफ्ना रोजाइहरू व्यवस्थापन गर्नुहोस्',
      'prefs.privacy':
          'यी तपाईंले मात्र देख्नुहुन्छ। पसलहरूले कहिल्यै देख्दैनन्। सान्दर्भिक सामान देखाउन मात्र प्रयोग हुन्छ, मूल्य बदल्न कहिल्यै होइन।',
      'prefs.sensitive_note':
          'ऐच्छिक र निजी। तपाईंले सेट गर्नुभयो भने मात्र प्रयोग हुन्छ, कहिल्यै अनुमान गरिँदैन।',
      'ask.dismiss': 'अहिले होइन',
    },
    'hi': {
      'why.declared_festival':
          'क्योंकि आपने बताया कि आप कौन-से त्योहार मनाते हैं',
      'why.declared_diet':
          'क्योंकि यह आपकी चुनी हुई खान-पान पसंद से मेल खाता है',
      'why.matches_style': 'क्योंकि यह आपकी स्टाइल से मेल खाता है',
      'why.matches_budget': 'क्योंकि यह आपकी आम खरीदारी की कीमत सीमा में है',
      'why.bought_together': 'आपके पास मौजूद चीज़ों के साथ अक्सर खरीदा जाता है',
      'why.visually_similar': 'आपकी देखी हुई चीज़ों जैसा दिखता है',
      'why.reorder_due': 'शायद ख़त्म होने वाला है — दोबारा ऑर्डर करने का समय',
      'why.followed_creator': 'आपके फ़ॉलो किए गए क्रिएटर से',
      'why.popular_near_you': 'आपके आस-पास के खरीदारों में लोकप्रिय',
      'why.trending': 'अभी StyleMint पर ट्रेंडिंग',
      'why.new_arrival': 'नया आगमन',
      'why.complete_the_look': 'आपका शुरू किया हुआ लुक पूरा करता है',
      'why.price_drop': 'आपकी सेव की हुई चीज़ की कीमत घटी',
      'why.back_in_stock': 'फिर से स्टॉक में',
      'why.season': 'इस मौसम के लिए सही',
      'why.weather': 'आपके यहाँ के मौसम के अनुकूल',
      'why.gift_for': 'आप जिस उपहार की तलाश में हैं, उसके लिए सुझाव',
      'why.explore': 'देखने के लिए कुछ नया',
      'why.title': 'मुझे यह क्यों दिख रहा है?',
      'why.unknown': 'StyleMint ने आपके लिए चुना',
      'why.manage': 'अपनी पसंद प्रबंधित करें',
      'prefs.privacy':
          'इन्हें केवल आप देखते हैं। दुकानें इन्हें कभी नहीं देखतीं। केवल प्रासंगिक चीज़ें दिखाने के लिए उपयोग होता है, कीमत बदलने के लिए कभी नहीं।',
      'prefs.sensitive_note':
          'वैकल्पिक और निजी। इसका उपयोग तभी होता है जब आप इसे चुनें, और इसका कभी अनुमान नहीं लगाया जाता।',
      'ask.dismiss': 'अभी नहीं',
    },
    'es': {
      'why.declared_festival': 'Porque nos dijiste qué festividades celebras',
      'why.declared_diet': 'Porque encaja con tus preferencias alimentarias',
      'why.matches_style': 'Porque encaja con tu estilo',
      'why.matches_budget':
          'Porque está en el rango de precio que sueles comprar',
      'why.bought_together': 'Se compra a menudo con artículos que tienes',
      'why.visually_similar': 'Se parece a cosas que has visto',
      'why.reorder_due':
          'Puede que se te esté acabando: hora de volver a pedir',
      'why.followed_creator': 'De un creador que sigues',
      'why.popular_near_you': 'Popular entre compradores cerca de ti',
      'why.trending': 'Tendencia en StyleMint ahora mismo',
      'why.new_arrival': 'Novedad',
      'why.complete_the_look': 'Completa un look que empezaste',
      'why.price_drop': 'Bajó el precio de algo que guardaste',
      'why.back_in_stock': 'De nuevo disponible',
      'why.season': 'Ideal para la temporada',
      'why.weather': 'Adecuado para el clima donde estás',
      'why.gift_for': 'Ideas para el regalo que estás buscando',
      'why.explore': 'Algo nuevo para descubrir',
      'why.title': '¿Por qué veo esto?',
      'why.unknown': 'Elegido para ti por StyleMint',
      'why.manage': 'Gestionar tus preferencias',
      'prefs.privacy':
          'Solo tú las ves. Las tiendas nunca las ven. Se usan para mostrarte artículos relevantes, nunca para cambiar precios.',
      'prefs.sensitive_note':
          'Opcional y privado. Solo lo usamos si decides indicarlo, y nunca se deduce.',
      'ask.dismiss': 'Ahora no',
    },
    'zh': {
      'why.declared_festival': '因为你告诉过我们你庆祝哪些节日',
      'why.declared_diet': '因为它符合你设置的饮食偏好',
      'why.matches_style': '因为它符合你的风格',
      'why.matches_budget': '因为它在你常购买的价格区间内',
      'why.bought_together': '常与你已有的商品一起购买',
      'why.visually_similar': '与你浏览过的商品相似',
      'why.reorder_due': '可能快用完了 — 该再次购买了',
      'why.followed_creator': '来自你关注的创作者',
      'why.popular_near_you': '在你附近的买家中很受欢迎',
      'why.trending': 'StyleMint 当前热门',
      'why.new_arrival': '新品上架',
      'why.complete_the_look': '补全你开始搭配的造型',
      'why.price_drop': '你收藏的商品降价了',
      'why.back_in_stock': '已重新到货',
      'why.season': '适合当季',
      'why.weather': '适合你所在地的天气',
      'why.gift_for': '为你正在挑选的礼物提供灵感',
      'why.explore': '发现新内容',
      'why.title': '为什么我会看到这个？',
      'why.unknown': 'StyleMint 为你精选',
      'why.manage': '管理你的偏好',
      'prefs.privacy': '只有你能看到这些。商家永远看不到。仅用于向你展示相关商品，绝不用于改变价格。',
      'prefs.sensitive_note': '可选且私密。仅在你主动设置时使用，绝不推断。',
      'ask.dismiss': '暂不',
    },
  };

  static Iterable<String> get locales => _byLocale.keys;

  static Map<String, String> table(String languageCode) =>
      _byLocale[languageCode] ?? const {};

  static String? resolve(String key, Locale? locale) {
    final table = _byLocale[locale?.languageCode] ?? _byLocale['en']!;
    return table[key] ?? _byLocale['en']![key];
  }

  static String? of(BuildContext context, String key) =>
      resolve(key, Localizations.maybeLocaleOf(context));

  /// The reason text for [reasonKey], or the generic line for an unknown or
  /// absent key.
  static String reason(BuildContext context, String? reasonKey) =>
      (reasonKey == null ? null : of(context, reasonKey)) ??
      of(context, 'why.unknown')!;
}
