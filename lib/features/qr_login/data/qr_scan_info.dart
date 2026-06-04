/// Confirmation-screen info returned by POST /v1/auth/qr/{token}/scan.
class QrScanInfo {
  const QrScanInfo({
    required this.targetApp,
    required this.webPlatform,
    this.creatorIp,
    this.creatorUserAgent,
    required this.expiresUtc,
  });

  /// 1 = Brand Studio, 2 = Creator Studio.
  final int targetApp;

  /// DevicePlatform enum int (3 = Web).
  final int webPlatform;
  final String? creatorIp;
  final String? creatorUserAgent;
  final DateTime expiresUtc;

  String get appLabel => switch (targetApp) {
        1 => 'Brand Studio',
        2 => 'Creator Studio',
        _ => 'Style Mint web',
      };

  factory QrScanInfo.fromJson(Map<String, dynamic> json) => QrScanInfo(
        targetApp: (json['targetApp'] as num?)?.toInt() ?? 0,
        webPlatform: (json['webPlatform'] as num?)?.toInt() ?? 0,
        creatorIp: json['creatorIp'] as String?,
        creatorUserAgent: json['creatorUserAgent'] as String?,
        expiresUtc: DateTime.tryParse(json['expiresUtc']?.toString() ?? '')
                ?.toLocal() ??
            DateTime.now(),
      );
}
