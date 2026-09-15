/// How often a code has been opened (backend `CodeStatsVm`). Scans keep no
/// IP address, device or location; people are counted only when signed in.
class CodeStats {
  const CodeStats({
    required this.code,
    required this.totalScans,
    required this.scansLast7Days,
    required this.scansLast30Days,
    required this.uniqueScanners,
    this.lastScannedUtc,
  });

  final String code;
  final int totalScans;
  final int scansLast7Days;
  final int scansLast30Days;
  final int uniqueScanners;
  final DateTime? lastScannedUtc;
}
