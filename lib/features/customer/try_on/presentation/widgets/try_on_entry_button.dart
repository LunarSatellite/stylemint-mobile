import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Try it on" on the product page.
///
/// Drawn only when the service is enabled (`GET /v1/try-on/access`) and the
/// product is try-on ready. A buyer with access gets the overlay itself as
/// the readiness check (404 = no try-on image → nothing drawn); a buyer
/// without access cannot ask that (403), so the public size chart stands in
/// as the vendor's "this item is set up for try-on" signal. Tapping without
/// access opens the paywall.
class TryOnEntryButton extends ConsumerStatefulWidget {
  const TryOnEntryButton({required this.productId, this.padding, super.key});

  final String productId;
  final EdgeInsetsGeometry? padding;

  @override
  ConsumerState<TryOnEntryButton> createState() => _TryOnEntryButtonState();
}

class _TryOnEntryButtonState extends ConsumerState<TryOnEntryButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(tryOnAccountKeyProvider) != null) {
        unawaited(
          ref.read(tryOnAccessNotifierProvider.notifier).ensureLoaded(),
        );
      }
    });
  }

  Future<void> _open() async {
    if (!await ensureAuth(context, ref, reason: AuthReason.general)) return;
    if (!mounted) return;
    // Possibly just signed in: read access for this account.
    await ref.read(tryOnAccessNotifierProvider.notifier).ensureLoaded();
    if (!mounted) return;
    final access = ref.read(tryOnAccessNotifierProvider).accessOrNull;
    if (access == null || !access.serviceEnabled) {
      SmSnackbar.info(context, 'Virtual try-on is not available right now.');
      return;
    }
    if (!access.hasAccess) {
      final unlocked = await context.push<bool>(RouteNames.tryOnPaywall);
      if (!(unlocked ?? false) || !mounted) return;
    }
    await context.push(RouteNames.tryOnPath(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(tryOnAccountKeyProvider) != null;
    final access = ref.watch(tryOnAccessNotifierProvider).accessOrNull;
    final chart = ref
        .watch(publicSizeChartProvider(widget.productId))
        .asData
        ?.value;

    // Signed out: the access endpoint needs a session, so the size chart is
    // the only signal; sign-in happens on tap.
    if (signedIn && (access == null || !access.serviceEnabled)) {
      return const SizedBox.shrink();
    }
    final hasAccess = access?.hasAccess ?? false;
    final ready = hasAccess
        ? ref.watch(tryOnProductProvider(widget.productId)).hasValue ||
              chart != null
        : chart != null;
    if (!ready) return const SizedBox.shrink();

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const Key('try-it-on'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignTokens.primaryGreen,
            side: const BorderSide(color: DesignTokens.primaryGreen),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: () => unawaited(_open()),
          icon: const Icon(Icons.view_in_ar_rounded),
          label: Text(hasAccess ? 'Try it on' : 'Try it on · Premium'),
        ),
      ),
    );
  }
}
