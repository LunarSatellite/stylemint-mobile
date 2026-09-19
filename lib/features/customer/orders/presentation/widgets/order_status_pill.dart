import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

/// Semantic tone of a status pill, in the vocabulary the order screens speak.
///
/// This is now a thin adapter over the Mall kit's [MallStatusTone]: the kit
/// owns the palette and, crucially, the glyph. A status pill in this app can
/// no longer be drawn without one, so a delivered order and a cancelled one
/// differ by mark as well as by colour.
enum OrderPillTone { info, progress, success, negative, caution, neutral }

/// Compact rounded status label. Wraps rather than truncating so a long
/// label at a large text scale never overflows.
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({
    required this.label,
    required this.tone,
    super.key,
    this.icon,
    this.dense = false,
  });

  final String label;
  final OrderPillTone tone;

  /// Overrides the tone's default glyph. There is no way to have none.
  final IconData? icon;

  /// Tighter padding, for list rows.
  final bool dense;

  /// Maps the order vocabulary onto the kit's.
  ///
  /// `success` used to invert to a solid green slab with dark ink; it now
  /// shares the kit's tonal treatment, because a row of pills in which one is
  /// a filled block reads as a button, not a state.
  static MallStatusTone mallToneFor(OrderPillTone tone) => switch (tone) {
    OrderPillTone.info => MallStatusTone.info,
    OrderPillTone.progress => MallStatusTone.progress,
    OrderPillTone.success => MallStatusTone.success,
    OrderPillTone.negative => MallStatusTone.danger,
    OrderPillTone.caution => MallStatusTone.caution,
    OrderPillTone.neutral => MallStatusTone.neutral,
  };

  /// Fill and ink for [tone]. Kept for callers that tint a surrounding
  /// surface to match a pill.
  static (Color, Color) colorsFor(OrderPillTone tone) {
    final style = mallStatusStyle(mallToneFor(tone));
    return (style.background, style.foreground);
  }

  @override
  Widget build(BuildContext context) => MallStatusPill(
    label: label,
    tone: mallToneFor(tone),
    icon: icon,
    dense: dense,
  );
}
