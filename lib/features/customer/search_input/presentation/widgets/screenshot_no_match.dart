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
class ScreenshotNoMatchView extends StatelessWidget {
  const ScreenshotNoMatchView({
    required this.onTryAnother,
    required this.onTypeInstead,
    super.key,
  });

  final VoidCallback onTryAnother;
  final VoidCallback onTypeInstead;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MallErrorState(
              key: ValueKey('screenshot-no-match'),
              title: 'The Mall could not find this',
              body:
                  'StyleMint looked at your screenshot and nothing in the '
                  'Mall matches it. It may not be stocked here, or the '
                  'picture may be too small or too busy to read.',
              // No product is named, pictured or suggested. An empty result
              // is an empty result. The two ways forward are the buttons
              // below, so the error state carries no action of its own.
              icon: Icons.search_off_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s24,
                0,
                DesignTokens.s24,
                DesignTokens.s24,
              ),
              child: Column(
                children: [
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
