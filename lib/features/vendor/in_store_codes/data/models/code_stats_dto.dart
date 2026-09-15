import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/entities/code_stats.dart';

/// Wire shape of backend `CodeStatsVm`: `{ code, totalScans, scansLast7Days,
/// scansLast30Days, uniqueScanners, lastScannedUtc? }`.
class CodeStatsDto {
  const CodeStatsDto({
    required this.code,
    required this.totalScans,
    required this.scansLast7Days,
    required this.scansLast30Days,
    required this.uniqueScanners,
    this.lastScannedUtc,
  });

  factory CodeStatsDto.fromJson(Map<String, dynamic> json) => CodeStatsDto(
    code: readString(json['code']).toUpperCase(),
    totalScans: readInt(json['totalScans']),
    scansLast7Days: readInt(json['scansLast7Days']),
    scansLast30Days: readInt(json['scansLast30Days']),
    uniqueScanners: readInt(json['uniqueScanners']),
    lastScannedUtc: readDate(json['lastScannedUtc']),
  );

  final String code;
  final int totalScans;
  final int scansLast7Days;
  final int scansLast30Days;
  final int uniqueScanners;
  final DateTime? lastScannedUtc;

  CodeStats toDomain() => CodeStats(
    code: code,
    totalScans: totalScans,
    scansLast7Days: scansLast7Days,
    scansLast30Days: scansLast30Days,
    uniqueScanners: uniqueScanners,
    lastScannedUtc: lastScannedUtc,
  );
}
