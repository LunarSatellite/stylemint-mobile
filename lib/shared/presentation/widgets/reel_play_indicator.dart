import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The mark shown on a paused reel and on reels that open in their app.
class ReelPlayIndicator extends StatelessWidget {
  const ReelPlayIndicator({this.size = 64, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DesignTokens.baseBlack.withValues(alpha: 0.45),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        size: size * 0.5,
        color: DesignTokens.iconWhite,
      ),
    );
  }
}
