import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/course/data/models/course_model.dart';

/// User education and career preference model for hyperlocal profiling
class UserProfilePreference {
  final String educationLevel;
  final String major;
  final String careerGoal;
  final String? preferredLocation;

  const UserProfilePreference({
    required this.educationLevel,
    required this.major,
    required this.careerGoal,
    this.preferredLocation,
  });

  Map<String, dynamic> toJson() => {
        'education_level': educationLevel,
        'major': major,
        'career_goal': careerGoal,
        'preferred_location': preferredLocation,
      };

  factory UserProfilePreference.fromJson(Map<String, dynamic> json) {
    return UserProfilePreference(
      educationLevel: json['education_level']?.toString() ?? 'SMK',
      major: json['major']?.toString() ?? '',
      careerGoal: json['career_goal']?.toString() ?? 'Meningkatkan keahlian kerja',
      preferredLocation: json['preferred_location']?.toString(),
    );
  }
}

/// Scored course with computed algorithmic relevance and transparent justification
class ScoredCourse {
  final CourseModel course;
  final int score; // 0 - 100
  final String matchReason;
  final List<String> matchingTags;

  const ScoredCourse({
    required this.course,
    required this.score,
    required this.matchReason,
    this.matchingTags = const [],
  });
}

/// Course Relevance Engine & Data Security Handler
///
/// Implements transparent, explainable recommendations aligned with PRD 2.3 & 8.3:
/// - Uses education & career signals as personalization weights.
/// - Stores preferences securely with AES hardware-backed encryption.
/// - Ranks courses by semantic affinity, career goals, and Indramayu hyperlocal proximity.
class CourseRelevanceService {
  static const String _storageKey = 'skilloka_user_education_preference';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Securely save user preference
  static Future<void> savePreference(UserProfilePreference preference) async {
    try {
      final jsonStr = jsonEncode(preference.toJson());
      await _secureStorage.write(key: _storageKey, value: jsonStr);
    } catch (e) {
      debugPrint('Error saving user profile preference: $e');
    }
  }

  /// Securely retrieve user preference
  static Future<UserProfilePreference?> getPreference() async {
    try {
      final jsonStr = await _secureStorage.read(key: _storageKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr);
      if (map is Map<String, dynamic>) {
        return UserProfilePreference.fromJson(map);
      }
    } catch (e) {
      debugPrint('Error reading user profile preference: $e');
    }
    return null;
  }

  /// Sanitize user input text to prevent XSS and malformed payloads
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>{}]'), '')
        .trim();
  }

  /// Semantic clusters for vocational skills in Indramayu
  static final Map<String, List<String>> _clusterKeywords = {
    'teknologi': [
      'ti', 'tkj', 'rpl', 'multimedia', 'komputer', 'informatika', 'it',
      'web', 'coding', 'desain', 'grafis', 'programming', 'software', 'network'
    ],
    'otomotif': [
      'otomotif', 'tmo', 'motor', 'mobil', 'mesin', 'mekanik', 'kendaraan',
      'tpm', 'bengkel', 'servis'
    ],
    'pengelasan': [
      'las', 'welding', 'smaw', 'gmaw', 'mig', 'tig', 'fabrikasi', 'logam', 'besi'
    ],
    'bahasa': [
      'bahasa', 'jepang', 'korea', 'inggris', 'mandarin', 'toefl', 'jlpt',
      'eps-topik', 'magang jepang', 'gino jisshusei'
    ],
    'kuliner': [
      'boga', 'masak', 'kuliner', 'kue', 'bakery', 'pastry', 'chef',
      'barista', 'kopi', 'makanan'
    ],
    'busana': [
      'busana', 'jahit', 'fashion', 'menjahit', 'garmen', 'desain busana', 'pola'
    ],
    'bisnis': [
      'akuntansi', 'bisnis', 'manajemen', 'administrasi', 'pemasaran',
      'keuangan', 'kantor', 'sekretaris', 'office'
    ],
  };

  /// Rank courses according to user profile using explainable multi-signal scoring
  static List<ScoredCourse> rankCourses({
    required List<CourseModel> courses,
    required UserProfilePreference preference,
  }) {
    if (courses.isEmpty) return [];

    final majorClean = preference.major.toLowerCase();
    final majorTokens = majorClean
        .split(RegExp(r'[\s,&/+-]+'))
        .where((t) => t.length > 1)
        .toList();

    final goalClean = preference.careerGoal.toLowerCase();
    final locationClean = preference.preferredLocation?.toLowerCase() ?? '';

    // Identify user affinity clusters
    final userClusters = <String>{};
    for (final entry in _clusterKeywords.entries) {
      final clusterName = entry.key;
      final keywords = entry.value;
      if (keywords.any((kw) => majorClean.contains(kw))) {
        userClusters.add(clusterName);
      }
    }

    final scoredList = <ScoredCourse>[];

    for (final course in courses) {
      final titleLower = course.title.toLowerCase();
      final descLower = course.description.toLowerCase();
      final catLower = course.categoryName.toLowerCase();
      final lpkLower = course.lpkName.toLowerCase();
      final facilitiesLower = course.facilities.join(' ').toLowerCase();

      int score = 45; // baseline interest score
      final tags = <String>[];
      String primaryReason = 'Rekomendasi Populer';

      // 1. Direct Keyword Matching (Title & Category)
      bool hasDirectKeyword = false;
      for (final token in majorTokens) {
        if (titleLower.contains(token)) {
          score += 35;
          hasDirectKeyword = true;
          tags.add('Sesuai Kata Kunci: $token');
        } else if (catLower.contains(token)) {
          score += 25;
          hasDirectKeyword = true;
          tags.add('Kategori $token');
        } else if (descLower.contains(token) || facilitiesLower.contains(token)) {
          score += 15;
          hasDirectKeyword = true;
        }
      }

      // 2. Semantic Cluster Alignment
      bool clusterMatched = false;
      for (final cluster in userClusters) {
        final keywords = _clusterKeywords[cluster] ?? [];
        if (keywords.any((kw) =>
            titleLower.contains(kw) || catLower.contains(kw) || descLower.contains(kw))) {
          score += 30;
          clusterMatched = true;
          tags.add('Bidang ${cluster.toUpperCase()}');
        }
      }

      // 3. Career Goal Alignment
      if (goalClean.contains('wirausaha') || goalClean.contains('bisnis')) {
        if (catLower.contains('boga') ||
            catLower.contains('busana') ||
            titleLower.contains('barista') ||
            titleLower.contains('las') ||
            titleLower.contains('otomotif')) {
          score += 15;
          tags.add('Potensi Wirausaha');
        }
      } else if (goalClean.contains('luar negeri')) {
        if (catLower.contains('bahasa') ||
            titleLower.contains('las') ||
            titleLower.contains('jepang') ||
            titleLower.contains('korea')) {
          score += 20;
          tags.add('Peluang Karir Global');
        }
      } else if (goalClean.contains('kerja pertama') || goalClean.contains('keahlian kerja')) {
        if (course.level.toLowerCase().contains('pemula') ||
            course.facilities.any((f) => f.toLowerCase().contains('sertifikat'))) {
          score += 15;
          tags.add('Siap Kerja Bersertifikat');
        }
      }

      // 4. Hyperlocal Proximity
      if (locationClean.isNotEmpty) {
        if (lpkLower.contains(locationClean) || descLower.contains(locationClean)) {
          score += 10;
          tags.add('Lokasi Dekat');
        }
      }

      // Clamp score to realistic 55 - 99%
      final clampedScore = score.clamp(55, 99);

      // Determine human-friendly transparent explanation
      if (hasDirectKeyword || clusterMatched) {
        if (preference.major.isNotEmpty) {
          primaryReason = '$clampedScore% Cocok untuk Jurusan ${preference.major}';
        } else {
          primaryReason = '$clampedScore% Relevan dengan Target Karir';
        }
      } else if (tags.contains('Potensi Wirausaha')) {
        primaryReason = '$clampedScore% Jalur Cepat Buka Usaha Mandiri';
      } else if (tags.contains('Peluang Karir Global')) {
        primaryReason = '$clampedScore% Membuka Penempatan Kerja Luar Negeri';
      } else if (tags.contains('Siap Kerja Bersertifikat')) {
        primaryReason = '$clampedScore% Program Sertifikasi Siap Kerja';
      } else {
        primaryReason = '$clampedScore% Pelatihan Pilihan Prioritas';
      }

      scoredList.add(ScoredCourse(
        course: course,
        score: clampedScore,
        matchReason: primaryReason,
        matchingTags: tags,
      ));
    }

    // Sort by relevance score descending
    scoredList.sort((a, b) => b.score.compareTo(a.score));

    return scoredList;
  }
}
