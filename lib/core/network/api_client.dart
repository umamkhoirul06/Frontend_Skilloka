/// API Client configuration with Dio
import 'package:dio/dio.dart';
import '../error/exceptions.dart';
import '../security/secure_storage.dart';

import '../config/app_config.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  // Configuration from AppConfig
  static String get baseUrl => AppConfig.baseUrl;
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  ApiClient({required this.dio, required this.secureStorage}) {
    _configureDio();
  }

  void _configureDio() {
    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    );

    dio.interceptors.add(_authInterceptor());

    if (AppConfig.enableLogging) {
      dio.interceptors.add(_loggingInterceptor());
    }

    dio.interceptors.add(_retryInterceptor());
  }

  /// Auth interceptor - adds token to requests and handles refresh
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth for public endpoints
        if (_isPublicEndpoint(options.path)) {
          return handler.next(options);
        }

        final token = await secureStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final opts = error.requestOptions;
            final token = await secureStorage.getAccessToken();
            opts.headers['Authorization'] = 'Bearer $token';

            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.reject(error);
            }
          }
        }
        return handler.next(error);
      },
    );
  }

  /// Logging interceptor for debugging
  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // ignore: avoid_print
        print('API Request: ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // ignore: avoid_print
        print(
          'API Response: ${response.statusCode} ${response.requestOptions.path}',
        );
        return handler.next(response);
      },
      onError: (error, handler) {
        // ignore: avoid_print
        print(
          'API Error: ${error.response?.statusCode} ${error.requestOptions.path}',
        );
        return handler.next(error);
      },
    );
  }

  /// Retry interceptor for failed requests
  InterceptorsWrapper _retryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final requestOptions = error.requestOptions;
        final int retryCount =
            (requestOptions.extra['retryCount'] as int?) ?? 0;

        // Only retry for network errors and 5xx responses
        if (_shouldRetry(error) && retryCount < maxRetries) {
          requestOptions.extra['retryCount'] = retryCount + 1;

          // Exponential backoff
          await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));

          try {
            final response = await dio.fetch(requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    );
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
      '/auth/verify-otp',
      '/courses',
      '/lpk',
      '/categories',
    ];
    return publicEndpoints.any((endpoint) => path.startsWith(endpoint));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '$baseUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await secureStorage.saveAccessToken(data['access_token']);
        await secureStorage.saveRefreshToken(data['refresh_token']);
        return true;
      }
      return false;
    } catch (e) {
      // Clear tokens on refresh failure
      await secureStorage.clearTokens();
      return false;
    }
  }

  /// Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Koneksi timeout');
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return ServerException(
          message: error.response?.data?['message'] ?? 'Terjadi kesalahan',
          statusCode: error.response?.statusCode,
          data: error.response?.data,
        );
      case DioExceptionType.cancel:
        return const ServerException(message: 'Request dibatalkan');
      default:
        return ServerException(message: error.message ?? 'Terjadi kesalahan');
    }
  }
}
