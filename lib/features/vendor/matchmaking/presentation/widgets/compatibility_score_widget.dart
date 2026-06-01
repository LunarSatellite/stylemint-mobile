import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CompatibilityScoreWidget extends StatelessWidget {
  const CompatibilityScoreWidget({super.key, required this.score});

  final int score;

  Color get _color {
    if (score >= 80) return DesignTokens.primaryGreen;
    if (score >= 50) return DesignTokens.warning500;
    return DesignTokens.colorError;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 4,
              backgroundColor: DesignTokens.bgAppBodyLight,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
          Text(
            '$score',
            style: DesignTokens.mediumSemibold.copyWith(
              color: _color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
