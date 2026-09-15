import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Back button floating top-start over imagery, clear of the status bar.
class MallBackButton extends StatelessWidget {
  const MallBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(DesignTokens.s8),
          child: IconButton(
            tooltip: 'Back',
            onPressed: context.popOrHome,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x73000000),
              fixedSize: const Size.square(DesignTokens.minTouchTarget),
              minimumSize: const Size.square(DesignTokens.minTouchTarget),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: DesignTokens.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}

/// The end of an infinitely scrolling list: a spinner while the next page
/// loads, a retry after a failed page, otherwise breathing room.
class MallPagingFooter extends StatelessWidget {
  const MallPagingFooter({
    required this.isLoading,
    required this.failed,
    required this.onRetry,
    super.key,
  });

  final bool isLoading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final Widget child;
    if (isLoading) {
      child = const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: DesignTokens.textLight,
          semanticsLabel: 'Loading more',
        ),
      );
    } else if (failed) {
      child = TextButton.icon(
        onPressed: onRetry,
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.textWhite,
          minimumSize: const Size(
            DesignTokens.minTouchTarget,
            DesignTokens.minTouchTarget,
          ),
        ),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text("Couldn't load more. Retry"),
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 32 + bottom),
      child: Center(child: child),
    );
  }
}
