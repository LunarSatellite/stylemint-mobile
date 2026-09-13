import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Dims the page and shows the StyleMint loader while [isLoading].
class SmLoadingOverlay extends StatelessWidget {
  const SmLoadingOverlay({super.key, required this.isLoading, this.child});

  final bool isLoading;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child ?? const SizedBox.shrink();

    return Stack(
      children: [
        if (child != null) child!,
        ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: const SmPageLoader(size: 80),
        ),
      ],
    );
  }
}

/// Fullscreen loading indicator — for route-level loading.
class SmLoadingScreen extends StatelessWidget {
  const SmLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SmPageLoader(size: 88),
    );
  }
}
