import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
// flutter_nfc_kit writes and returns records typed by its own `ndef`
// dependency, so the record classes come from there.
// ignore: depend_on_referenced_packages
import 'package:ndef/ndef.dart' as ndef;
import 'package:stylemint_mobile_frontend/features/codes/domain/nfc/nfc_link_writer.dart';

/// [NfcTagSession] over flutter_nfc_kit.
class FlutterNfcKitSession implements NfcTagSession {
  const FlutterNfcKitSession();

  @override
  Future<NfcAvailability> availability() async =>
      switch (await FlutterNfcKit.nfcAvailability) {
        NFCAvailability.available => NfcAvailability.available,
        NFCAvailability.disabled => NfcAvailability.disabled,
        NFCAvailability.not_supported => NfcAvailability.notSupported,
      };

  @override
  Future<NfcTagInfo> poll({
    required Duration timeout,
    required String iosAlertMessage,
  }) => _guard(() async {
    final tag = await FlutterNfcKit.poll(
      timeout: timeout,
      iosAlertMessage: iosAlertMessage,
      // Link stickers (NTAG21x) are ISO 14443-A; skip ISO 14443-B, which
      // never carries one.
      readIso14443B: false,
    );
    return NfcTagInfo(
      ndefAvailable: tag.ndefAvailable ?? false,
      ndefWritable: tag.ndefWritable ?? false,
      ndefCapacity: tag.ndefCapacity,
    );
  });

  @override
  Future<void> writeUri(String uri) => _guard(
    () => FlutterNfcKit.writeNDEFRecords([ndef.UriRecord.fromString(uri)]),
  );

  @override
  Future<List<String>> readUris() => _guard(() async {
    final records = await FlutterNfcKit.readNDEFRecords(cached: false);
    return records
        .whereType<ndef.UriRecord>()
        .map((record) => record.uriString)
        .whereType<String>()
        .toList(growable: false);
  });

  @override
  Future<void> finish({String? iosAlertMessage, String? iosErrorMessage}) =>
      FlutterNfcKit.finish(
        iosAlertMessage: iosAlertMessage,
        iosErrorMessage: iosErrorMessage,
      );

  /// flutter_nfc_kit reports a poll timeout as `408` and a session the
  /// person closed as `409`; anything else is a failed read or write.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      throw NfcSessionException(switch (e.code) {
        '408' => NfcSessionError.timeout,
        '409' => NfcSessionError.cancelled,
        _ => NfcSessionError.failed,
      });
    }
  }
}
