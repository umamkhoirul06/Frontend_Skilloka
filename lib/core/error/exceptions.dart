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

class LocationException implements Exception {
  final String message;
  final LocationExceptionType type;

  const LocationException({
    required this.message,
    this.type = LocationExceptionType.unknown,
  });

  @override
  String toString() => 'LocationException: $message (type: $type)';
}

enum LocationExceptionType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// Helper untuk menghasilkan pesan error yang rapih, sopan, dan informatif bagi pengguna
class AppExceptionHandler {
  static String getFriendlyMessage(dynamic error) {
    if (error is LocationException) {
      return error.message;
    }
    if (error is NetworkException) {
      return 'Tidak dapat terhubung ke internet. Periksa koneksi data atau Wi-Fi Anda.';
    }
    if (error is ServerException) {
      if (error.statusCode == 404) {
        return 'Data pelatihan atau LPK tidak ditemukan di server.';
      }
      if (error.statusCode == 500) {
        return 'Server Skilloka sedang dalam pemeliharaan. Silakan coba sesaat lagi.';
      }
      return error.message.isNotEmpty
          ? error.message
          : 'Terjadi kendala pada server (Status: ${error.statusCode ?? 'unknown'}).';
    }
    if (error is AuthException) {
      if (error.type == AuthExceptionType.tokenExpired) {
        return 'Sesi login telah berakhir. Silakan masuk kembali.';
      }
      if (error.type == AuthExceptionType.unauthorized) {
        return 'Akses ditolak. Anda tidak memiliki izin untuk tindakan ini.';
      }
      return error.message;
    }
    if (error is ValidationException) {
      return error.message;
    }
    return error?.toString() ?? 'Terjadi kesalahan sistem yang tidak diketahui.';
  }
}
