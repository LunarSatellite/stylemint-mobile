import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/reel_share_targets.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// How StyleMint's share sheet was closed.
enum ReelShareOutcome {
  /// The link was copied.
  copied,

  /// An app was opened with the message (or the phone's share menu shown).
  sent,

  /// The chosen app could not be opened.
  failed,

  /// Closed without sharing.
  dismissed,
}

/// Opens apps for [ReelShareSheet]. An interface so the sheet can be tested
/// without platform channels.
abstract interface class ReelShareLauncher {
  Future<bool> canOpen(Uri uri);

  Future<bool> open(Uri uri);

  /// Opens the Android app [package]'s own share screen with [text]. False
  /// when the app is not installed or the platform can't do this.
  Future<bool> shareToApp(String package, String text);

  /// The phone's own share menu, for apps without a share link (Instagram,
  /// TikTok, Messenger, ...).
  Future<void> shareText(String text);
}

class DefaultReelShareLauncher implements ReelShareLauncher {
  const DefaultReelShareLauncher();

  static const MethodChannel _channel = MethodChannel('app.stylemint/share');

  @override
  Future<bool> canOpen(Uri uri) async {
    try {
      return await canLaunchUrl(uri);
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> shareToApp(String package, String text) async {
    try {
      final shared = await _channel.invokeMethod<bool>('shareText', {
        'package': package,
        'text': text,
      });
      return shared ?? false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

/// Opens StyleMint's share sheet for a reel: send [message] (which carries
/// the StyleMint [link]) to WhatsApp or Viber (when installed), Facebook or
/// Messages, open the
/// phone's share menu for other apps, or copy the link (owner decision,
/// 2026-09-15). Every option shares the StyleMint link, never the platform's.
Future<ReelShareOutcome> showReelShareSheet(
  BuildContext context, {
  required Uri link,
  required String message,
  ReelShareLauncher launcher = const DefaultReelShareLauncher(),
}) async {
  final outcome = await showModalBottomSheet<ReelShareOutcome>(
    context: context,
    // Sized to its content rather than capped at 9/16 of the screen, so the
    // app row, link and button never overflow on short screens.
    isScrollControlled: true,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.s24),
      ),
    ),
    builder: (_) =>
        ReelShareSheet(link: link, message: message, launcher: launcher),
  );
  return outcome ?? ReelShareOutcome.dismissed;
}

class ReelShareSheet extends StatefulWidget {
  const ReelShareSheet({
    required this.link,
    required this.message,
    this.launcher = const DefaultReelShareLauncher(),
    super.key,
  });

  static const String title = 'Share reel';
  static const String copyLabel = 'Copy link';
  static const String moreLabel = 'More apps';
  static const String copiedMessage = 'Link copied';
  static const String failedMessage =
      "Couldn't open that app. Copy the link instead.";
  static const Key copyKey = ValueKey('reel-share-copy');
  static const Key moreKey = ValueKey('reel-share-more');
  static Key targetKey(ReelShareTarget target) =>
      ValueKey('reel-share-${target.name}');

  final Uri link;
  final String message;
  final ReelShareLauncher launcher;

  @override
  State<ReelShareSheet> createState() => _ReelShareSheetState();
}

class _ReelShareSheetState extends State<ReelShareSheet> {
  /// Targets that need their app installed, and whether it is.
  final Map<ReelShareTarget, bool> _installed = {};

  @override
  void initState() {
    super.initState();
    for (final target in ReelShareTarget.values) {
      final probe = target.installedProbe;
      if (probe == null) continue;
      widget.launcher
          .canOpen(probe)
          .catchError((Object _) => false)
          .then((available) {
            if (mounted) setState(() => _installed[target] = available);
          });
    }
  }

  void _close(ReelShareOutcome outcome) {
    if (mounted) Navigator.of(context).pop(outcome);
  }

  Future<void> _send(ReelShareTarget target) async {
    final launcher = widget.launcher;
    final package = target.androidPackage;
    if (package != null && defaultTargetPlatform == TargetPlatform.android) {
      final text = target.appShareText(
        link: widget.link,
        message: widget.message,
      );
      if (await launcher.shareToApp(package, text)) {
        _close(ReelShareOutcome.sent);
        return;
      }
    }
    final opened = await launcher.open(
      target.uri(link: widget.link, message: widget.message),
    );
    _close(opened ? ReelShareOutcome.sent : ReelShareOutcome.failed);
  }

  Future<void> _more() async {
    _close(ReelShareOutcome.sent);
    await widget.launcher.shareText(widget.message);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link.toString()));
    _close(ReelShareOutcome.copied);
  }

  @override
  Widget build(BuildContext context) {
    final targets = [
      for (final target in ReelShareTarget.values)
        if (!target.needsInstalledApp || (_installed[target] ?? false)) target,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s24,
          DesignTokens.s12,
          DesignTokens.s24,
          DesignTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            const Text(
              ReelShareSheet.title,
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Anyone with the link can watch this reel on StyleMint.',
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Row(
              children: [
                for (final target in targets)
                  Expanded(
                    child: _TargetButton(
                      key: ReelShareSheet.targetKey(target),
                      label: target.label,
                      badge: _TargetBadge(target),
                      onTap: () => _send(target),
                    ),
                  ),
                Expanded(
                  child: _TargetButton(
                    key: ReelShareSheet.moreKey,
                    label: ReelShareSheet.moreLabel,
                    badge: const _Disc(
                      color: DesignTokens.bgAppBodyLight,
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    onTap: _more,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            Container(
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.s12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 20,
                    color: DesignTokens.primaryGreen,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Text(
                      widget.link.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: ReelShareSheet.copyKey,
                style: DesignTokens.primaryButtonStyle(),
                onPressed: _copy,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text(ReelShareSheet.copyLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetButton extends StatelessWidget {
  const _TargetButton({
    required this.label,
    required this.badge,
    required this.onTap,
    super.key,
  });

  final String label;
  final Widget badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              badge,
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A target's app logo on its brand colour.
class _TargetBadge extends StatelessWidget {
  const _TargetBadge(this.target);

  final ReelShareTarget target;

  static const _white = ColorFilter.mode(Colors.white, BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    return switch (target) {
      ReelShareTarget.whatsApp => const _Disc(
        color: Color(0xFF25D366),
        child: _Logo('assets/icons/whatsapp.svg', filter: _white),
      ),
      // Facebook's logo is already its blue disc.
      ReelShareTarget.facebook => SvgPicture.asset(
        'assets/icons/facebook.svg',
        width: _Disc.size,
        height: _Disc.size,
      ),
      ReelShareTarget.viber => const _Disc(
        color: Color(0xFF7360F2),
        child: _Logo('assets/icons/viber.svg', filter: _white),
      ),
      ReelShareTarget.messages => const _Disc(
        color: DesignTokens.primaryGreen,
        child: Icon(
          Icons.sms_rounded,
          color: DesignTokens.buttonPrimaryText,
        ),
      ),
    };
  }
}

class _Logo extends StatelessWidget {
  const _Logo(this.asset, {required this.filter});

  final String asset;
  final ColorFilter filter;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(asset, width: 26, height: 26, colorFilter: filter);
}

class _Disc extends StatelessWidget {
  const _Disc({required this.color, required this.child});

  static const double size = 52;

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: child,
  );
}
