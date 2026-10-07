/// Model untuk data LPK dari API
class LpkModel {
  final String id;
  final String name;
  final String? legalName;
  final String address;
  final String? logoUrl;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final double? lat;
  final double? lng;
  final List<String> facilities;
  final Map<String, dynamic> contactInfo;
  final String? locationName;
  final int coursesCount;
  final String status;

  const LpkModel({
    required this.id,
    required this.name,
    this.legalName,
    required this.address,
    this.logoUrl,
    this.images = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.lat,
    this.lng,
    this.facilities = const [],
    this.contactInfo = const {},
    this.locationName,
    this.coursesCount = 0,
    this.status = 'active',
  });

  factory LpkModel.fromJson(Map<String, dynamic> json) {
    return LpkModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      legalName: json['legal_name']?.toString(),
      address: json['address']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? json['logo']?.toString(),
      images: _parseStringList(json['images']),
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) ?? 0.0 : 0.0,
      reviewCount: json['review_count'] != null ? int.tryParse(json['review_count'].toString()) ?? 0 : 0,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1 || json['is_verified'] == '1',
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: (json['long'] ?? json['lng']) != null ? double.tryParse((json['long'] ?? json['lng']).toString()) : null,
      facilities: _parseFacilities(json['facilities']),
      contactInfo: _parseContactInfo(json['contact_info']),
      locationName: json['location'] is Map ? json['location']['name']?.toString() : null,
      coursesCount: json['courses_count'] != null ? int.tryParse(json['courses_count'].toString()) ?? 0 : 0,
      status: json['status']?.toString() ?? 'active',
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }
    return const [];
  }

  static List<String> _parseFacilities(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const [];
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = List<dynamic>.from(raw as dynamic);
          return decoded.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        } catch (_) {}
      }
      // If it contains newlines or bullets, split them
      if (trimmed.contains('\n') || trimmed.contains('•')) {
        return trimmed
            .split(RegExp(r'[\n•]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.length < 80)
            .toList();
      }
      return [trimmed];
    }
    return const [];
  }

  static Map<String, dynamic> _parseContactInfo(dynamic raw) {
    if (raw == null) return const {};
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  String? get phone => contactInfo['phone'] as String?;
  String? get whatsapp => contactInfo['whatsapp'] as String?;
  String? get email => contactInfo['email'] as String?;
}
