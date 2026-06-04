import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/busy/busy_controller.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Wraps the whole app (via MaterialApp.router `builder`) and shows a thin,
/// non-blocking progress bar at the very top whenever any tracked operation is
/// in flight. Deliberately does NOT trap taps — it's a "please wait" hint, not a
/// modal blocker, so the UI never feels frozen/stale.
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: DesignTokens.primaryGreen.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        DesignTokens.primaryGreen),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
