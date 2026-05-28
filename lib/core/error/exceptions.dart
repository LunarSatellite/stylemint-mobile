/// Raw exceptions thrown inside data/datasources before being mapped
/// to [Failure] inside the repository impl.

class NetworkException implements Exception {
  const NetworkException([this.message]);
  final String? message;
}

class AuthException implements Exception {
  const AuthException([this.message]);
  final String? message;
}

class ServerException implements Exception {
  const ServerException([this.message]);
  final String? message;
}
