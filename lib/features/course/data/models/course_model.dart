import 'dart:convert';
import '../../../../core/services/api_service.dart';

class CourseModel {
  final String id;
  final String title;
  final String slug;
  final double price;
  final int durationHours;
  final String description;
  final Map<String, dynamic> lpk;
  final Map<String, dynamic> category;
  final List<String> images;
  final String level;
  final List<String> facilities;
  final List<dynamic> schedules;

  CourseModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    required this.durationHours,
    this.description = '',
    required this.lpk,
    required this.category,
    required this.images,
    required this.level,
    this.facilities = const [],
    this.schedules = const [],
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    // ── Parse & normalize images agar selalu dynamic sesuai upload LPK ──
    final List<String> parsedImages = [];
    final rawImages = json['images'];

    if (rawImages is List) {
      for (final item in rawImages) {
        if (item != null) {
          final s = item.toString().trim();
          if (s.isNotEmpty) {
            final full = ApiService.toFullUrl(s);
            if (full.isNotEmpty) parsedImages.add(full);
          }
        }
      }
    } else if (rawImages is String && rawImages.trim().isNotEmpty) {
      final s = rawImages.trim();
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            for (final d in decoded) {
              if (d != null) {
                final full = ApiService.toFullUrl(d.toString().trim());
                if (full.isNotEmpty) parsedImages.add(full);
              }
            }
          }
        } catch (_) {
          final full = ApiService.toFullUrl(s);
          if (full.isNotEmpty) parsedImages.add(full);
        }
      } else {
        final full = ApiService.toFullUrl(s);
        if (full.isNotEmpty) parsedImages.add(full);
      }
    }

    // Fallback key jika images array kosong
    if (parsedImages.isEmpty) {
      final fallbackRaw = json['image_url'] ??
          json['image'] ??
          json['thumbnail'] ??
          json['cover_image'];
      if (fallbackRaw != null && fallbackRaw.toString().trim().isNotEmpty) {
        final full = ApiService.toFullUrl(fallbackRaw.toString().trim());
        if (full.isNotEmpty) parsedImages.add(full);
      }
    }

    // ── Parse & normalize lpk logo ──
    Map<String, dynamic> parsedLpk = {};
    if (json['lpk'] is Map) {
      parsedLpk = Map<String, dynamic>.from(json['lpk']);
      if (parsedLpk['logo'] != null &&
          parsedLpk['logo'].toString().isNotEmpty) {
        parsedLpk['logo'] = ApiService.toFullUrl(parsedLpk['logo'].toString());
      }
      if (parsedLpk['logo_url'] != null &&
          parsedLpk['logo_url'].toString().isNotEmpty) {
        parsedLpk['logo_url'] =
            ApiService.toFullUrl(parsedLpk['logo_url'].toString());
      }
    }

    return CourseModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      price: json['price'] != null
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      durationHours: json['duration_hours'] != null
          ? int.tryParse(json['duration_hours'].toString()) ?? 0
          : 0,
      description: json['description']?.toString() ?? '',
      lpk: parsedLpk,
      category: json['category'] is Map
          ? Map<String, dynamic>.from(json['category'])
          : {},
      images: parsedImages,
      level: json['level']?.toString() ?? '',
      facilities: json['facilities'] is List
          ? List<String>.from(json['facilities'].map((e) => e.toString()))
          : const [],
      schedules: json['schedules'] is List ? json['schedules'] : const [],
    );
  }

  String get lpkName => lpk['name']?.toString() ?? 'LPK';
  String? get lpkLogo => lpk['logo']?.toString() ?? lpk['logo_url']?.toString();
  String get categoryName => category['name']?.toString() ?? 'Umum';
  String get firstImage => images.isNotEmpty ? images.first : '';

  /// Return empty string to prevent loading dummy Unsplash images
  String get fallbackImage => '';

  static String getFallbackImage({String title = '', String category = ''}) => '';
}

