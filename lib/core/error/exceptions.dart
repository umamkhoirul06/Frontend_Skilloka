/// Exception classes for error handling
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ServerException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  final AuthExceptionType type;

  const AuthException({
    required this.message,
    this.type = AuthExceptionType.unknown,
  });

  @override
  String toString() => 'AuthException: $message (type: $type)';
}

enum AuthExceptionType {
  invalidCredentials,
  tokenExpired,
  unauthorized,
  accountLocked,
  unknown,
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  const ValidationException({required this.message, this.errors});

  @override
  String toString() => 'ValidationException: $message';
}

class SecurityException implements Exception {
  final String message;
  final SecurityExceptionType type;

  const SecurityException({
    required this.message,
    this.type = SecurityExceptionType.unknown,
  });

  @override
  String toString() => 'SecurityException: $message (type: $type)';
}

enum SecurityExceptionType {
  rootedDevice,
  jailbrokenDevice,
  sslPinningFailed,
  unknown,
}
