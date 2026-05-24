import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../navigation/app_router.dart';

class ApiService {
  static const String baseUrl = 'https://skilloka.my.id/api';
  static const String _tokenKey = 'access_token';
  final _storage = const FlutterSecureStorage();

  // ==========================================
  // TOKEN HELPERS
  // ==========================================

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> logout() async {
    await removeToken();
    AppRouter.router.go(AppRouter.login);
  }

  // ==========================================
  // HEADERS HELPER
  // ==========================================

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ==========================================
  // RESPONSE HELPER
  // ==========================================

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else if (response.statusCode == 401) {
      // Token expired / invalid — paksa logout
      removeToken();
      AppRouter.router.go(AppRouter.login);
      return {'success': false, 'message': 'Sesi habis. Silakan login kembali.'};
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Terjadi kesalahan (${response.statusCode})',
      };
    }
  }

  // ==========================================
  // AUTH
  // ==========================================

  Future<Map<String, dynamic>> register(String name, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _publicHeaders,
        body: jsonEncode({'name': name, 'phone': phone}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-otp'),
        headers: _publicHeaders,
        body: jsonEncode({'phone': phoneNumber}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
      String phoneNumber, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _publicHeaders,
        body: jsonEncode({'phone': phoneNumber, 'otp_code': otpCode}),
      );
      final result = _handleResponse(response);
      if (result['success']) {
        final token = result['data']['token'] ??
            result['data']['access_token'] ??
            result['data']['data']?['token'];
        if (token != null) await saveToken(token);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  // ==========================================
  // PROFILE
  // ==========================================

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _authHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? gender,
    String? birthDate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
          if (gender != null) 'gender': gender,
          if (birthDate != null) 'birth_date': birthDate,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan.'};
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/profile/photo'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.files.add(
        await http.MultipartFile.fromPath('photo', imageFile.path),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  // ==========================================
  // LPK
  // ==========================================

  Future<Map<String, dynamic>> getLpks({
    String? search,
    String? category,
    String? location,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (location != null && location.isNotEmpty) queryParams['location'] = location;

      final uri = Uri.parse('$baseUrl/lpks').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _publicHeaders);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getLpkDetail(String lpkId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lpks/$lpkId'),
        headers: _publicHeaders,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  // ==========================================
  // COURSES
  // ==========================================

  Future<Map<String, dynamic>> getCourses({
    String? search,
    String? category,
    String? lpkId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (lpkId != null && lpkId.isNotEmpty) queryParams['lpk_id'] = lpkId;

      final uri = Uri.parse('$baseUrl/courses').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _publicHeaders);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getCourseDetail(String courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/courses/$courseId'),
        headers: _publicHeaders,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  // ==========================================
  // BOOKINGS
  // ==========================================

  Future<Map<String, dynamic>> getBookings() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token missing'};
      }
      final response = await http.get(
        Uri.parse('$baseUrl/user/bookings'),
        headers: await _authHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String courseId,
    required String scheduleId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'course_id': courseId,
          'schedule_id': scheduleId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: await _authHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  // ==========================================
  // CERTIFICATES
  // ==========================================

  Future<Map<String, dynamic>> getCertificates() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan.'};
      }
      final response = await http.get(
        Uri.parse('$baseUrl/user/certificates'),
        headers: await _authHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  // ==========================================
  // FAVORITES
  // ==========================================

  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/favorites'),
        headers: await _authHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> toggleFavorite({
    required String itemId,
    required String itemType, // 'course' atau 'lpk'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/favorites/toggle'),
        headers: await _authHeaders(),
        body: jsonEncode({'item_id': itemId, 'item_type': itemType}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  // ==========================================
  // CATEGORIES & LOCATIONS (untuk filter)
  // ==========================================

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _publicHeaders,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations'),
        headers: _publicHeaders,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: ${e.toString()}'};
    }
  }
}