/// Dependency Injection Container using GetIt
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';
import '../security/secure_storage.dart';
import '../security/security_checker.dart';

import '../services/sync_service.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters if needed here

  // External dependencies
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPrefs);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<Dio>(() => Dio());

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );

  // Core services
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageServiceImpl(storage: sl()),
  );
  sl.registerLazySingleton<SecurityChecker>(() => SecurityCheckerImpl());

  // ApiClient depends on Dio and SecureStorage
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(dio: sl(), secureStorage: sl()),
  );

  // Sync Service
  sl.registerLazySingleton<SyncService>(() => SyncServiceImpl(apiClient: sl()));

  // Register feature dependencies
  await _initAuthFeature();
  await _initHomeFeature();
  await _initCourseFeature();
  await _initBookingFeature();
  await _initProfileFeature();

  // Initialize Sync Service (open boxes)
  await sl<SyncService>().init();
}

Future<void> _initAuthFeature() async {
  // Data sources, Repositories...
}

Future<void> _initHomeFeature() async {}
Future<void> _initCourseFeature() async {}
Future<void> _initBookingFeature() async {}
Future<void> _initProfileFeature() async {}
