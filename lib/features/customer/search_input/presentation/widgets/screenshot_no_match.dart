import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The designed dead end for a screenshot the Mall cannot place.
///
/// This screen is the whole point of the feature's first hard rule. Visual
/// search that finds nothing has an obvious, tempting escape — show popular
/// products and let the buyer assume they were recognised. That is a
/// fabrication, it has reached customers on this codebase before, and the
/// honest version is this: say the Mall did not find it, and offer the two
/// things that genuinely help next.
///
/// There are two dead ends, not one, because the server distinguishes them
/// and a buyer acts on them differently. [ScreenshotNoMatchView] is used when
/// vision read the picture and the Mall does not stock it — it can name what
/// was seen. [ScreenshotNotRecognizedView] is used when the picture yielded
/// nothing to search with, where the advice is about the photo instead.
/// Neither shows a product.
class ScreenshotNoMatchView extends StatelessWidget {
  const ScreenshotNoMatchView({
    required this.onTryAnother,
    required this.onTypeInstead,
    this.recognizedFeatures = const [],
    super.key,
  });

  final VoidCallback onTryAnother;
  final VoidCallback onTypeInstead;

  /// What vision reported seeing. Rendered as read-only chips when present so
  /// the buyer learns the Mall understood the picture and simply has none of
  /// it. Empty is normal — the multimodal endpoint reports the outcome but
  /// not the features — and then the wording stays general. Nothing is
  /// invented to fill the space, and no chip is a search or a product.
  final List<String> recognizedFeatures;

  @override
  Widget build(BuildContext context) {
    final features = recognizedFeatures
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList(growable: false);

    return _ScreenshotDeadEnd(
      stateKey: const ValueKey('screenshot-no-match'),
      title: features.isEmpty
          ? 'The Mall could not find this'
          : 'The Mall does not stock this',
      body: features.isEmpty
          ? 'StyleMint looked at your screenshot and nothing in the Mall '
                'matches it. It may not be stocked here, or the picture may '
                'be too small or too busy to read.'
          : 'StyleMint read your screenshot and searched for what it saw. '
                'No seller in the Mall lists it right now.',
      icon: Icons.search_off_rounded,
      onTryAnother: onTryAnother,
      onTypeInstead: onTypeInstead,
      extra: features.isEmpty ? null : _RecognizedFeatures(features: features),
    );
  }
}

/// The dead end for a picture vision could not read anything searchable out
/// of. Says so plainly: nothing is known to be missing from the Mall, so the
/// wording does not claim it is, and no products are offered as consolation.
class ScreenshotNotRecognizedView extends StatelessWidget {
  const ScreenshotNotRecognizedView({
    required this.onTryAnother,
    required this.onTypeInstead,
    super.key,
  });

  final VoidCallback onTryAnother;
  final VoidCallback onTypeInstead;

  @override
  Widget build(BuildContext context) => _ScreenshotDeadEnd(
    stateKey: const ValueKey('screenshot-not-recognized'),
    title: 'StyleMint could not read this picture',
    // Deliberately not "we don't stock it" — that is a claim about the
    // catalogue, and nothing was searched for, so nothing is known about it.
    body:
        'Nothing in the screenshot was clear enough to search with. A '
        'sharper, closer picture of the single item usually works.',
    icon: Icons.image_not_supported_outlined,
    onTryAnother: onTryAnother,
    onTypeInstead: onTypeInstead,
  );
}

/// The words vision read, shown as plain, non-interactive chips.
class _RecognizedFeatures extends StatelessWidget {
  const _RecognizedFeatures({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DesignTokens.s24,
      DesignTokens.s16,
      DesignTokens.s24,
      0,
    ),
    child: Column(
      children: [
        const Text(
          'What StyleMint saw',
          key: ValueKey('screenshot-features-heading'),
          style: DesignTokens.smallRegular,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.s8),
        // One Semantics node for the whole set: a screen reader should hear
        // the list as a sentence, not tab through chips that do nothing.
        Semantics(
          key: const ValueKey('screenshot-features'),
          label: 'What StyleMint saw: ${features.join(', ')}',
          readOnly: true,
          container: true,
          child: ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                for (final feature in features)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: DesignTokens.chipsSelectedFill,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.chipRadius,
                      ),
                      border: Border.all(
                        color: DesignTokens.chipsSelectedBorder,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s12,
                        vertical: DesignTokens.s4,
                      ),
                      child: Text(
                        feature,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.chipsDefaultText,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Shared layout for both dead ends: centred explanation, optional detail,
/// and the two ways forward. Scrolls and re-centres so a large text scale at
/// 320dp never clips or overflows.
class _ScreenshotDeadEnd extends StatelessWidget {
  const _ScreenshotDeadEnd({
    required this.stateKey,
    required this.title,
    required this.body,
    required this.icon,
    required this.onTryAnother,
    required this.onTypeInstead,
    this.extra,
  });

  final Key stateKey;
  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onTryAnother;
  final VoidCallback onTypeInstead;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MallErrorState(
              key: stateKey,
              title: title,
              body: body,
              // No product is named, pictured or suggested. An empty result
              // is an empty result. The two ways forward are the buttons
              // below, so the error state carries no action of its own.
              icon: icon,
            ),
            ?extra,
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s24,
                DesignTokens.s16,
                DesignTokens.s24,
                DesignTokens.s24,
              ),
              child: Column(
                children: [
                  // Both buttons take their accessible name from their own
                  // label text, so no explicit Semantics wrapper — adding one
                  // produces a second node with the same name.
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('screenshot-try-another'),
                      onPressed: onTryAnother,
                      child: const Text(
                        'Try another screenshot',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('screenshot-type-instead'),
                    onPressed: onTypeInstead,
                    child: const Text(
                      'Type your search instead',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
