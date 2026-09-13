import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Voyager "Transparent Sponsored Product Boosting": the disclosure on a paid
/// search result. The badge carries an info icon; tapping it explains why
/// the result is there.
class SponsoredBadge extends StatelessWidget {
  const SponsoredBadge({required this.label, required this.onInfo, super.key});

  /// The backend's disclosure text, e.g. "Sponsored".
  final String label;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    // Its own control for screen readers; the disclosure itself is already
    // part of the result's spoken label.
    return Semantics(
      container: true,
      button: true,
      label: 'Why am I seeing this?',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('sponsored-info'),
        onTap: onInfo,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          // Taller than the pill so it is easy to hit.
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s6),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
            decoration: BoxDecoration(
              color: DesignTokens.warningFillDark,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: DesignTokens.warning500.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.warningTextLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: DesignTokens.s4),
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: DesignTokens.warningTextLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Explains a paid placement in a bottom sheet.
Future<void> showSponsoredInfoSheet(
  BuildContext context, {
  required String label,
  int? organicPosition,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: DesignTokens.sectionInnerTitle),
            const SizedBox(height: DesignTokens.s12),
            Text(
              sponsoredPlacementExplanation(organicPosition),
              style: DesignTokens.mediumRegular,
            ),
            const SizedBox(height: DesignTokens.s20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: DesignTokens.primaryButtonStyle(),
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Why a paid result is shown, and where it would rank without payment
/// when that is known.
String sponsoredPlacementExplanation(int? organicPosition) {
  const reason =
      "This is a paid placement. It's shown because it matches your search "
      'and is in stock.';
  return organicPosition == null
      ? reason
      : '$reason Without payment it would be result #$organicPosition.';
}
