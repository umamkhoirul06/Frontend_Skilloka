import 'package:hive_flutter/hive_flutter.dart';
import '../constants/hive_constants.dart';
import '../network/api_client.dart';
import '../config/app_config.dart';

abstract class SyncService {
  Future<void> init();
  Future<void> syncLocations();
  Future<void> syncCategories();
  Future<void> syncUserProfile();
  List<dynamic> getLocations();
  List<dynamic> getCategories();
  Future<void> startInitialSync();
}

class SyncServiceImpl implements SyncService {
  final ApiClient apiClient;

  SyncServiceImpl({required this.apiClient});

  Box? _locationBox;
  Box? _categoryBox;
  Box? _userBox;

  @override
  Future<void> init() async {
    _locationBox = await Hive.openBox(HiveConstants.locationBox);
    _categoryBox = await Hive.openBox(HiveConstants.categoryBox);
    _userBox = await Hive.openBox(HiveConstants.userBox);
  }

  @override
  Future<void> syncLocations() async {
    try {
      final response = await apiClient.get('/locations');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        await _locationBox?.put(HiveConstants.locationsKey, data);
        await _locationBox?.put(
          HiveConstants.syncTimestampKey,
          DateTime.now().toIso8601String(),
        );

        if (AppConfig.enableLogging) {
          print('Synced ${data.length} locations');
        }
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('Sync Locations Failed: $e');
      }
      // Depending on requirements, retry or silent fail (offline)
    }
  }

  @override
  Future<void> syncCategories() async {
    try {
      final response = await apiClient.get('/categories');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        await _categoryBox?.put(HiveConstants.categoriesKey, data);
        await _categoryBox?.put(
          HiveConstants.syncTimestampKey,
          DateTime.now().toIso8601String(),
        );

        if (AppConfig.enableLogging) {
          print('Synced ${data.length} categories');
        }
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('Sync Categories Failed: $e');
      }
    }
  }

  @override
  Future<void> syncUserProfile() async {
    try {
      final response = await apiClient.get('/auth/me'); // Assuming endpoint
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        await _userBox?.put(HiveConstants.userKey, data);
      }
    } catch (e) {
      // e.g. 401 Unauthorized
    }
  }

  @override
  List<dynamic> getLocations() {
    return _locationBox?.get(HiveConstants.locationsKey, defaultValue: []) ??
        [];
  }

  @override
  List<dynamic> getCategories() {
    return _categoryBox?.get(HiveConstants.categoriesKey, defaultValue: []) ??
        [];
  }

  @override
  Future<void> startInitialSync() async {
    // Run syncs (don't block UI if possible, but for initial maybe we wait or run in background)
    // We don't await here to allow UI to proceed unless necessary
    // But user requirement says 'Sync Indramayu hierarchy on first launch'.
    // Typically this runs in Splash Screen.
    try {
      if (AppConfig.enableLogging) print('Starting initial sync...');
      await Future.wait([syncLocations(), syncCategories(), syncUserProfile()]);
      if (AppConfig.enableLogging) print('Initial sync completed.');
    } catch (e) {
      if (AppConfig.enableLogging) print('Initial sync failed: $e');
    }
  }
}
