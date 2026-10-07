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
      lpk: json['lpk'] is Map ? Map<String, dynamic>.from(json['lpk']) : {},
      category: json['category'] is Map
          ? Map<String, dynamic>.from(json['category'])
          : {},
      images: json['images'] is List
          ? List<String>.from(json['images'].map((e) => e.toString()))
          : (json['images'] is String && (json['images'] as String).isNotEmpty
              ? [json['images'].toString()]
              : const []),
      level: json['level']?.toString() ?? '',
      facilities: json['facilities'] is List
          ? List<String>.from(json['facilities'].map((e) => e.toString()))
          : const [],
      schedules: json['schedules'] is List ? json['schedules'] : const [],
    );
  }

  String get lpkName => lpk['name']?.toString() ?? 'LPK';
  String? get lpkLogo => lpk['logo']?.toString();
  String get categoryName => category['name']?.toString() ?? 'Umum';
  String get firstImage => images.isNotEmpty ? images.first : '';
}
