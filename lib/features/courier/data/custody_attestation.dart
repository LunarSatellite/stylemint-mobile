/// Chain-of-custody event kinds. Values must match the backend's
/// `ChainEventKind`, because the number goes into the signed attestation.
enum ChainEventKind {
  sealApplied(1),
  pickedUp(2),
  handedOff(3),
  deliveryConfirmed(4),
  exception(5),
  returnInitiated(6);

  const ChainEventKind(this.wire);

  final int wire;
}

/// Builds the exact string a courier device signs for a custody event.
///
/// This is a byte-for-byte mirror of the backend's
/// `ChainPayloadSerializer.CanonicalizeAttestation`. The server rebuilds the
/// same string from its own columns and verifies the signature against it, so
/// a single byte of difference fails verification with no useful error — the
/// response is just "Signature verification failed". The published algorithm
/// at `GET /v1/deliveries/custody-proof/rules`, step 6, is the contract.
///
/// Four details that are easy to get wrong and produce exactly that failure:
///
/// - **`event_kind` is quoted.** The backend passes it through its string
///   field writer (`((int)eventKind).ToString()`), so it serialises as
///   `"event_kind":"2"`, not `"event_kind":2`.
/// - **GUIDs are lowercase with hyphens** — .NET's `ToString("D")`. An
///   uppercase or brace-wrapped id is a different string.
/// - **A missing courier is the JSON literal `null`**, not `""` and not an
///   omitted key. The field is always present.
/// - **No whitespace anywhere**, and the field order is fixed: package_id,
///   event_kind, from_courier_id, to_courier_id, geohash_at_event.
///
/// Deliberately hand-built rather than passed through `jsonEncode` of a map:
/// Dart map iteration order would hold today and the encoder adds no spaces,
/// but neither is a guarantee anyone would think to check, and the failure
/// mode is silent. Writing the bytes out makes the contract visible.
String buildCustodyAttestation({
  required String packageId,
  required ChainEventKind eventKind,
  required String? fromCourierProfileId,
  required String? toCourierProfileId,
  required String geohashAtEvent,
}) {
  final buffer = StringBuffer('{');
  buffer.write('"package_id":${_jsonString(packageId)},');
  buffer.write('"event_kind":${_jsonString('${eventKind.wire}')},');
  buffer.write('"from_courier_id":${_jsonGuidOrNull(fromCourierProfileId)},');
  buffer.write('"to_courier_id":${_jsonGuidOrNull(toCourierProfileId)},');
  buffer.write('"geohash_at_event":${_jsonString(geohashAtEvent)}');
  buffer.write('}');
  return buffer.toString();
}

String _jsonGuidOrNull(String? id) {
  final trimmed = id?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'null';
  // Lowercase to match .NET's "D" format. Ids reaching here come from our own
  // API and are already lowercase; normalising costs nothing and removes a
  // whole class of failure if one ever arrives cased differently.
  return _jsonString(trimmed.toLowerCase());
}

/// Minimal JSON string encoding, matching what the server's writer emits for
/// the values this attestation carries — GUIDs, a small integer rendered as
/// text, and a base-32 geohash. All are plain ASCII with nothing to escape, so
/// the quotes are the whole job; the escapes are here so a surprising value
/// produces valid JSON rather than a malformed attestation.
String _jsonString(String value) {
  final out = StringBuffer('"');
  for (final rune in value.runes) {
    switch (rune) {
      case 0x22:
        out.write(r'\"');
      case 0x5C:
        out.write(r'\\');
      case 0x0A:
        out.write(r'\n');
      case 0x0D:
        out.write(r'\r');
      case 0x09:
        out.write(r'\t');
      default:
        if (rune < 0x20) {
          out.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
        } else {
          out.writeCharCode(rune);
        }
    }
  }
  out.write('"');
  return out.toString();
}
