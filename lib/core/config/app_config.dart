import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppEnvironment {
  prod,       // Server remote skilloka.my.id (DEFAULT)
  devLocal,   // Localhost emulator (10.0.2.2:8000) atau desktop/web (127.0.0.1:8000)
  devDevice,  // HP fisik di WiFi lokal (http://<deviceIp>:8000)
  custom,     // Custom Origin URL yang ditentukan pengguna
  dev,        // Alias prod / dev server
  staging,    // Staging remote
}

class AppConfig {
  static const String _prefEnvKey = 'app_api_environment';
  static const String _prefCustomOriginKey = 'app_api_custom_origin';
  static const String _prefDeviceIpKey = 'app_api_device_ip';

  // ─── ENVIRONMENT AKTIF ───────────────────────────────────────────────────
  // Default adalah AppEnvironment.prod (https://skilloka.my.id)
  // Bisa di-override lewat build flag: --dart-define=ENV=devLocal / devDevice / prod
  // Atau diubah langsung secara dinamis melalui menu Pengaturan aplikasi.
  static AppEnvironment environment = _resolveDefaultEnvironment();

  static AppEnvironment _resolveDefaultEnvironment() {
    const envVal = String.fromEnvironment('ENV', defaultValue: 'prod');
    switch (envVal.toLowerCase()) {
      case 'devlocal':
      case 'local':
        return AppEnvironment.devLocal;
      case 'devdevice':
      case 'device':
        return AppEnvironment.devDevice;
      case 'staging':
        return AppEnvironment.staging;
      case 'custom':
        return AppEnvironment.custom;
      case 'prod':
      case 'production':
      default:
        return AppEnvironment.prod;
    }
  }

  /// IP PC di jaringan WiFi lokal (untuk devDevice)
  static String deviceIp = const String.fromEnvironment(
    'DEVICE_IP',
    defaultValue: '192.168.0.107',
  );

  /// Custom Base Origin jika memilih mode custom
  static String customOrigin = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );

  /// Inisialisasi dari SharedPreferences saat aplikasi start
  static Future<void> init(SharedPreferences prefs) async {
    final savedEnv = prefs.getString(_prefEnvKey);
    if (savedEnv != null) {
      for (final val in AppEnvironment.values) {
        if (val.name == savedEnv) {
          environment = val;
          break;
        }
      }
    }
    final savedCustom = prefs.getString(_prefCustomOriginKey);
    if (savedCustom != null && savedCustom.isNotEmpty) {
      customOrigin = savedCustom;
    }
    final savedIp = prefs.getString(_prefDeviceIpKey);
    if (savedIp != null && savedIp.isNotEmpty) {
      deviceIp = savedIp;
    }
  }

  /// Ubah environment secara runtime dan simpan ke SharedPreferences
  static Future<void> setEnvironment(
    AppEnvironment newEnv, {
    String? newCustomOrigin,
    String? newDeviceIp,
    SharedPreferences? prefs,
  }) async {
    environment = newEnv;
    if (newCustomOrigin != null) customOrigin = newCustomOrigin;
    if (newDeviceIp != null) deviceIp = newDeviceIp;

    if (prefs != null) {
      await prefs.setString(_prefEnvKey, newEnv.name);
      if (newCustomOrigin != null) {
        await prefs.setString(_prefCustomOriginKey, newCustomOrigin);
      }
      if (newDeviceIp != null) {
        await prefs.setString(_prefDeviceIpKey, newDeviceIp);
      }
    }
  }

  static bool get isLocal =>
      environment == AppEnvironment.devLocal ||
      environment == AppEnvironment.devDevice;

  static String get _localHost {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return '127.0.0.1:8000';
    }
    // Android emulator
    return '10.0.2.2:8000';
  }

  static String get baseOrigin {
    if (environment == AppEnvironment.custom && customOrigin.trim().isNotEmpty) {
      var url = customOrigin.trim();
      while (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      if (url.endsWith('/api')) {
        url = url.substring(0, url.length - 4);
      }
      return url;
    }

    switch (environment) {
      case AppEnvironment.prod:
      case AppEnvironment.dev:
        return 'https://skilloka.my.id';
      case AppEnvironment.devLocal:
        return 'http://$_localHost';
      case AppEnvironment.devDevice:
        if (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux) {
          return 'http://$_localHost';
        }
        return 'http://$deviceIp:8000';
      case AppEnvironment.staging:
        return 'https://staging.skilloka.my.id';
      case AppEnvironment.custom:
        return 'https://skilloka.my.id';
    }
  }

  static String get baseUrl => '$baseOrigin/api';

  static String get baseStorageUrl => '$baseOrigin/storage';

  static bool get enableLogging => environment != AppEnvironment.prod;

  /// Google Gemini Free Tier API Key (can be injected via --dart-define=GEMINI_API_KEY=xxx or overridden in runtime)
  static String geminiApiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // ─── MIDTRANS CONFIGURATION ───────────────────────────────────────────────
  static const String midtransMerchantId = 'G068252610';
  static const String midtransClientKey = 'Mid-client-Vr_iP7ruEQNSptDT';

  /// Cek apakah menggunakan sandbox atau production environment
  static bool get isMidtransProduction =>
      !midtransClientKey.startsWith('SB-');

  /// URL dasar untuk Snap checkout Midtrans
  static String get midtransSnapBaseUrl => isMidtransProduction
      ? 'https://app.midtrans.com/snap/v2/vtweb/'
      : 'https://app.sandbox.midtrans.com/snap/v2/vtweb/';

  /// Helper untuk mendapatkan URL lengkap Snap Midtrans
  static String getMidtransSnapUrl(String snapToken) {
    return '$midtransSnapBaseUrl$snapToken';
  }
}
