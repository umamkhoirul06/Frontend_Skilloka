
enum AppEnvironment { dev, staging, prod }

class AppConfig {
  static AppEnvironment environment = AppEnvironment.dev;

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.dev:
        return 'https://skilloka.my.id/api';
      case AppEnvironment.prod:
        return 'https://skilloka.my.id/api';
      case AppEnvironment.staging:
        return 'https://staging.skilloka.my.id/api';
    }
  }

  static String get baseStorageUrl {
    switch (environment) {
      case AppEnvironment.dev:
      case AppEnvironment.prod:
        return 'https://skilloka.my.id/storage/';
      case AppEnvironment.staging:
        return 'https://staging.skilloka.my.id/storage/';
    }
  }

  static bool get enableLogging {
    return environment != AppEnvironment.prod;
  }
}
