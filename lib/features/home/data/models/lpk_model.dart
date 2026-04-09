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
      id: json['id'].toString(),
      name: json['name'] ?? '',
      legalName: json['legal_name'],
      address: json['address'] ?? '',
      logoUrl: json['logo_url'],
      images: List<String>.from(json['images'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['long'] != null ? double.tryParse(json['long'].toString()) : null,
      facilities: List<String>.from(json['facilities'] ?? []),
      contactInfo: Map<String, dynamic>.from(json['contact_info'] ?? {}),
      locationName: json['location']?['name'],
      coursesCount: json['courses_count'] ?? 0,
      status: json['status'] ?? 'active',
    );
  }

  String? get phone => contactInfo['phone'] as String?;
  String? get whatsapp => contactInfo['whatsapp'] as String?;
  String? get email => contactInfo['email'] as String?;
}
