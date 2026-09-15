import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A StyleMint QR code: dark modules on white for any camera, high error
/// correction, and the StyleMint mark in the middle.
class StyleMintQr extends StatelessWidget {
  const StyleMintQr({
    required this.data,
    this.size = 220,
    this.semanticLabel = 'StyleMint QR code',
    super.key,
  });

  /// The mark's width as a share of the code's. Error correction H survives
  /// about 30% damage; the mark stays under the 25% ceiling.
  static const double markScale = 0.22;

  /// Always a StyleMint link.
  final String data;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DesignTokens.textWhite,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: SizedBox.square(
              dimension: size,
              child: PrettyQrView.data(
                data: data,
                errorCorrectLevel: QrErrorCorrectLevel.H,
                // The default shape: smooth black modules.
                decoration: const PrettyQrDecoration(
                  image: PrettyQrDecorationImage(
                    image: AssetImage(smBrandMarkAsset),
                    scale: markScale,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
