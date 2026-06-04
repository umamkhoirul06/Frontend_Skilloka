import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../navigation/app_router.dart';

class ApiService {
  static const String baseUrl = 'https://skilloka.my.id/api';
  static const String storageUrl = 'https://skilloka.my.id/storage';
  static const String _tokenKey = 'access_token';
  final _storage = const FlutterSecureStorage();

  // ── Konversi path relatif ke full URL ──────────────────────────────────
  static String toFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path : '/$path';
    return '$storageUrl$clean';
  }

  // ── Token Helpers ───────────────────────────────────────────────────────
  Future<void> saveToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() async => await _storage.read(key: _tokenKey);

  Future<void> removeToken() async => await _storage.delete(key: _tokenKey);

  Future<void> logout() async {
    await removeToken();
    AppRouter.router.go(AppRouter.login);
  }

  // ── Headers ─────────────────────────────────────────────────────────────
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

  // ── Response Handler ─────────────────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        removeToken();
        AppRouter.router.go(AppRouter.login);
        return {
          'success': false,
          'message': 'Sesi habis. Silakan login kembali.'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal parse response: $e'};
    }
  }

  // ── AUTH ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(String name, String phone) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/auth/register'),
          headers: _publicHeaders,
          body: jsonEncode({'name': name, 'phone': phone}));
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> requestOtp(String phone, {String channel = 'whatsapp'}) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/auth/request-otp'),
          headers: _publicHeaders, body: jsonEncode({'phone': phone, 'channel': channel}));
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/auth/verify-otp'),
          headers: _publicHeaders,
          body: jsonEncode({'phone': phone, 'otp_code': otp}));
      final result = _handleResponse(r);
      if (result['success']) {
        final d = result['data'];
        final token = d['token'] ?? d['access_token'] ?? d['data']?['token'];
        if (token != null) await saveToken(token);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── PROFILE ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null)
        return {'success': false, 'message': 'Token tidak ditemukan.'};
      final r = await http.get(Uri.parse('$baseUrl/auth/me'),
          headers: await _authHeaders());
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
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
      final r = await http.put(Uri.parse('$baseUrl/user/profile'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'name': name,
            if (phone != null) 'phone': phone,
            if (email != null) 'email': email,
            if (address != null) 'address': address,
            if (gender != null) 'gender': gender,
            if (birthDate != null) 'birth_date': birthDate,
          }));
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    try {
      final token = await getToken();
      if (token == null)
        return {'success': false, 'message': 'Token tidak ditemukan.'};
      final request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/user/profile/photo'));
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.files
          .add(await http.MultipartFile.fromPath('photo', imageFile.path));
      final streamed = await request.send();
      final r = await http.Response.fromStream(streamed);
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── LPK ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getLpks({
    String? search,
    String? category,
    String? location,
  }) async {
    try {
      final q = <String, String>{};
      if (search?.isNotEmpty == true) q['search'] = search!;
      if (category?.isNotEmpty == true) q['category'] = category!;
      if (location?.isNotEmpty == true) q['location'] = location!;
      final uri = Uri.parse('$baseUrl/lpks').replace(queryParameters: q);
      final r = await http.get(uri, headers: _publicHeaders);
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> getLpkDetail(String lpkId) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/lpks/$lpkId'),
          headers: _publicHeaders);
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── COURSES ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCourses({
    String? search,
    String? category,
    String? lpkId,
  }) async {
    try {
      final q = <String, String>{};
      if (search?.isNotEmpty == true) q['search'] = search!;
      if (category?.isNotEmpty == true) q['category'] = category!;
      if (lpkId?.isNotEmpty == true) q['lpk_id'] = lpkId!;
      final uri = Uri.parse('$baseUrl/courses').replace(queryParameters: q);
      final r = await http.get(uri, headers: _publicHeaders);
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> getCourseDetail(String courseId) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/courses/$courseId'),
          headers: _publicHeaders);
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── BOOKINGS ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getBookings() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/user/bookings'),
          headers: await _authHeaders());
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String courseId,
    required String scheduleId,
  }) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/bookings'),
          headers: await _authHeaders(),
          body: jsonEncode({'course_id': courseId, 'schedule_id': scheduleId}));
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final r = await http.patch(
          Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
          headers: await _authHeaders());
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── CERTIFICATES ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCertificates() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/user/certificates'),
          headers: await _authHeaders());
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── FAVORITES ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/user/favorites'),
          headers: await _authHeaders());
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> toggleFavorite({
    required String itemId,
    required String itemType,
  }) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/user/favorites/toggle'),
          headers: await _authHeaders(),
          body: jsonEncode({'item_id': itemId, 'item_type': itemType}));
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── CATEGORIES & LOCATIONS ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/categories'),
          headers: _publicHeaders);
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> getLocations() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/locations'),
          headers: _publicHeaders);
      return _handleResponse(r);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
