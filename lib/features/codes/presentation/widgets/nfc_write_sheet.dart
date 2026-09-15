import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/nfc/nfc_link_writer.dart';
import 'package:stylemint_mobile_frontend/features/codes/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Writes [link] (a StyleMint link) to an NFC tag, reads it back, and says
/// how it went.
Future<void> showNfcWriteSheet(BuildContext context, {required String link}) =>
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: DesignTokens.bgAppBodyLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => NfcWriteSheet(link: link),
    );

class NfcWriteSheet extends ConsumerStatefulWidget {
  const NfcWriteSheet({required this.link, super.key});

  final String link;

  /// What to tell the person for each outcome.
  static String messageFor(NfcWriteOutcome outcome) => switch (outcome) {
    NfcWriteOutcome.written =>
      'Link written. Tap the tag with a phone to check it opens StyleMint.',
    NfcWriteOutcome.notSupported => "This phone can't write NFC tags.",
    NfcWriteOutcome.disabled =>
      "NFC is turned off. Turn it on in your phone's settings, then try "
          'again.',
    NfcWriteOutcome.timedOut =>
      'No tag found. Hold the tag flat against the back of the phone and '
          'try again.',
    NfcWriteOutcome.cancelled => 'Stopped. Nothing was written.',
    NfcWriteOutcome.notNdef =>
      "This tag can't store a link. Use an NTAG213, NTAG215 or NTAG216 "
          'sticker.',
    NfcWriteOutcome.readOnly => "This tag is locked and can't be changed.",
    NfcWriteOutcome.tooSmall =>
      'This tag is too small for the link. Use a tag with more memory.',
    NfcWriteOutcome.verifyFailed =>
      "The link didn't save correctly. Hold the tag still and try again.",
    NfcWriteOutcome.failed =>
      "Couldn't write the tag. Keep it still against the phone and try "
          'again.',
  };

  @override
  ConsumerState<NfcWriteSheet> createState() => _NfcWriteSheetState();
}

class _NfcWriteSheetState extends ConsumerState<NfcWriteSheet> {
  late final NfcLinkWriter _writer = NfcLinkWriter(
    ref.read(nfcTagSessionProvider),
  );

  /// Null while waiting for a tag.
  NfcWriteOutcome? _outcome;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_write());
  }

  @override
  void dispose() {
    // Closed another way (e.g. system back) while waiting: stop the reader.
    if (_outcome == null && !_closed) unawaited(_writer.cancel());
    super.dispose();
  }

  Future<void> _write() async {
    final outcome = await _writer.write(widget.link);
    if (!mounted || _closed) return;
    setState(() => _outcome = outcome);
  }

  void _retry() {
    setState(() => _outcome = null);
    unawaited(_write());
  }

  Future<void> _cancel() async {
    _closed = true;
    await _writer.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  void _close() {
    _closed = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome;
    final written = outcome == NfcWriteOutcome.written;
    final canRetry =
        outcome != null &&
        !written &&
        outcome != NfcWriteOutcome.notSupported;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s24,
          DesignTokens.s24,
          DesignTokens.s24,
          DesignTokens.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              outcome == null
                  ? Icons.contactless_outlined
                  : written
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              size: 56,
              color: outcome == null || written
                  ? DesignTokens.primaryGreen
                  : DesignTokens.colorError,
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              outcome == null
                  ? NfcLinkWriter.holdTagMessage
                  : written
                  ? 'Tag ready'
                  : "Tag wasn't written",
              textAlign: TextAlign.center,
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              outcome == null
                  ? 'Keep it still until this changes. The tag gets your '
                        'StyleMint link.'
                  : NfcWriteSheet.messageFor(outcome),
              textAlign: TextAlign.center,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              widget.link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(height: DesignTokens.s24),
            if (outcome == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => unawaited(_cancel()),
                  style: DesignTokens.outlinedButtonStyle(),
                  child: const Text('Cancel'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _close,
                      style: DesignTokens.outlinedButtonStyle(),
                      child: Text(written ? 'Done' : 'Close'),
                    ),
                  ),
                  if (canRetry) ...[
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _retry,
                        style: DesignTokens.primaryButtonStyle(),
                        child: const Text('Try again'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
