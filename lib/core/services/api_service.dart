import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';

import 'package:dio/dio.dart';

import '../config/app_config.dart';

import '../navigation/app_router.dart';

class ApiService {
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: const {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );

  static String get baseUrl => AppConfig.baseUrl;

  static String get storageUrl => AppConfig.baseStorageUrl;

  static const String _tokenKey = 'access_token';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Konversi path relatif ke full URL ─────────────────────────────────────

  static String toFullUrl(String? path) {
  if (path == null || path.isEmpty) return '';

  final url = path.trim();

  if (url.startsWith('http://127.0.0.1:8000')) {
    final parsed = Uri.parse(url);
    final storageIndex = parsed.path.indexOf('/storage/');

    if (storageIndex != -1) {
      final storagePath =
          parsed.path.substring(storageIndex + '/storage/'.length);

      return '${AppConfig.baseOrigin}/api/media/$storagePath';
    }

    return url.replaceFirst(
      'http://127.0.0.1:8000',
      AppConfig.baseOrigin,
    );
  }

  if (url.startsWith('http://localhost:8000')) {
    final parsed = Uri.parse(url);
    final storageIndex = parsed.path.indexOf('/storage/');

    if (storageIndex != -1) {
      final storagePath =
          parsed.path.substring(storageIndex + '/storage/'.length);

      return '${AppConfig.baseOrigin}/api/media/$storagePath';
    }

    return url.replaceFirst(
      'http://localhost:8000',
      AppConfig.baseOrigin,
    );
  }

  if (url.startsWith('/storage/')) {
    final storagePath = url.substring('/storage/'.length);
    return '${AppConfig.baseOrigin}/api/media/$storagePath';
  }

  if (url.startsWith('storage/')) {
    final storagePath = url.substring('storage/'.length);
    return '${AppConfig.baseOrigin}/api/media/$storagePath';
  }

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  final clean = url.startsWith('/') ? url.substring(1) : url;

  return '${AppConfig.baseOrigin}/api/media/$clean';
}

  // ── Token Helpers ──────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _secureStorage.write(
      key: _tokenKey,
      value: token,
    );
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(
      key: _tokenKey,
    );
  }

  Future<void> removeToken() async {
    await _secureStorage.delete(
      key: _tokenKey,
    );
  }

  Future<void> logout() async {
    await removeToken();

    AppRouter.router.go(
      AppRouter.login,
    );
  }

  // ── Headers ────────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null)
        'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> get _publicHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ── Response Handler ───────────────────────────────────────────────────────

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        removeToken();

        AppRouter.router.go(
          AppRouter.login,
        );

        return {
          'success': false,
          'message':
              'Sesi habis. Silakan login kembali.',
        };
      } else {
        return {
          'success': false,
          'message':
              data['message'] ??
              'Error ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Gagal parse response: $e',
      };
    }
  }

  // ── AUTH ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(
    String name,
    String phone,
  ) async {
    try {
      final r = await http
          .post(
            Uri.parse(
              '$baseUrl/auth/register',
            ),
            headers: _publicHeaders,
            body: jsonEncode({
              'name': name,
              'phone': phone,
            }),
          )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response(
          '{"message":"Koneksi timeout."}',
          408,
        ),
      );

      return _handleResponse(r);
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message':
            'Gagal terhubung ke server: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> requestOtp(
    String phone, {
    String channel = 'whatsapp',
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse(
              '$baseUrl/auth/request-otp',
            ),
            headers: _publicHeaders,
            body: jsonEncode({
              'phone': phone,
              'channel': channel,
            }),
          )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response(
          '{"message":"Koneksi timeout. Server tidak merespons."}',
          408,
        ),
      );

      return _handleResponse(r);
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message':
            'Gagal terhubung ke server: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp,
  ) async {
    try {
      final r = await http
          .post(
            Uri.parse(
              '$baseUrl/auth/verify-otp',
            ),
            headers: _publicHeaders,
            body: jsonEncode({
              'phone': phone,
              'otp_code': otp,
            }),
          )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response(
          '{"message":"Koneksi timeout. Server tidak merespons."}',
          408,
        ),
      );

      final result = _handleResponse(r);

      if (result['success']) {
        final d = result['data'];

        final token =
            d['token'] ??
            d['access_token'] ??
            d['data']?['token'] ??
            d['data']?['access_token'];

        if (token != null) {
          await saveToken(token);
        }
      }

      return result;
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message':
            'Gagal terhubung ke server: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── PROFILE ────────────────────────────────────────────────────────────────

 Future<Map<String, dynamic>> getProfile() async {
  try {
    final token = await getToken();

    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan.',
      };
    }

    final response = await _dio.get(
      '/profile',
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );



    return {
      'success': true,
      'data': response.data,
    };
  } on DioException catch (e) {
    final responseData = e.response?.data;

    String message = 'Gagal memuat profil';

    if (responseData is Map<String, dynamic>) {
      message = responseData['message']?.toString() ?? message;
    }

    return {
      'success': false,
      'message': message,
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Koneksi gagal: $e',
    };
  }
}

  // ── UPDATE PROFILE ─────────────────────────────────────────────────────────

  // ── UPDATE PROFILE ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? gender,
    String? birthDate,
    String? avatarType,
    String? avatarId,
    String? frameId,
  }) async {
    try {
      final response = await _dio.put(
        '/user/profile',
        data: {
          'name': name,
          'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
          if (gender != null) 'gender': gender,
          if (birthDate != null) 'birth_date': birthDate,
          if (avatarType != null) 'avatar_type': avatarType,
          if (avatarId != null || avatarType == 'photo')
            'avatar_id': avatarId,
          if (frameId != null) 'frame_id': frameId,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ??
            'Gagal memperbarui profil',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan sistem: $e',
      };
    }
  }


  // ── UPLOAD FOTO PROFIL ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadProfilePhoto(
    XFile imageFile,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        ),
      });

      final response = await _dio.post(
        '/user/profile/photo',
        data: formData,
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ??
            'Gagal mengunggah foto',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Terjadi kesalahan sistem: $e',
      };
    }
  }

  // ── LPK ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getLpks({
    String? search,
    String? category,
    String? location,
  }) async {
    try {
      final q = <String, String>{};

      if (search?.isNotEmpty == true) {
        q['search'] = search!;
      }

      if (category?.isNotEmpty == true) {
        q['category'] = category!;
      }

      if (location?.isNotEmpty == true) {
        q['location'] = location!;
      }

      final uri = Uri.parse(
        '$baseUrl/lpks',
      ).replace(
        queryParameters: q,
      );

      final r = await http
          .get(
            uri,
            headers: _publicHeaders,
          )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response(
          '{"message":"Koneksi timeout."}',
          408,
        ),
      );

      return _handleResponse(r);
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message':
            'Gagal terhubung ke server: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getLpkDetail(
    String lpkId,
  ) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/lpks/$lpkId',
        ),
        headers: _publicHeaders,
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── COURSES ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCourses({
    String? search,
    String? category,
    String? lpkId,
  }) async {
    try {
      final q = <String, String>{};

      if (search?.isNotEmpty == true) {
        q['search'] = search!;
      }

      if (category?.isNotEmpty == true) {
        q['category'] = category!;
      }

      if (lpkId?.isNotEmpty == true) {
        q['lpk_id'] = lpkId!;
      }

      final uri = Uri.parse(
        '$baseUrl/courses',
      ).replace(
        queryParameters: q,
      );

      final r = await http
          .get(
            uri,
            headers: _publicHeaders,
          )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response(
          '{"message":"Koneksi timeout."}',
          408,
        ),
      );

      return _handleResponse(r);
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message':
            'Gagal terhubung ke server: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getCourseDetail(
    String courseId,
  ) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/courses/$courseId',
        ),
        headers: _publicHeaders,
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── BOOKINGS ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBookings() async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/bookings',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String courseId,
    required String scheduleId,
  }) async {
    try {
      final r = await http.post(
        Uri.parse(
          '$baseUrl/bookings',
        ),
        headers: await _authHeaders(),
        body: jsonEncode({
          'course_id': courseId,
          'schedule_id': scheduleId,
        }),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> cancelBooking(
    String bookingId,
  ) async {
    try {
      final r = await http.patch(
        Uri.parse(
          '$baseUrl/bookings/$bookingId/cancel',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── CERTIFICATES ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCertificates() async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/user/certificates',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── FAVORITES ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/favorites',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> toggleFavorite({
    required String courseId,
  }) async {
    try {
      final r = await http.post(
        Uri.parse(
          '$baseUrl/favorites/$courseId',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }
    // ── CATEGORIES & LOCATIONS ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final r = await http
          .get(
            Uri.parse(
              '$baseUrl/categories',
            ),
            headers: _publicHeaders,
          )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response(
          '{"message":"Koneksi timeout."}',
          408,
        ),
      );

      return _handleResponse(r);
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message':
            'Gagal terhubung ke server: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getLocations() async {
    try {
      final r = await http
          .get(
            Uri.parse(
              '$baseUrl/locations',
            ),
            headers: _publicHeaders,
          )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response(
          '{"message":"Koneksi timeout."}',
          408,
        ),
      );

      return _handleResponse(r);
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message':
            'Gagal terhubung ke server: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── EDUCATION PROFILE ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateEducationProfile({
    required String educationLevel,
    required String major,
    String? institutionName,
    String? graduationYear,
    String? careerGoal,
    String? preferredLocation,
  }) async {
    try {
      final r = await http.put(
        Uri.parse(
          '$baseUrl/profile/education',
        ),
        headers: await _authHeaders(),
        body: jsonEncode({
          'education_level': educationLevel,
          'major': major,
          if (institutionName != null)
            'institution_name': institutionName,
          if (graduationYear != null)
            'graduation_year': graduationYear,
          if (careerGoal != null)
            'career_goal': careerGoal,
          if (preferredLocation != null)
            'preferred_location': preferredLocation,
        }),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── RECOMMENDATIONS ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getRecommendations() async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/recommendations',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── MY COURSES ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyCourses() async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/my-courses',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getCourseContent(
    String courseId,
  ) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/my-courses/$courseId/content',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getCourseAttendance(
    String courseId,
  ) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/my-courses/$courseId/attendance',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getCourseCertificate(
    String courseId,
  ) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/my-courses/$courseId/certificate',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── BOOKING PAYMENT ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBookingPayment(
    String bookingId,
  ) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/bookings/$bookingId/payment',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createBookingPayment({
    required String bookingId,
    required String paymentMethod,
  }) async {
    try {
      final r = await http.post(
        Uri.parse(
          '$baseUrl/bookings/$bookingId/payment',
        ),
        headers: await _authHeaders(),
        body: jsonEncode({
          'payment_method': paymentMethod,
        }),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── REVIEWS ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCourseReviews(
    String courseId,
  ) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/courses/$courseId/reviews',
        ),
        headers: _publicHeaders,
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createReview({
    required String courseId,
    required int rating,
    required String comment,
  }) async {
    try {
      final r = await http.post(
        Uri.parse(
          '$baseUrl/courses/$courseId/reviews',
        ),
        headers: await _authHeaders(),
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── CHATBOT ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendChatbotMessage(
    String message,
  ) async {
    try {
      final r = await http.post(
        Uri.parse(
          '$baseUrl/chatbot/messages',
        ),
        headers: await _authHeaders(),
        body: jsonEncode({
          'message': message,
        }),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getChatbotHistory() async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/chatbot/history',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── COURSE SCHEDULES ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCourseSchedules(
    String courseId,
  ) async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/courses/$courseId/schedules',
        ),
        headers: _publicHeaders,
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  // ── SUBSCRIPTION PLANS ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSubscriptionPlans() async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/subscription/plans',
        ),
        headers: _publicHeaders,
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getMySubscriptions() async {
    try {
      final r = await http.get(
        Uri.parse(
          '$baseUrl/subscriptions',
        ),
        headers: await _authHeaders(),
      );

      return _handleResponse(r);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Koneksi gagal: $e',
      };
    }
  }
}