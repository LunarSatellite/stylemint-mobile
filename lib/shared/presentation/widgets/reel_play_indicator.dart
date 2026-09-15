import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The play button on a paused reel: the StyleMint mark — the same mark as
/// the splash and page loaders — in a dark disc with a faint mint ring.
class ReelPlayIndicator extends StatelessWidget {
  const ReelPlayIndicator({this.size = 76, super.key});

  static const Key markKey = ValueKey('reel-play-mark');

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paused',
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.13),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DesignTokens.baseBlack.withValues(alpha: 0.5),
            border: Border.all(
              color: DesignTokens.primaryGreen.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primaryGreen.withValues(alpha: 0.22),
                blurRadius: size * 0.3,
              ),
            ],
          ),
          child: Image.asset(
            smBrandMarkAsset,
            key: markKey,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
