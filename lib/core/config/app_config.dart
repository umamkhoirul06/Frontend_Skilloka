import 'package:flutter/foundation.dart';

enum AppEnvironment { devLocal, devDevice, dev, staging, prod }

class AppConfig {
  // ─── UBAH INI SESUAI KEBUTUHAN ─────────────────────────────────────────────
  // • devLocal   : Otomatis deteksi:
  //                - Web & Windows Desktop → http://localhost:8000
  //                - Android Emulator      → http://10.0.2.2:8000
  //                - iOS Simulator         → http://localhost:8000
  // • devDevice  : HP fisik di WiFi       → http://<deviceIp>:8000
  // • dev/prod   : Server remote skilloka.my.id
  static AppEnvironment environment = AppEnvironment.devDevice;

  /// IP PC kamu di jaringan WiFi lokal (hanya untuk devDevice).
  /// Cek dengan: `ipconfig` (Windows) → IPv4 Address
  static const String _deviceIp = '192.168.0.112';

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
    switch (environment) {
      case AppEnvironment.devLocal:
        return 'http://$_localHost';
      case AppEnvironment.devDevice:
        return 'http://$_deviceIp:8000';
      case AppEnvironment.dev:
      case AppEnvironment.prod:
        return 'https://skilloka.my.id';
      case AppEnvironment.staging:
        return 'https://staging.skilloka.my.id';
    }
  }

  static String get baseUrl => '$baseOrigin/api';

  static String get baseStorageUrl => '$baseOrigin/storage';

  static bool get enableLogging => environment != AppEnvironment.prod;

  /// Google Gemini Free Tier API Key (can be injected via --dart-define=GEMINI_API_KEY=xxx or overridden in runtime)
  /// Set your own key via the chatbot settings dialog (gear icon) or provide via --dart-define=GEMINI_API_KEY=AIzaSy...
  static String geminiApiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Leave empty to use built-in local reasoning; set real key via settings or --dart-define
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

