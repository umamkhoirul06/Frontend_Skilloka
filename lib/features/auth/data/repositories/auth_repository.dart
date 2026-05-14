import 'dart:convert'; // Ini penting untuk mengubah teks jadi JSON
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService secureStorage;

  AuthRepository({required this.apiClient, required this.secureStorage});

  // 🛠️ FUNGSI PENYELAMAT: Mengubah String paksa menjadi JSON Map
  // 🛠️ FUNGSI PENYELAMAT & DETEKTIF
  Map<String, dynamic> _parseData(dynamic responseData) {
    if (responseData is String) {
      try {
        return jsonDecode(responseData);
      } catch (e) {
        // Tampilkan pesan error PHP asli dari Laravel ke Terminal VS Code
        print("\n========== ERROR DARI SERVER LARAVEL ==========");
        print(responseData);
        print("===============================================\n");
        throw Exception(
            "Server Backend sedang mengalami gangguan (PHP Error).");
      }
    }
    return responseData as Map<String, dynamic>;
  }

  // 1. Fungsi Tembak API Minta OTP
  Future<bool> sendOtp(String phone) async {
    try {
      final response = await apiClient.post(
        '/auth/send-otp',
        data: {'phone': phone},
      );

      // Gunakan fungsi penyelamat di sini
      final data = _parseData(response.data);
      return data['status'] == 'success';
    } catch (e) {
      throw Exception('Gagal mengirim OTP: $e');
    }
  }

  // 2. Fungsi Tembak API Verifikasi OTP & Simpan Token
  Future<bool> verifyOtp(String phone, String otp) async {
    try {
      final response = await apiClient.post(
        '/auth/verify-otp',
        data: {
          'phone': phone,
          'otp': otp,
        },
      );

      // Gunakan fungsi penyelamat di sini
      final data = _parseData(response.data);

      if (data['status'] == 'success') {
        // Ambil token dari JSON response
        final accessToken = data['data']['access_token'];
        final refreshToken = data['data']['refresh_token'];

        // Simpan token ke HP user secara aman
        await secureStorage.saveAccessToken(accessToken);
        await secureStorage.saveRefreshToken(refreshToken);

        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Kode OTP salah atau gagal verifikasi: $e');
    }
  }
}
