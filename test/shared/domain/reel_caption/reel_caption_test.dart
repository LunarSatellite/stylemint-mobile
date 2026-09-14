import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/reel_caption/reel_caption.dart';

const _aeroPods = CaptionProduct(
  name: 'AeroPods Air',
  price: Money(amount: 8999, currency: 'NPR'),
);
const _tote = CaptionProduct(
  name: 'Nomad Canvas Tote',
  price: Money(amount: 1800, currency: 'NPR'),
);
const _glow = CaptionProduct(
  name: 'Glow Rituals',
  price: Money(amount: 2500, currency: 'NPR'),
);

const _singleProductCaption =
    'Wireless sound that fits your daily commute 🎧\n'
    'AeroPods Air · Rs 8,999\n'
    'Tap the product to shop on StyleMint.\n'
    '\n'
    '#StyleMint #Earbuds #TechDeals #AIgenerated';

List<CaptionIssueCode> _codes(List<CaptionIssue> issues) =>
    issues.map((i) => i.code).toList();

void main() {
  group('ReelCaption.compose', () {
    test('single product follows the standard layout exactly', () {
      final caption = ReelCaption.compose(
        hook: 'Wireless sound that fits your daily commute 🎧',
        products: const [_aeroPods],
        topicTags: const ['Earbuds', 'TechDeals'],
        aiGenerated: true,
      );

      expect(caption, _singleProductCaption);
    });

    test('two products get one line each and a single CTA', () {
      final caption = ReelCaption.compose(
        hook: 'Two weekend essentials I never leave home without',
        products: const [_tote, _glow],
        topicTags: const ['WeekendStyle', 'Skincare'],
        aiGenerated: false,
      );

      expect(
        caption,
        'Two weekend essentials I never leave home without\n'
        'Nomad Canvas Tote · Rs 1,800\n'
        'Glow Rituals · Rs 2,500\n'
        'Tap the product to shop on StyleMint.\n'
        '\n'
        '#StyleMint #WeekendStyle #Skincare',
      );
    });

    test('three or more products collapse to "+ n more · from lowest"', () {
      final lines = ReelCaption.productLinesFor(const [_tote, _aeroPods, _glow]);

      expect(lines, hasLength(1));
      expect(lines.single.text, 'Nomad Canvas Tote + 2 more · from Rs 1,800');
    });

    test('lowest price is used even when the first product is pricier', () {
      final lines = ReelCaption.productLinesFor(const [_aeroPods, _glow, _tote]);

      expect(lines.single.text, 'AeroPods Air + 2 more · from Rs 1,800');
    });

    test('no product omits product lines and the CTA', () {
      final caption = ReelCaption.compose(
        hook: 'Three ways to style one tote for a full week',
        products: const [],
        topicTags: const ['StyleTips'],
        aiGenerated: true,
      );

      expect(
        caption,
        'Three ways to style one tote for a full week\n'
        '\n'
        '#StyleMint #StyleTips #AIgenerated',
      );
      expect(caption, isNot(contains(ReelCaptionCopy.cta)));
    });

    test('hook whitespace and line breaks collapse to one line', () {
      final caption = ReelCaption.compose(
        hook: '  Wireless   sound\nthat fits your commute  ',
        products: const [],
        aiGenerated: false,
      );

      expect(caption.split('\n').first, 'Wireless sound that fits your commute');
    });

    test('non-whole prices keep two decimals via the shared formatter', () {
      expect(
        ReelCaption.formatCaptionPrice(
          const Money(amount: 1799.5, currency: 'NPR'),
        ),
        'Rs 1,799.50',
      );
      expect(
        ReelCaption.formatCaptionPrice(
          const Money(amount: 125000, currency: 'NPR'),
        ),
        'Rs 125,000',
      );
    });

    test('a blank product name falls back to "Product"', () {
      final lines = ReelCaption.productLinesFor(const [
        CaptionProduct(name: '  ', price: Money(amount: 500, currency: 'NPR')),
      ]);

      expect(lines.single.text, 'Product · Rs 500');
    });

    test('a custom (localized) CTA is used verbatim', () {
      final caption = ReelCaption.compose(
        hook: 'Wireless sound that fits your commute',
        products: const [_aeroPods],
        aiGenerated: false,
        cta: 'StyleMint मा किन्न उत्पादन थिच्नुहोस्।',
      );

      expect(caption, contains('\nStyleMint मा किन्न उत्पादन थिच्नुहोस्।\n'));
    });
  });

  group('ReelCaption hashtags', () {
    test('#StyleMint first, max 3 topics, #AIgenerated last', () {
      final tags = ReelCaption.hashtagsFor(
        topicTags: const ['One', 'Two', 'Three', 'Four'],
        aiGenerated: true,
      );

      expect(tags, ['StyleMint', 'One', 'Two', 'Three', 'AIgenerated']);
      expect(tags.length, lessThanOrEqualTo(ReelCaption.maxHashtags));
    });

    test('topic tags are letters/digits only, de-duplicated case-insensitively, '
        'and never repeat the system tags', () {
      final tags = ReelCaption.normalizeTopicTags(const [
        '#tech deals',
        'TECHDEALS',
        'Tech-Deals!',
        'stylemint',
        '#AIgenerated',
        'Skincare2026',
        'OOTD',
        'Extra',
      ]);

      expect(tags, ['techdeals', 'Skincare2026', 'OOTD']);
    });

    test('non-Latin topic tags keep their combining marks', () {
      expect(ReelCaption.normalizeTopicTag('#नेपाल'), 'नेपाल');
    });

    test('a tag with nothing left after cleaning is dropped', () {
      expect(ReelCaption.normalizeTopicTag('#!!'), isNull);
      expect(ReelCaption.normalizeTopicTags(const ['--', '']), isEmpty);
    });
  });

  group('ReelCaption.parse', () {
    test('round-trips a single-product standard caption', () {
      final parsed = ReelCaption.parse(_singleProductCaption);

      expect(parsed.isStandard, isTrue);
      expect(parsed.hook, 'Wireless sound that fits your daily commute 🎧');
      expect(parsed.productLines, const [
        CaptionProductLine(label: 'AeroPods Air', price: 'Rs 8,999'),
      ]);
      expect(parsed.hasCta, isTrue);
      expect(parsed.hashtags, ['StyleMint', 'Earbuds', 'TechDeals', 'AIgenerated']);
      expect(parsed.topicTags, ['Earbuds', 'TechDeals']);
      expect(parsed.hasAiTag, isTrue);
    });

    test('parses the collapsed "+ n more · from" product line', () {
      final caption = ReelCaption.compose(
        hook: 'Everything I packed for a Pokhara weekend',
        products: const [_tote, _aeroPods, _glow],
        aiGenerated: false,
      );

      final parsed = ReelCaption.parse(caption);

      expect(parsed.isStandard, isTrue);
      expect(parsed.productLines.single.label, 'Nomad Canvas Tote + 2 more');
      expect(parsed.productLines.single.price, 'from Rs 1,800');
      expect(parsed.hasAiTag, isFalse);
    });

    test('a no-product standard caption has no product lines or CTA', () {
      final parsed = ReelCaption.parse(
        'Three ways to style one tote for a full week\n\n#StyleMint #StyleTips',
      );

      expect(parsed.isStandard, isTrue);
      expect(parsed.productLines, isEmpty);
      expect(parsed.hasCta, isFalse);
      expect(parsed.topicTags, ['StyleTips']);
    });

    test('tolerates CRLF line endings', () {
      final parsed = ReelCaption.parse(
        _singleProductCaption.replaceAll('\n', '\r\n'),
      );

      expect(parsed.isStandard, isTrue);
      expect(parsed.productLines, hasLength(1));
    });

    test('a platform caption is non-standard but keeps its hashtags', () {
      final parsed = ReelCaption.parse(
        'New Year calls for rich cakes 🎂 #cake #NewYear\nOrder now!',
      );

      expect(parsed.isStandard, isFalse);
      expect(parsed.hook, 'New Year calls for rich cakes 🎂');
      expect(parsed.productLines, isEmpty);
      expect(parsed.hashtags, ['cake', 'NewYear']);
    });

    test('product lines without the CTA are non-standard', () {
      final parsed = ReelCaption.parse(
        'Wireless sound that fits your commute\n'
        'AeroPods Air · Rs 8,999\n\n#StyleMint',
      );

      expect(parsed.isStandard, isFalse);
    });

    test('a hashtag line that does not start with #StyleMint is non-standard', () {
      final parsed = ReelCaption.parse(
        'Wireless sound that fits your commute\n\n#Earbuds #StyleMint',
      );

      expect(parsed.isStandard, isFalse);
      expect(parsed.hashtags, ['Earbuds', 'StyleMint']);
    });

    test('more than two product lines is non-standard', () {
      final parsed = ReelCaption.parse(
        'Wireless sound that fits your commute\n'
        'AeroPods Air · Rs 8,999\n'
        'Nomad Canvas Tote · Rs 1,800\n'
        'Glow Rituals · Rs 2,500\n'
        'Tap the product to shop on StyleMint.\n\n#StyleMint',
      );

      expect(parsed.isStandard, isFalse);
    });

    test('an empty caption parses to an empty, non-standard value', () {
      final parsed = ReelCaption.parse('   \n ');

      expect(parsed.isEmpty, isTrue);
      expect(parsed.isStandard, isFalse);
      expect(parsed.hook, isEmpty);
      expect(parsed.hashtags, isEmpty);
    });
  });

  group('ReelCaption suggestions', () {
    test('suggestTopicTags extracts platform hashtags minus system tags', () {
      final tags = ReelCaption.suggestTopicTags(
        'Loving these #AeroPods for my #commute #StyleMint #AIgenerated '
        '#aeropods #Music #Extra',
      );

      expect(tags, ['AeroPods', 'commute', 'Music']);
    });

    test('suggestHook uses the first sentence when it fits 20–70 characters', () {
      expect(
        ReelCaption.suggestHook(
          'Wireless sound that fits your daily commute. Grab yours at '
          'stylemint.app #earbuds',
        ),
        'Wireless sound that fits your daily commute.',
      );
    });

    test('suggestHook skips hashtag-only lines', () {
      expect(
        ReelCaption.suggestHook(
          '#ad #sale\nThis tote carries my whole week of work gear',
        ),
        'This tote carries my whole week of work gear',
      );
    });

    test('suggestHook returns empty when the first sentence does not fit', () {
      expect(ReelCaption.suggestHook('Wow. So good'), isEmpty);
      expect(
        ReelCaption.suggestHook(
          'New Year calls for rich, delicious cakes to celebrate with your '
          'near and dear ones in a get together',
        ),
        isEmpty,
      );
      expect(ReelCaption.suggestHook(''), isEmpty);
    });

    test('mentionsAiGenerated detects common AI disclosures only', () {
      expect(ReelCaption.mentionsAiGenerated('Demo reel #AIgenerated'), isTrue);
      expect(ReelCaption.mentionsAiGenerated('This video is AI-generated'), isTrue);
      expect(ReelCaption.mentionsAiGenerated('Made with AI in Kathmandu'), isTrue);
      expect(ReelCaption.mentionsAiGenerated('Said hi to my aide'), isFalse);
      expect(ReelCaption.mentionsAiGenerated('Generated more leads'), isFalse);
    });
  });

  group('ReelCaption.issues', () {
    List<CaptionIssue> issuesFor(
      String hook, {
      List<String> topicTags = const [],
      bool aiGenerated = false,
      List<CaptionProduct> products = const [_aeroPods],
      String? sourceCaption,
    }) => ReelCaption.issues(
      hook: hook,
      products: products,
      topicTags: topicTags,
      aiGenerated: aiGenerated,
      sourceCaption: sourceCaption,
    );

    test('a clean draft has no issues', () {
      expect(
        issuesFor('Wireless sound that fits your daily commute 🎧', topicTags: const ['Earbuds']),
        isEmpty,
      );
    });

    test('missing hook is blocking', () {
      final issues = issuesFor('   ');

      expect(issues.first.code, CaptionIssueCode.hookMissing);
      expect(issues.first.blocking, isTrue);
      expect(ReelCaption.isHookLengthValid('   '), isFalse);
    });

    test('hook shorter than 20 characters is blocking', () {
      final issues = issuesFor('Check this out');

      expect(issues.first.code, CaptionIssueCode.hookTooShort);
      expect(issues.first.blocking, isTrue);
      expect(issues.first.message, contains('14'));
    });

    test('hook longer than 70 characters is blocking', () {
      final hook = 'A${'a' * 70}';
      final issues = issuesFor(hook);

      expect(issues.first.code, CaptionIssueCode.hookTooLong);
      expect(ReelCaption.isHookLengthValid(hook), isFalse);
    });

    test('20 and 70 characters are both valid', () {
      expect(ReelCaption.isHookLengthValid('A${'a' * 19}'), isTrue);
      expect(ReelCaption.isHookLengthValid('A${'a' * 69}'), isTrue);
    });

    test('flags price, hashtags, links, emoji, caps and case in the hook', () {
      expect(
        _codes(issuesFor('Only Rs 8999 for these earbuds today')),
        contains(CaptionIssueCode.hookHasPrice),
      );
      expect(
        _codes(issuesFor('New drop #earbuds for the daily commute')),
        contains(CaptionIssueCode.hookHasHashtag),
      );
      expect(
        _codes(issuesFor('Get yours today at stylemint.app/glow now')),
        contains(CaptionIssueCode.hookHasLink),
      );
      expect(
        _codes(issuesFor('Weekend vibes with my new canvas tote 🔥🔥')),
        contains(CaptionIssueCode.hookTooManyEmoji),
      );
      expect(
        _codes(issuesFor('AMAZING deal on earbuds this week')),
        contains(CaptionIssueCode.shoutingWord),
      );
      expect(
        _codes(issuesFor('wireless sound for your daily commute')),
        contains(CaptionIssueCode.hookNotSentenceCase),
      );
    });

    test('short acronyms are not shouting', () {
      expect(
        _codes(issuesFor('SPF that fits an NPR budget, finally')),
        isNot(contains(CaptionIssueCode.shoutingWord)),
      );
    });

    test('more than three distinct topic tags is flagged', () {
      expect(
        _codes(
          issuesFor(
            'Wireless sound that fits your daily commute',
            topicTags: const ['One', 'Two', 'Three', 'Four'],
          ),
        ),
        contains(CaptionIssueCode.tooManyTopicTags),
      );
    });

    test('#AIgenerated as a topic while the AI switch is off is flagged', () {
      const hook = 'Wireless sound that fits your daily commute';
      expect(
        _codes(issuesFor(hook, topicTags: const ['AIgenerated'])),
        contains(CaptionIssueCode.aiTagAsTopic),
      );
      expect(
        _codes(
          issuesFor(hook, topicTags: const ['AIgenerated'], aiGenerated: true),
        ),
        isNot(contains(CaptionIssueCode.aiTagAsTopic)),
      );
    });

    test('dropping the AI disclosure from an AI caption is flagged', () {
      const hook = 'Wireless sound that fits your daily commute';
      expect(
        _codes(issuesFor(hook, sourceCaption: 'Demo #AIgenerated')),
        contains(CaptionIssueCode.aiDisclosureMissing),
      );
      expect(
        issuesFor(hook, sourceCaption: 'Demo #AIgenerated', aiGenerated: true),
        isEmpty,
      );
    });

    test('captions over 300 characters are flagged', () {
      final longName = 'Product ${'x' * 120}';
      final issues = issuesFor(
        'Wireless sound that fits your daily commute',
        products: [
          CaptionProduct(name: longName, price: const Money(amount: 1, currency: 'NPR')),
          CaptionProduct(name: longName, price: const Money(amount: 2, currency: 'NPR')),
        ],
      );

      expect(_codes(issues), contains(CaptionIssueCode.captionTooLong));
    });

    test('emojiCount treats a ZWJ sequence as one emoji', () {
      expect(ReelCaption.emojiCount('Family day 👨‍👩‍👧'), 1);
      expect(ReelCaption.emojiCount('🎧 and 👍🏽'), 2);
      expect(ReelCaption.emojiCount('No emoji here'), 0);
    });
  });

  group('ReelCaptionDraft', () {
    test('fromPlatformCaption pre-fills hook, topics and AI flag', () {
      final draft = ReelCaptionDraft.fromPlatformCaption(
        'Wireless sound that fits your daily commute. #Earbuds #AIgenerated',
        products: const [_aeroPods],
      );

      expect(draft.hook, 'Wireless sound that fits your daily commute.');
      expect(draft.topicTags, ['Earbuds']);
      expect(draft.aiGenerated, isTrue);
      expect(draft.canSubmit, isTrue);
      expect(
        draft.caption,
        'Wireless sound that fits your daily commute.\n'
        'AeroPods Air · Rs 8,999\n'
        'Tap the product to shop on StyleMint.\n\n'
        '#StyleMint #Earbuds #AIgenerated',
      );
    });

    test('fromPlatformCaption without AI mention defaults the switch off', () {
      final draft = ReelCaptionDraft.fromPlatformCaption(
        'Morning routine with my favourite serum',
        products: const [_glow],
      );

      expect(draft.aiGenerated, isFalse);
    });

    test('fromExistingCaption round-trips a standard caption unchanged', () {
      final draft = ReelCaptionDraft.fromExistingCaption(
        _singleProductCaption,
        products: const [_aeroPods],
      );

      expect(draft.caption, _singleProductCaption);
      expect(draft.issues, isEmpty);
    });

    test('fromExistingCaption with no caption starts empty and blocked', () {
      final draft = ReelCaptionDraft.fromExistingCaption(
        null,
        products: const [],
      );

      expect(draft.hook, isEmpty);
      expect(draft.aiGenerated, isFalse);
      expect(draft.canSubmit, isFalse);
      expect(draft.caption, '#StyleMint');
    });

    test('copyWith keeps the source caption for disclosure checks', () {
      final draft = ReelCaptionDraft.fromExistingCaption(
        _singleProductCaption,
        products: const [_aeroPods],
      ).copyWith(aiGenerated: false);

      expect(
        _codes(draft.issues),
        contains(CaptionIssueCode.aiDisclosureMissing),
      );
    });
  });
}
