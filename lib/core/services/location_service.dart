import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../error/exceptions.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Mengambil posisi GPS pengguna saat ini dengan handling izin & timeout
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan GPS aktif di perangkat
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        message: 'Layanan lokasi (GPS) belum diaktifkan. Silakan aktifkan GPS perangkat Anda.',
        type: LocationExceptionType.serviceDisabled,
      );
    }

    // 2. Cek izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          message: 'Izin lokasi tidak diberikan. Skilloka membutuhkan lokasi untuk menampilkan LPK terdekat.',
          type: LocationExceptionType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        message: 'Izin lokasi diblokir permanen. Mohon aktifkan izin lokasi di Pengaturan aplikasi Anda.',
        type: LocationExceptionType.permissionDeniedForever,
      );
    }

    // 3. Ambil posisi saat ini
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (e) {
      debugPrint('Error getting GPS position: $e');
      // Fallback ke posisi terakhir yang diketahui jika getCurrentPosition timeout
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      throw LocationException(
        message: 'Gagal mendeteksi koordinat GPS saat ini: $e',
        type: LocationExceptionType.timeout,
      );
    }
  }

  /// Menghitung jarak langsung (dalam kilometer) antara dua koordinat
  double calculateDistanceKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final meters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return meters / 1000.0;
  }

  /// Koordinat referensi pusat 31 Kecamatan di Kabupaten Indramayu
  static const Map<String, (double, double)> indramayuKecamatanCoordinates = {
    'Indramayu': (-6.3264, 108.3200),
    'Sindang': (-6.3333, 108.3000),
    'Pasekan': (-6.2833, 108.3167),
    'Cantigi': (-6.3167, 108.2667),
    'Arahan': (-6.3667, 108.2500),
    'Lohbener': (-6.3986, 108.2725),
    'Balongan': (-6.3811, 108.3758),
    'Juntinyuat': (-6.4250, 108.4333),
    'Karangampel': (-6.4628, 108.4528),
    'Kedokanbunder': (-6.4833, 108.4000),
    'Krangkeng': (-6.5083, 108.4972),
    'Sliyeg': (-6.4556, 108.3611),
    'Jatibarang': (-6.4716, 108.3128),
    'Widasari': (-6.4667, 108.2667),
    'Bangodua': (-6.4833, 108.2833),
    'Tukdana': (-6.5000, 108.2500),
    'Kertasemaya': (-6.5167, 108.3333),
    'Sukagumiwang': (-6.5500, 108.3500),
    'Lelea': (-6.4333, 108.2333),
    'Cikedung': (-6.4833, 108.1667),
    'Terisi': (-6.4833, 108.1000),
    'Losarang': (-6.3917, 108.1694),
    'Kandanghaur': (-6.3314, 108.1528),
    'Bongas': (-6.3667, 108.0667),
    'Gabuswetan': (-6.4167, 108.0833),
    'Kroya': (-6.4833, 108.0167),
    'Anjatan': (-6.3556, 107.9667),
    'Patrol': (-6.3117, 107.9892),
    'Sukra': (-6.2889, 107.9250),
    'Haurgeulis': (-6.4589, 107.9547),
    'Gantar': (-6.5333, 107.9167),
  };

  /// Mencari kecamatan terdekat di Indramayu dari posisi pengguna
  (String, double) findNearestKecamatan(double lat, double lng) {
    String closestName = 'Indramayu';
    double minDistance = double.infinity;

    indramayuKecamatanCoordinates.forEach((name, coords) {
      final dist = calculateDistanceKm(lat, lng, coords.$1, coords.$2);
      if (dist < minDistance) {
        minDistance = dist;
        closestName = name;
      }
    });

    return (closestName, minDistance);
  }
}
