import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The designed dead end: a real code that this catalogue does not carry.
class BarcodeNotInCatalogue extends StatelessWidget {
  const BarcodeNotInCatalogue({
    required this.code,
    required this.onScanAgain,
    required this.onSearchCode,
    required this.onTypeInstead,
    super.key,
  });

  final String code;
  final VoidCallback onScanAgain;
  final VoidCallback onSearchCode;
  final VoidCallback onTypeInstead;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MallErrorState(
              key: const ValueKey('barcode-not-in-catalogue'),
              title: 'No StyleMint product carries this code',
              body:
                  'We read the barcode fine — the Mall just does not stock '
                  'this item. It may be sold somewhere else, or under a '
                  'different code here.',
              // Showing the digits lets the buyer tell a misread from a
              // genuine miss, and gives support something to quote.
              detail: 'Scanned code $code',
              icon: Icons.search_off_rounded,
              retryLabel: 'Scan another code',
              onRetry: onScanAgain,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s24,
                DesignTokens.s8,
                DesignTokens.s24,
                DesignTokens.s24,
              ),
              child: Column(
                children: [
                  TextButton(
                    key: const ValueKey('barcode-search-code'),
                    onPressed: onSearchCode,
                    // The label spells out the digits; the visible text
                    // cannot, and a lone "this code" tells a screen reader
                    // nothing.
                    child: Text(
                      'Search the Mall for this code',
                      textAlign: TextAlign.center,
                      semanticsLabel: 'Search the Mall for the code $code',
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('barcode-type-instead'),
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
