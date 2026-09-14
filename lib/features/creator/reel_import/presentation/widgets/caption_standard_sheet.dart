import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/reel_caption/reel_caption.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_caption_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Opens the short "Caption standard" explainer used by [CaptionEditor].
Future<void> showCaptionStandardSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: DesignTokens.bgAppBody,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const CaptionStandardSheet(),
  );
}

/// Structure of a StyleMint reel caption plus one rendered example.
class CaptionStandardSheet extends StatelessWidget {
  const CaptionStandardSheet({super.key});

  static const String title = 'Caption standard';
  static const String closeLabel = 'Got it';

  static final String example = ReelCaption.compose(
    hook: 'Wireless sound that fits your daily commute 🎧',
    products: const [
      CaptionProduct(
        name: 'AeroPods Air',
        price: Money(amount: 8999, currency: 'NPR'),
      ),
    ],
    topicTags: const ['Earbuds', 'TechDeals'],
    aiGenerated: true,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s20,
          DesignTokens.s16,
          DesignTokens.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: DesignTokens.sectionInnerTitle.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            const Text(
              'Every StyleMint reel caption uses the same shape, so shoppers '
              'can read any reel at a glance.',
              style: DesignTokens.smallDescription,
            ),
            const SizedBox(height: DesignTokens.s16),
            const _Rule(
              number: '1',
              title: 'Hook',
              body:
                  'One line, 20–70 characters. No price, hashtags or links, '
                  'and at most one emoji. It is what viewers see first.',
            ),
            const _Rule(
              number: '2',
              title: 'Products',
              body:
                  'Name and price of each tagged product. Added for you.',
            ),
            const _Rule(
              number: '3',
              title: 'Call to action',
              body: '"${ReelCaptionCopy.cta}" Added for you.',
            ),
            const _Rule(
              number: '4',
              title: 'Hashtags',
              body:
                  '#StyleMint, up to 3 topic tags, and #AIgenerated for AI or '
                  'synthetic reels.',
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Example',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.baseBlack,
                borderRadius: BorderRadius.circular(DesignTokens.s12),
                border: Border.all(color: DesignTokens.borderDefault),
              ),
              child: ReelCaptionText(caption: example, expandable: false),
            ),
            const SizedBox(height: DesignTokens.s20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: DesignTokens.primaryButtonStyle(),
                child: const Text(closeLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.number, required this.title, required this.body});

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: DesignTokens.primaryGreenLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DesignTokens.mediumSemibold),
                const SizedBox(height: 2),
                Text(body, style: DesignTokens.smallDescription),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
