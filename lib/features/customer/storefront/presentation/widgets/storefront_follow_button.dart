import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Follow / Following pill for a creator or brand account. Guests are asked
/// to sign in first; the toggle is optimistic and rolls back on failure.
class StorefrontFollowButton extends ConsumerWidget {
  const StorefrontFollowButton({
    required this.accountId,
    required this.name,
    super.key,
  });

  final String accountId;
  final String name;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    if (!await ensureAuth(context, ref, reason: AuthReason.follow)) return;
    if (!context.mounted) return;
    try {
      await ref.read(followNotifierProvider.notifier).toggle(accountId);
    } on Object {
      if (context.mounted) {
        SmSnackbar.error(context, "Couldn't update follow. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following = ref.watch(
      followNotifierProvider.select((ids) => ids.contains(accountId)),
    );
    final duration = MallMetrics.reduceMotion(context)
        ? Duration.zero
        : DesignTokens.motionFast;
    final foreground = following
        ? DesignTokens.textWhite
        : DesignTokens.buttonPrimaryText;

    return Semantics(
      button: true,
      toggled: following,
      label: following ? 'Following $name' : 'Follow $name',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        curve: DesignTokens.motionCurve,
        constraints: const BoxConstraints(
          minHeight: DesignTokens.minTouchTarget,
          minWidth: 104,
        ),
        decoration: BoxDecoration(
          color: following
              ? DesignTokens.surfaceRaised
              : DesignTokens.buttonPrimaryFill,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            onTap: () => _toggle(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    following ? Icons.check_rounded : Icons.add_rounded,
                    size: 18,
                    color: foreground,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    following ? 'Following' : 'Follow',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
