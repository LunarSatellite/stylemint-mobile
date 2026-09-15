import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/nfc/nfc_link_writer.dart';

const _link = 'https://stylemint.voyageritnepal.com/c/ABCD2345?via=nfc';

class _FakeSession implements NfcTagSession {
  NfcAvailability availabilityResult = NfcAvailability.available;
  Exception? availabilityError;
  NfcTagInfo tag = const NfcTagInfo(
    ndefAvailable: true,
    ndefWritable: true,
    ndefCapacity: 137,
  );
  Exception? pollError;
  Exception? writeError;
  Exception? finishError;

  /// What the tag reads back; null echoes what was written.
  List<String>? readBack;

  final List<String> written = [];
  final List<({String? alert, String? error})> finishes = [];
  int polls = 0;
  String? pollAlert;

  @override
  Future<NfcAvailability> availability() async {
    final error = availabilityError;
    if (error != null) throw error;
    return availabilityResult;
  }

  @override
  Future<NfcTagInfo> poll({
    required Duration timeout,
    required String iosAlertMessage,
  }) async {
    polls++;
    pollAlert = iosAlertMessage;
    final error = pollError;
    if (error != null) throw error;
    return tag;
  }

  @override
  Future<void> writeUri(String uri) async {
    final error = writeError;
    if (error != null) throw error;
    written.add(uri);
  }

  @override
  Future<List<String>> readUris() async => readBack ?? List.of(written);

  @override
  Future<void> finish({
    String? iosAlertMessage,
    String? iosErrorMessage,
  }) async {
    finishes.add((alert: iosAlertMessage, error: iosErrorMessage));
    final error = finishError;
    if (error != null) throw error;
  }
}

void main() {
  late _FakeSession session;
  late NfcLinkWriter writer;

  setUp(() {
    session = _FakeSession();
    writer = NfcLinkWriter(session);
  });

  test('writes the link, reads it back and ends the session', () async {
    final outcome = await writer.write(_link);

    expect(outcome, NfcWriteOutcome.written);
    expect(session.written, [_link]);
    expect(session.pollAlert, NfcLinkWriter.holdTagMessage);
    expect(session.finishes.single.error, isNull);
    expect(session.finishes.single.alert, isNotNull);
  });

  test('NFC switched off or missing never waits for a tag', () async {
    session.availabilityResult = NfcAvailability.disabled;
    expect(await writer.write(_link), NfcWriteOutcome.disabled);

    session.availabilityResult = NfcAvailability.notSupported;
    expect(await writer.write(_link), NfcWriteOutcome.notSupported);

    session.availabilityError = Exception('no plugin');
    expect(await writer.write(_link), NfcWriteOutcome.notSupported);

    expect(session.polls, 0);
    expect(session.written, isEmpty);
  });

  test('tags that cannot take the link are not written', () async {
    session.tag = const NfcTagInfo(ndefAvailable: false, ndefWritable: false);
    expect(await writer.write(_link), NfcWriteOutcome.notNdef);

    session.tag = const NfcTagInfo(ndefAvailable: true, ndefWritable: false);
    expect(await writer.write(_link), NfcWriteOutcome.readOnly);

    session.tag = const NfcTagInfo(
      ndefAvailable: true,
      ndefWritable: true,
      ndefCapacity: 20,
    );
    expect(await writer.write(_link), NfcWriteOutcome.tooSmall);

    expect(session.written, isEmpty);
    expect(session.finishes.every((f) => f.error != null), isTrue);
  });

  test('a tag that does not report its size is still written', () async {
    session.tag = const NfcTagInfo(
      ndefAvailable: true,
      ndefWritable: true,
      ndefCapacity: 0,
    );

    expect(await writer.write(_link), NfcWriteOutcome.written);
  });

  test('a read-back that differs is reported', () async {
    session.readBack = ['https://example.com/'];

    expect(await writer.write(_link), NfcWriteOutcome.verifyFailed);
    expect(session.finishes.single.error, isNotNull);
  });

  test('reader errors map to clear outcomes', () async {
    session.pollError = const NfcSessionException(NfcSessionError.timeout);
    expect(await writer.write(_link), NfcWriteOutcome.timedOut);

    session.pollError = const NfcSessionException(NfcSessionError.cancelled);
    expect(await writer.write(_link), NfcWriteOutcome.cancelled);

    session
      ..pollError = null
      ..writeError = const NfcSessionException(NfcSessionError.failed);
    expect(await writer.write(_link), NfcWriteOutcome.failed);

    session.writeError = Exception('tag lost');
    expect(await writer.write(_link), NfcWriteOutcome.failed);
  });

  test('a failing finish does not change the outcome', () async {
    session.finishError = Exception('already closed');

    expect(await writer.write(_link), NfcWriteOutcome.written);
  });

  test('cancel ends the session and ignores a closed one', () async {
    await writer.cancel();
    session.finishError = Exception('already closed');
    await writer.cancel();

    expect(session.finishes, hasLength(2));
    expect(session.finishes.first.error, isNotNull);
  });

  test('counts the NDEF bytes a link needs', () {
    // 5 bytes of record overhead plus the link without "https://".
    expect(NfcLinkWriter.ndefUriMessageBytes(_link), 52);

    final long = 'https://stylemint.voyageritnepal.com/${'x' * 300}';
    final rest = long.length - 'https://'.length;
    expect(NfcLinkWriter.ndefUriMessageBytes(long), 1 + 1 + 4 + 1 + 1 + rest);
  });
}
