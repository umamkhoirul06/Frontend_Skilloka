class CourseModel {
  final String id;
  final String title;
  final String slug;
  final double price;
  final int durationHours;
  final Map<String, dynamic> lpk;
  final Map<String, dynamic> category;
  final List<String> images;
  final String level;

  CourseModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    required this.durationHours,
    required this.lpk,
    required this.category,
    required this.images,
    required this.level,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      durationHours: json['duration_hours'] ?? 0,
      lpk: json['lpk'] is Map ? Map<String, dynamic>.from(json['lpk']) : {},
      category: json['category'] is Map ? Map<String, dynamic>.from(json['category']) : {},
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      level: json['level'] ?? '',
    );
  }
}
