import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// Style Mint loading overlay — adapted from vpt-mydawa LoadingOverlay.
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
          color: Colors.black.withOpacity(0.35),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
            ),
          ),
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
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      ),
    );
  }
}
