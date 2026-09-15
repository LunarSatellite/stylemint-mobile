import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/data/qr_scan_info.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// How a scanned web-login QR ended.
enum QrLoginOutcome { approved, rejected, dismissed, failed }

/// Reports a scanned web-login [token], then asks the signed-in user to
/// approve or reject the login. Shows its own message when the login is
/// approved or fails. Backend: /v1/auth/qr/{token}/{scan|approve|reject}.
Future<QrLoginOutcome> approveQrLogin(
  BuildContext context,
  WidgetRef ref,
  String token,
) async {
  final ds = ref.read(qrLoginDataSourceProvider);
  try {
    final info = await ds.scan(token);
    if (!context.mounted) return QrLoginOutcome.dismissed;
    final approved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.s24),
        ),
      ),
      builder: (_) => _ConfirmSheet(info: info),
    );
    if (approved == null) return QrLoginOutcome.dismissed;
    if (approved) {
      await ds.approve(token);
      if (context.mounted) {
        SmSnackbar.success(context, 'Logged in on ${info.appLabel}.');
      }
      return QrLoginOutcome.approved;
    }
    await ds.reject(token);
    return QrLoginOutcome.rejected;
    // Any failure (network, expired token, bad payload) reads the same.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    if (context.mounted) {
      SmSnackbar.error(context, "Couldn't complete the login. Try again.");
    }
    return QrLoginOutcome.failed;
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.info});

  final QrScanInfo info;

  @override
  Widget build(BuildContext context) {
    final userAgent = info.creatorUserAgent;
    final ip = info.creatorIp;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.computer_rounded,
              color: DesignTokens.primaryGreen,
              size: 40,
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'Log in to ${info.appLabel}?',
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'A web browser is requesting to sign in to your account.',
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            if (userAgent != null) _row(Icons.public, userAgent),
            if (ip != null) _row(Icons.location_on_outlined, ip),
            const SizedBox(height: DesignTokens.s24),
            SmPrimaryButton(
              label: 'Approve',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.primaryGreen,
              labelColor: DesignTokens.buttonPrimaryText,
              onPressed: () async => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
              ),
              child: Text(
                'Reject',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: DesignTokens.iconLight),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ),
      ],
    ),
  );
}
