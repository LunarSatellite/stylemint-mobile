import 'dart:convert';

/// NFC on this phone.
enum NfcAvailability { available, disabled, notSupported }

/// The tag a phone is holding, as far as writing a link is concerned.
class NfcTagInfo {
  const NfcTagInfo({
    required this.ndefAvailable,
    required this.ndefWritable,
    this.ndefCapacity,
  });

  /// Whether the tag holds, or can hold, NDEF records.
  final bool ndefAvailable;
  final bool ndefWritable;

  /// Room for an NDEF message in bytes; null or 0 when the tag didn't say.
  final int? ndefCapacity;
}

/// Why an NFC session call didn't complete.
enum NfcSessionError { timeout, cancelled, failed }

class NfcSessionException implements Exception {
  const NfcSessionException(this.error);

  final NfcSessionError error;

  @override
  String toString() => 'NfcSessionException($error)';
}

/// The phone's NFC reader as [NfcLinkWriter] uses it. Implemented over
/// flutter_nfc_kit in the data layer; tests use a fake. Calls throw
/// [NfcSessionException] when the reader gives up.
abstract interface class NfcTagSession {
  Future<NfcAvailability> availability();

  /// Waits for a tag, showing [iosAlertMessage] in the iOS reader sheet.
  Future<NfcTagInfo> poll({
    required Duration timeout,
    required String iosAlertMessage,
  });

  /// Replaces the tag's NDEF message with a single URI record.
  Future<void> writeUri(String uri);

  /// The URI records on the tag, read from the tag itself.
  Future<List<String>> readUris();

  /// Ends the session. An [iosErrorMessage] marks it failed on iOS.
  Future<void> finish({String? iosAlertMessage, String? iosErrorMessage});
}

/// How writing a link to a tag ended.
enum NfcWriteOutcome {
  /// Written, and read back unchanged.
  written,
  notSupported,
  disabled,
  timedOut,
  cancelled,

  /// The tag can't hold a link (no NDEF).
  notNdef,

  /// The tag is locked.
  readOnly,

  /// The link doesn't fit on the tag.
  tooSmall,

  /// The tag didn't read back the link that was written.
  verifyFailed,
  failed,
}

/// Writes a StyleMint link to an NFC tag and reads it back to check it.
class NfcLinkWriter {
  NfcLinkWriter(this._session, {this.timeout = const Duration(seconds: 30)});

  static const String holdTagMessage =
      'Hold an NFC tag to the back of the phone';

  final NfcTagSession _session;
  final Duration timeout;

  Future<NfcWriteOutcome> write(String link) async {
    final NfcAvailability availability;
    try {
      availability = await _session.availability();
    } on Object catch (_) {
      return NfcWriteOutcome.notSupported;
    }
    switch (availability) {
      case NfcAvailability.notSupported:
        return NfcWriteOutcome.notSupported;
      case NfcAvailability.disabled:
        return NfcWriteOutcome.disabled;
      case NfcAvailability.available:
        break;
    }

    try {
      final tag = await _session.poll(
        timeout: timeout,
        iosAlertMessage: holdTagMessage,
      );
      if (!tag.ndefAvailable) return _end(NfcWriteOutcome.notNdef);
      if (!tag.ndefWritable) return _end(NfcWriteOutcome.readOnly);
      final capacity = tag.ndefCapacity ?? 0;
      if (capacity > 0 && capacity < ndefUriMessageBytes(link)) {
        return _end(NfcWriteOutcome.tooSmall);
      }
      await _session.writeUri(link);
      final onTag = await _session.readUris();
      if (!onTag.map((uri) => uri.trim()).contains(link)) {
        return _end(NfcWriteOutcome.verifyFailed);
      }
      return _end(NfcWriteOutcome.written);
    } on NfcSessionException catch (e) {
      return _end(switch (e.error) {
        NfcSessionError.timeout => NfcWriteOutcome.timedOut,
        NfcSessionError.cancelled => NfcWriteOutcome.cancelled,
        NfcSessionError.failed => NfcWriteOutcome.failed,
      });
    } on Object catch (_) {
      return _end(NfcWriteOutcome.failed);
    }
  }

  /// Stops waiting for a tag.
  Future<void> cancel() async {
    try {
      await _session.finish(iosErrorMessage: 'Cancelled');
    } on Object catch (_) {
      // The session may already be over.
    }
  }

  Future<NfcWriteOutcome> _end(NfcWriteOutcome outcome) async {
    final ok = outcome == NfcWriteOutcome.written;
    try {
      await _session.finish(
        iosAlertMessage: ok ? 'StyleMint link written' : null,
        iosErrorMessage: ok ? null : "Couldn't write the tag",
      );
    } on Object catch (_) {
      // The outcome stands either way.
    }
    return outcome;
  }

  /// Bytes an NDEF message with one URI record for [link] takes on a tag:
  /// record header, type length, payload length (1 byte, or 4 past 255),
  /// the `U` type, then the payload — a prefix code standing for `https://`
  /// and the rest of the link.
  static int ndefUriMessageBytes(String link) {
    const https = 'https://';
    final rest = link.startsWith(https) ? link.substring(https.length) : link;
    final payload = 1 + utf8.encode(rest).length;
    final lengthBytes = payload > 255 ? 4 : 1;
    return 1 + 1 + lengthBytes + 1 + payload;
  }
}
