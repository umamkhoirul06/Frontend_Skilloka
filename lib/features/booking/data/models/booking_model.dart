/// Model untuk data Booking dari API
class BookingModel {
  final String id;
  final String code;
  final String status;
  final double amount;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final BookingScheduleModel? schedule;

  const BookingModel({
    required this.id,
    required this.code,
    required this.status,
    required this.amount,
    this.expiresAt,
    required this.createdAt,
    this.schedule,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'].toString(),
      code: json['code'] ?? '',
      status: json['status'] ?? 'pending',
      amount: (json['amount'] ?? 0).toDouble(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      schedule: json['schedule'] != null
          ? BookingScheduleModel.fromJson(json['schedule'])
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'pending':    return 'Menunggu Konfirmasi';
      case 'confirmed':  return 'Dikonfirmasi';
      case 'cancelled':  return 'Dibatalkan';
      case 'completed':  return 'Selesai';
      default:           return status;
    }
  }
}

class BookingScheduleModel {
  final String id;
  final String? startDate;
  final String? endDate;
  final String? courseId;
  final String? courseTitle;
  final String? courseImageUrl;
  final String? lpkName;
  final String? lpkLogoUrl;
  final String? categoryName;

  const BookingScheduleModel({
    required this.id,
    this.startDate,
    this.endDate,
    this.courseId,
    this.courseTitle,
    this.courseImageUrl,
    this.lpkName,
    this.lpkLogoUrl,
    this.categoryName,
  });

  factory BookingScheduleModel.fromJson(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>?;
    final lpk = course?['lpk'] as Map<String, dynamic>?;
    final category = course?['category'] as Map<String, dynamic>?;

    return BookingScheduleModel(
      id: json['id'].toString(),
      startDate: json['start_date'],
      endDate: json['end_date'],
      courseId: course?['id']?.toString(),
      courseTitle: course?['title'],
      courseImageUrl: (course?['images'] as List?)?.isNotEmpty == true
          ? course!['images'][0] as String?
          : null,
      lpkName: lpk?['name'],
      lpkLogoUrl: lpk?['logo'],
      categoryName: category?['name'],
    );
  }
}
