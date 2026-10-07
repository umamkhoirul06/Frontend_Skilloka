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
  static AppEnvironment environment = AppEnvironment.devLocal;

  /// IP PC kamu di jaringan WiFi lokal (hanya untuk devDevice).
  /// Cek dengan: `ipconfig` (Windows) → IPv4 Address
  static const String _deviceIp = '10.0.168.202';

  static String get _localHost {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return 'localhost:8000';
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
}

