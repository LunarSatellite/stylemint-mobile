import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// Style Mint snackbar helpers — adapted from vpt-mydawa AppSnackbar.
abstract class SmSnackbar {
  static void success(BuildContext context, String message) =>
      _show(context, message, kSuccessColor, Icons.check_circle_outline);

  static void error(BuildContext context, String message, {int seconds = 3}) =>
      _show(context, message, kErrorColor, Icons.cancel_outlined, seconds: seconds);

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
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: Duration(seconds: seconds),
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
