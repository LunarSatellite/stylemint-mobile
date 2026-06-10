import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/busy/busy_controller.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Wraps the whole app (via MaterialApp.router `builder`) and shows a global
/// loading indicator whenever any tracked operation is in flight — driven
/// automatically by the Dio BusyInterceptor (every API call) and by
/// `ref.runBusy(...)` for non-network work (e.g. passkey/local_auth).
///
/// Shows BOTH a thin top progress bar AND a clearly-visible centered spinner so
/// the user always knows the app is working. It does NOT trap taps
/// (`IgnorePointer`), so the UI never feels frozen if a request is slow —
/// buttons separately disable themselves via their own loading state.
class BusyOverlay extends ConsumerWidget {
  const BusyOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(isBusyProvider);
    return Stack(
      children: [
        child,
        if (busy)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  // Thin top progress bar.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor:
                              DesignTokens.primaryGreen.withValues(alpha: 0.18),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              DesignTokens.primaryGreen),
                        ),
                      ),
                    ),
                  ),
                  // Clearly-visible centered spinner in a rounded card.
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(DesignTokens.s20),
                      decoration: BoxDecoration(
                        color:
                            DesignTokens.bgAppBodyLight.withValues(alpha: 0.96),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.cardRadius),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              DesignTokens.primaryGreen),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
