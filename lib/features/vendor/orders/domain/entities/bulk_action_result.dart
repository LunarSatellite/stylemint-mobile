/// Result of a Vendor §3B/§3C bulk sub-order action. The backend returns an
/// outer 200 with a per-row result even when some ids fail individually —
/// this collapses that into a simple succeeded/failed split for the UI.
class BulkActionResult {
  const BulkActionResult({required this.succeededIds, required this.failed});

  final List<String> succeededIds;

  /// orderId -> error message/code.
  final Map<String, String> failed;

  int get successCount => succeededIds.length;
  int get failureCount => failed.length;
}
