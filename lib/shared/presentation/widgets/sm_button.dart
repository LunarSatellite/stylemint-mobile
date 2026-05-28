import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../core/utils/size_config.dart';

bool _isTablet(BuildContext ctx) =>
    MediaQuery.of(ctx).size.shortestSide >= 600;

// ── SmPrimaryButton ───────────────────────────────────────────────────────────
/// Full-width primary button with built-in loading state.
/// Adapted from vpt-mydawa PrimaryButton.
class SmPrimaryButton extends StatefulWidget {
  const SmPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.labelColor,
    this.height,
    this.width,
    this.color,
    this.labelWeight,
    this.labelSize,
    this.borderRadius,
    this.elevation,
    this.prefixIcon,
    this.suffixIcon,
    this.padding,
    this.disabled = false,
    this.isLoadingInitially = false,
  });

  final String label;
  final Future<void> Function() onPressed;
  final Color? labelColor;
  final double? height;
  final double? width;
  final Color? color;
  final FontWeight? labelWeight;
  final double? labelSize;
  final double? borderRadius;
  final double? elevation;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsets? padding;
  final bool disabled;
  final bool isLoadingInitially;

  @override
  State<SmPrimaryButton> createState() => _SmPrimaryButtonState();
}

class _SmPrimaryButtonState extends State<SmPrimaryButton> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = widget.isLoadingInitially;
  }

  Future<void> _handlePress() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    final config = SizeConfig(context);
    final h = widget.height ?? (tablet ? 58 : 52);
    final fs = widget.labelSize ?? (tablet ? 18.0 : 16.0);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.disabled
            ? kGrey300
            : (widget.color ?? kPrimaryColor),
        elevation: widget.elevation ?? 0,
        minimumSize: widget.padding == null
            ? Size(widget.width ?? double.infinity, h)
            : null,
        padding: widget.padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 360),
        ),
      ),
      onPressed: (_loading || widget.disabled) ? null : _handlePress,
      child: _loading
          ? CupertinoActivityIndicator(color: widget.labelColor ?? Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  config.horizontalSpaceSmall(),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: fs,
                    fontWeight: widget.labelWeight ?? FontWeight.w600,
                    color: widget.labelColor ?? Colors.white,
                  ),
                ),
                if (widget.suffixIcon != null) ...[
                  config.horizontalSpaceSmall(),
                  widget.suffixIcon!,
                ],
              ],
            ),
    );
  }
}

// ── SmOutlinedButton ──────────────────────────────────────────────────────────
class SmOutlinedButton extends StatelessWidget {
  const SmOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.labelColor,
    this.borderColor,
    this.height,
    this.width,
    this.borderRadius,
    this.labelStyle,
    this.prefixIcon,
    this.padding,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? labelColor;
  final Color? borderColor;
  final double? height;
  final double? width;
  final double? borderRadius;
  final TextStyle? labelStyle;
  final Widget? prefixIcon;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    final h = height ?? (tablet ? 58 : 52);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: labelColor ?? kPrimaryColor,
        side: BorderSide(color: borderColor ?? kPrimaryColor),
        minimumSize: Size(width ?? double.infinity, h),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 360),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prefixIcon != null) ...[
            prefixIcon!,
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: labelStyle ??
                TextStyle(
                  fontSize: tablet ? 17 : 15,
                  fontWeight: FontWeight.w600,
                  color: labelColor ?? kPrimaryColor,
                ),
          ),
        ],
      ),
    );
  }
}

// ── SmTextButton ──────────────────────────────────────────────────────────────
class SmTextButton extends StatelessWidget {
  const SmTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.labelColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: labelColor ?? kPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
