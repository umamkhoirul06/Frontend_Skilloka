/// Failure classes for domain layer error handling
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, super.code, this.statusCode});

  @override
  List<Object?> get props => [message, code, statusCode];

  factory ServerFailure.fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return const ServerFailure(
          message: 'Permintaan tidak valid',
          code: 'BAD_REQUEST',
          statusCode: 400,
        );
      case 401:
        return const ServerFailure(
          message: 'Sesi telah berakhir, silakan login kembali',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
      case 403:
        return const ServerFailure(
          message: 'Akses ditolak',
          code: 'FORBIDDEN',
          statusCode: 403,
        );
      case 404:
        return const ServerFailure(
          message: 'Data tidak ditemukan',
          code: 'NOT_FOUND',
          statusCode: 404,
        );
      case 422:
        return const ServerFailure(
          message: 'Data yang dikirim tidak valid',
          code: 'VALIDATION_ERROR',
          statusCode: 422,
        );
      case 500:
        return const ServerFailure(
          message: 'Terjadi kesalahan pada server',
          code: 'SERVER_ERROR',
          statusCode: 500,
        );
      case 503:
        return const ServerFailure(
          message: 'Server sedang dalam perbaikan',
          code: 'SERVICE_UNAVAILABLE',
          statusCode: 503,
        );
      default:
        return ServerFailure(
          message: 'Terjadi kesalahan (kode: $statusCode)',
          code: 'UNKNOWN',
          statusCode: statusCode,
        );
    }
  }
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Gagal mengakses data lokal',
    super.code = 'CACHE_ERROR',
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Tidak ada koneksi internet',
    super.code = 'NO_NETWORK',
  });
}

class AuthFailure extends Failure {
  final AuthFailureType type;

  const AuthFailure({
    required super.message,
    super.code,
    this.type = AuthFailureType.unknown,
  });

  @override
  List<Object?> get props => [message, code, type];

  factory AuthFailure.tokenExpired() => const AuthFailure(
    message: 'Sesi telah berakhir, silakan login kembali',
    code: 'TOKEN_EXPIRED',
    type: AuthFailureType.tokenExpired,
  );

  factory AuthFailure.invalidCredentials() => const AuthFailure(
    message: 'Email atau password salah',
    code: 'INVALID_CREDENTIALS',
    type: AuthFailureType.invalidCredentials,
  );

  factory AuthFailure.biometricNotAvailable() => const AuthFailure(
    message: 'Autentikasi biometrik tidak tersedia',
    code: 'BIOMETRIC_NOT_AVAILABLE',
    type: AuthFailureType.biometricNotAvailable,
  );
}

enum AuthFailureType {
  invalidCredentials,
  tokenExpired,
  unauthorized,
  accountLocked,
  biometricNotAvailable,
  unknown,
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

class SecurityFailure extends Failure {
  final SecurityFailureType type;

  const SecurityFailure({
    required super.message,
    super.code,
    this.type = SecurityFailureType.unknown,
  });

  @override
  List<Object?> get props => [message, code, type];

  factory SecurityFailure.rootedDevice() => const SecurityFailure(
    message: 'Aplikasi tidak dapat berjalan pada perangkat yang di-root',
    code: 'ROOTED_DEVICE',
    type: SecurityFailureType.rootedDevice,
  );

  factory SecurityFailure.jailbrokenDevice() => const SecurityFailure(
    message: 'Aplikasi tidak dapat berjalan pada perangkat jailbreak',
    code: 'JAILBROKEN_DEVICE',
    type: SecurityFailureType.jailbrokenDevice,
  );
}

enum SecurityFailureType {
  rootedDevice,
  jailbrokenDevice,
  sslPinningFailed,
  unknown,
}

class LocationFailure extends Failure {
  const LocationFailure({
    super.message = 'Gagal mendapatkan lokasi',
    super.code = 'LOCATION_ERROR',
  });

  factory LocationFailure.permissionDenied() => const LocationFailure(
    message: 'Izin lokasi ditolak',
    code: 'PERMISSION_DENIED',
  );

  factory LocationFailure.serviceDisabled() => const LocationFailure(
    message: 'Layanan lokasi tidak aktif',
    code: 'SERVICE_DISABLED',
  );
}
