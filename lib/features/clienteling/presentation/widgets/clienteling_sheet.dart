import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A bottom sheet that stays usable at 320dp with large text: it scrolls, it
/// lifts above the keyboard, and it never gets a fixed height.
Future<T?> showClientelingSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTokens.surfaceRaised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.cardRadius),
      ),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.s16,
        right: DesignTokens.s16,
        top: DesignTokens.s16,
        bottom:
            MediaQuery.of(sheetContext).viewInsets.bottom + DesignTokens.s16,
      ),
      child: SingleChildScrollView(child: builder(sheetContext)),
    ),
  );
}
