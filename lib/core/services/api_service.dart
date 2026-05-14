import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../navigation/app_router.dart';

class ApiService {
  static const String baseUrl = 'https://skilloka.my.id/api';
  static const String _tokenKey = 'access_token';
  final _storage = const FlutterSecureStorage();

  // ==========================================
  // TOKEN HELPERS (Secure Storage)
  // ==========================================
  
  /// Menyimpan token ke lokal
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Mengambil token dari lokal
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Menghapus token dari lokal (Logout)
  Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Melakukan proses logout dan pindah halaman
  Future<void> logout() async {
    await removeToken();
    AppRouter.router.go(AppRouter.login);
  }

  // ==========================================
  // API ENDPOINTS
  // ==========================================

  /// Register user baru
  Future<Map<String, dynamic>> register(String name, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal mendaftar'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Request OTP
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-otp'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'phone': phoneNumber,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal meminta OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Verifikasi OTP dan simpan token
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'phone': phoneNumber,
          'otp_code': otpCode,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Asumsi token berada di properti 'token' atau 'access_token'
        final token = data['token'] ?? data['access_token'];
        if (token != null) {
          await saveToken(token);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Verifikasi OTP gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Ambil data semua courses
  Future<Map<String, dynamic>> getCourses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/courses'),
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Gagal memuat courses'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Ambil data profil user dengan token (Protected Route)
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan. Silakan login kembali.'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal memuat profil'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Ambil daftar pesanan user dengan token (Protected Route)
  Future<Map<String, dynamic>> getBookings() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Token missing'};

      final response = await http.get(
        Uri.parse('$baseUrl/user/bookings'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal memuat pesanan'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
