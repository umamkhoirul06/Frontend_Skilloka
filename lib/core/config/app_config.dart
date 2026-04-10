import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, staging, prod }

class AppConfig {
  static AppEnvironment environment = AppEnvironment.dev;

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.dev:
        if (kIsWeb) {
          return 'http://localhost:8000/api/v1';
        }
        // Ganti dengan IP Address Laptop Anda jika pakai HP Asli
        return 'http://192.168.0.205:8000/api/v1'; 
      case AppEnvironment.staging:
        return 'https://staging-api.skilloka.com/api/v1';
      case AppEnvironment.prod:
        return 'https://api.skilloka.com/api/v1';
    }
  }

  static bool get enableLogging {
    return environment != AppEnvironment.prod;
  }
}
