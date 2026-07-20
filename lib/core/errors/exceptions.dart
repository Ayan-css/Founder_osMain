/// Error handling classes
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error occurred'])
      : super(code: 'NETWORK_ERROR');
}

class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Database error occurred'])
      : super(code: 'DATABASE_ERROR');
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication error'])
      : super(code: 'AUTH_ERROR');
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
  });
}

class SyncException extends AppException {
  const SyncException([super.message = 'Sync error occurred'])
      : super(code: 'SYNC_ERROR');
}
