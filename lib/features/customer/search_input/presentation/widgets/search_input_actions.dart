import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The speak-and-scan entry points that sit beside the Discover search field,
/// next to the photo-search button they were modelled on.
///
/// A button is drawn only while its input can still lead somewhere. A device
/// with no camera or no speech engine gets no button for it — never a button
/// that fails on tap.
class SearchInputActions extends ConsumerWidget {
  const SearchInputActions({
    required this.currentQuery,
    required this.onQuery,
    super.key,
  });

  /// What is already typed in the field, carried into the voice screen so
  /// speaking does not throw away a half-written search.
  final ValueGetter<String> currentQuery;

  /// Runs a confirmed query through Discover's own submit path — the same
  /// one typing and photo search use.
  final ValueChanged<String> onQuery;

  Future<void> _openVoice(BuildContext context) async {
    final query = await context.push<String>(
      RouteNames.searchVoice,
      extra: currentQuery(),
    );
    if (query != null && query.trim().isNotEmpty) onQuery(query.trim());
  }

  Future<void> _openBarcode(BuildContext context) async {
    final query = await context.push<String>(RouteNames.searchBarcode);
    if (query != null && query.trim().isNotEmpty) onQuery(query.trim());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref.watch(searchInputCapabilitiesProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (capabilities.voice.isOffered) ...[
          const SizedBox(width: DesignTokens.s8),
          _SearchInputButton(
            buttonKey: const ValueKey('discover-voice-search'),
            icon: Icons.mic_none_rounded,
            label: 'Search by voice',
            onPressed: () => unawaited(_openVoice(context)),
          ),
        ],
        if (capabilities.barcode.isOffered) ...[
          const SizedBox(width: DesignTokens.s8),
          _SearchInputButton(
            buttonKey: const ValueKey('discover-barcode-search'),
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan a product barcode',
            onPressed: () => unawaited(_openBarcode(context)),
          ),
        ],
      ],
    );
  }
}

class _SearchInputButton extends StatelessWidget {
  const _SearchInputButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  // A tooltip sets the semantics *tooltip*, not the accessible name, and an
  // icon-only button has no text to fall back on — so the label is explicit.
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: IconButton.filledTonal(
      key: buttonKey,
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: DesignTokens.primaryGreen.withValues(alpha: 0.14),
        foregroundColor: DesignTokens.primaryGreen,
      ),
      icon: Icon(icon),
    ),
  );
}
