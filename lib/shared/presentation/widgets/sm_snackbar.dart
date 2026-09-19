import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// Style Mint snackbar helpers — adapted from vpt-mydawa AppSnackbar.
abstract class SmSnackbar {
  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message,
    kSuccessColor,
    Icons.check_circle_outline,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void error(BuildContext context, String message, {int seconds = 3}) =>
      _show(
        context,
        message,
        kErrorColor,
        Icons.cancel_outlined,
        seconds: seconds,
      );

  static void warning(BuildContext context, String message) =>
      _show(context, message, kWarningColor, Icons.warning_amber_outlined);

  static void info(BuildContext context, String message) =>
      _show(context, message, kInfoColor, Icons.info_outline);

  static void _show(
    BuildContext context,
    String message,
    Color bg,
    IconData icon, {
    int seconds = 2,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Status fills are bright brand tokens (green, yellow): pick dark or white
    // content by the fill's brightness so every variant stays legible.
    final foreground =
        ThemeData.estimateBrightnessForColor(bg) == Brightness.light
        ? kTextInverse
        : Colors.white;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: Duration(seconds: seconds),
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: foreground,
                  onPressed: onAction,
                )
              : null,
          content: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: foreground, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
