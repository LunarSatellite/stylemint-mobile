import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// Style Mint error view — adapted from vpt-mydawa ErrorView.
class SmErrorView extends StatelessWidget {
  const SmErrorView({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kWarningColor, size: 56),
            const SizedBox(height: 12),
            if (message != null)
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: kTextSecondary,
                    ),
              ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap to retry',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kPrimaryColor,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.refresh, size: 16, color: kPrimaryColor),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
