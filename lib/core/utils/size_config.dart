import 'package:flutter/material.dart';

/// Responsive sizing utility — adapted from vpt-mydawa.
/// Provides percentage-based width/height and common spacing helpers.
class SizeConfig {
  SizeConfig(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
  }

  late final double _screenWidth;
  late final double _screenHeight;

  bool get isTablet => _screenWidth >= 600;

  /// Returns [percent]% of screen width.
  double appWidth(double percent) => _screenWidth * (percent / 100);

  /// Returns [percent]% of screen height.
  double appHeight(double percent) => _screenHeight * (percent / 100);

  // ── Common spacers ───────────────────────────────────────────────────────
  SizedBox verticalSpaceTiny()   => const SizedBox(height: 4);
  SizedBox verticalSpaceSmall()  => const SizedBox(height: 8);
  SizedBox verticalSpaceMedium() => const SizedBox(height: 16);
  SizedBox verticalSpaceLarge()  => const SizedBox(height: 24);
  SizedBox verticalSpaceXL()     => const SizedBox(height: 32);

  SizedBox horizontalSpaceTiny()   => const SizedBox(width: 4);
  SizedBox horizontalSpaceSmall()  => const SizedBox(width: 8);
  SizedBox horizontalSpaceMedium() => const SizedBox(width: 16);
  SizedBox horizontalSpaceLarge()  => const SizedBox(width: 24);
}
