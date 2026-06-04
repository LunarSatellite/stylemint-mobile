import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/data/qr_scan_info.dart';

/// Mobile (authenticated) side of cross-device QR login. The web shows a QR;
/// scanning it yields a public token which the app reports here, then the user
/// approves or rejects. See backend docs/QR_LOGIN_API.md.
class QrLoginRemoteDataSource {
  QrLoginRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// Parses the `stylemint://qr-login?token=…&app=…` payload to its public
  /// token. Returns null if the payload isn't a Style Mint QR login.
  static String? parseToken(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final isQrLogin = (uri.scheme == 'stylemint' && uri.host == 'qr-login') ||
        uri.path.contains('qr-login');
    if (!isQrLogin) return null;
    final token = uri.queryParameters['token'];
    return (token != null && token.isNotEmpty) ? token : null;
  }

  /// POST /v1/auth/qr/{token}/scan — authenticated.
  Future<QrScanInfo> scan(String publicToken) async {
    final response = await apiClient.post('/v1/auth/qr/$publicToken/scan');
    return QrScanInfo.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/auth/qr/{token}/approve — authenticated.
  Future<void> approve(String publicToken) =>
      apiClient.post('/v1/auth/qr/$publicToken/approve');

  /// POST /v1/auth/qr/{token}/reject — authenticated.
  Future<void> reject(String publicToken) =>
      apiClient.post('/v1/auth/qr/$publicToken/reject');
}
