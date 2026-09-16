import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What quick-add is doing right now.
enum MallQuickAddPhase {
  /// Waiting to be tapped.
  idle,

  /// The request is in flight.
  busy,

  /// The item landed; the tick is held briefly, then the control resets.
  added,
}

/// The Mall's buy affordance: one tap puts the item in the bag without
/// leaving the page.
///
/// The control owns its own three-phase state rather than reading a provider,
/// so a rail of twenty tiles costs twenty booleans and one tap rebuilds one
/// tile. [onAdd] returns whether the add went through — a false result drops
/// straight back to idle and leaves the message to the caller, which is the
/// only layer that knows why it failed.
///
/// 44dp target around a 34dp disc, the same geometry as the save heart, so
/// the two controls read as a pair.
class MallQuickAdd extends StatefulWidget {
  /// The buy control on a product that needs no choice: one tap adds one unit.
  const MallQuickAdd({
    required Future<bool> Function() this.onAdd,
    required this.semanticLabel,
    super.key,
    this.label,
    this.dwell = const Duration(milliseconds: 1400),
  }) : onChoose = null;

  /// The same control on a product whose buyer has to pick a size or a colour
  /// first: it opens the product page and never touches the cart.
  ///
  /// A separate constructor rather than a flag, so the add callback is not
  /// merely unused on this path — it does not exist, and no future edit can
  /// reach it. Same geometry as the add form, so a rail does not reflow when
  /// one tile turns out to need a choice.
  const MallQuickAdd.choose({
    required VoidCallback this.onChoose,
    required this.semanticLabel,
    super.key,
    this.label,
  }) : onAdd = null,
       dwell = Duration.zero;

  /// Performs the add and reports whether it succeeded. Null on the choose
  /// form.
  final Future<bool> Function()? onAdd;

  /// Opens the product page so the buyer can choose. Null on the add form.
  final VoidCallback? onChoose;

  /// Whether this control sends the buyer to the product page instead of
  /// adding.
  bool get requiresSelection => onChoose != null;

  /// Spoken label, e.g. "Add Linen co-ord set to bag".
  final String semanticLabel;

  /// Spells the action out as a pill instead of a disc. For blocks with room
  /// for words — the spotlight — never for a rail tile.
  final String? label;

  /// How long the confirmation tick is held.
  final Duration dwell;

  /// The control's tap target, in both shapes.
  static const Key tapKey = Key('mall-quick-add');

  /// Exact height of the control, which is a touch target and so does not
  /// scale with text.
  static const double height = DesignTokens.minTouchTarget;

  /// The buy control for [product], in the only state its card allows.
  ///
  /// One place decides, so every surface that shows the control — rail tile,
  /// reel tile, spotlight — is honest in the same way: a product the card
  /// cleared for quick add (`requiresOptionSelection: false` **and** a
  /// default variant id) gets the add form; anything else, including every
  /// card from a server that does not send the fields yet, gets the choose
  /// form and opens the product page.
  ///
  /// Returns null when the control would do nothing: no [onAdd] (the surface
  /// does not buy), or a product needing a choice with no [onChoose] page to
  /// send the buyer to.
  static Widget? forProduct({
    required MallProductVm product,
    required MallStrings strings,
    Future<bool> Function()? onAdd,
    VoidCallback? onChoose,
    bool withLabel = false,
  }) {
    if (onAdd == null) return null;
    if (!product.isInStock) return null;
    if (!product.canQuickAdd) {
      if (onChoose == null) return null;
      return MallQuickAdd.choose(
        onChoose: onChoose,
        semanticLabel: strings.chooseItem(product.name),
        label: withLabel ? strings.chooseOptions : null,
      );
    }
    return MallQuickAdd(
      onAdd: onAdd,
      semanticLabel: strings.addItem(product.name),
      label: withLabel ? strings.addToBag : null,
    );
  }

  @override
  State<MallQuickAdd> createState() => _MallQuickAddState();
}

class _MallQuickAddState extends State<MallQuickAdd> {
  MallQuickAddPhase _phase = MallQuickAddPhase.idle;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _tap() async {
    // A product that needs a size or a colour is never added from a tile: the
    // tap opens the page where the buyer chooses, and the control stays idle.
    final choose = widget.onChoose;
    if (choose != null) {
      choose();
      return;
    }
    final add = widget.onAdd;
    if (add == null) return;
    // A second tap while the first is in flight would buy the item twice.
    if (_phase == MallQuickAddPhase.busy) return;
    _reset?.cancel();
    setState(() => _phase = MallQuickAddPhase.busy);
    final ok = await add();
    if (!mounted) return;
    setState(
      () => _phase = ok ? MallQuickAddPhase.added : MallQuickAddPhase.idle,
    );
    if (!ok) return;
    _reset = Timer(widget.dwell, () {
      if (mounted) setState(() => _phase = MallQuickAddPhase.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final reduceMotion = MallMetrics.reduceMotion(context);
    final duration = reduceMotion ? Duration.zero : DesignTokens.motionFast;
    final filled = _phase != MallQuickAddPhase.idle;
    final label = widget.label;
    final spoken = switch (_phase) {
      MallQuickAddPhase.added => strings.added,
      _ => widget.semanticLabel,
    };

    final mark = AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: switch (_phase) {
        // Sliders, not a cart: the tap opens a choice, and the glyph has to
        // say so before the tap, not after it.
        MallQuickAddPhase.idle => Icon(
          widget.requiresSelection
              ? Icons.tune_rounded
              : Icons.add_shopping_cart_rounded,
          key: const ValueKey(MallQuickAddPhase.idle),
          size: 18,
          color: DesignTokens.primaryGreen,
        ),
        MallQuickAddPhase.busy => const SizedBox.square(
          key: ValueKey(MallQuickAddPhase.busy),
          dimension: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DesignTokens.buttonPrimaryText,
          ),
        ),
        MallQuickAddPhase.added => const Icon(
          Icons.check_rounded,
          key: ValueKey(MallQuickAddPhase.added),
          size: 18,
          color: DesignTokens.buttonPrimaryText,
        ),
      },
    );

    final visual = AnimatedContainer(
      duration: duration,
      curve: DesignTokens.motionCurve,
      height: label == null ? 34 : 38,
      padding: label == null
          ? EdgeInsets.zero
          : const EdgeInsetsDirectional.fromSTEB(16, 0, 18, 0),
      width: label == null ? 34 : null,
      decoration: BoxDecoration(
        color: filled
            ? DesignTokens.primaryGreen
            : DesignTokens.primaryGreenDark,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        border: const Border.fromBorderSide(
          BorderSide(color: DesignTokens.primaryGreen),
        ),
      ),
      child: label == null
          ? Center(child: mark)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                mark,
                const SizedBox(width: DesignTokens.s8),
                Flexible(
                  child: Text(
                    _phase == MallQuickAddPhase.added ? strings.added : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: filled
                          ? DesignTokens.buttonPrimaryText
                          : DesignTokens.textWhite,
                    ),
                  ),
                ),
              ],
            ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: _phase != MallQuickAddPhase.busy,
      label: spoken,
      excludeSemantics: true,
      onTap: _tap,
      child: SizedBox(
        height: MallQuickAdd.height,
        width: label == null ? MallQuickAdd.height : null,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            key: MallQuickAdd.tapKey,
            onTap: () => unawaited(_tap()),
            radius: MallQuickAdd.height / 2,
            containedInkWell: label != null,
            highlightShape: label == null
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: label == null
                ? null
                : BorderRadius.circular(DesignTokens.buttonRadius),
            child: Center(child: visual),
          ),
        ),
      ),
    );
  }
}
