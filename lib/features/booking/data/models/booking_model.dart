class ScheduleInfo {
  final String? id;
  final String? courseId;
  final String? courseTitle;
  final String? courseImageUrl;
  final String? lpkName;
  final String? lpkLogoUrl;
  final String? categoryName;
  final String? startDate;
  final String? endDate;

  const ScheduleInfo({
    this.id,
    this.courseId,
    this.courseTitle,
    this.courseImageUrl,
    this.lpkName,
    this.lpkLogoUrl,
    this.categoryName,
    this.startDate,
    this.endDate,
  });

  factory ScheduleInfo.fromJson(Map<String, dynamic> json) {
    return ScheduleInfo(
      id: json['id']?.toString(),
      courseId: json['courseId']?.toString(),
      courseTitle: json['courseTitle']?.toString(),
      courseImageUrl: json['courseImageUrl']?.toString(),
      lpkName: json['lpkName']?.toString(),
      lpkLogoUrl: json['lpkLogoUrl']?.toString(),
      categoryName: json['categoryName']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
    );
  }
}

class BookingModel {
  final String id;
  final String code;
  final String status;
  final double amount;
  final String? expiresAt;
  final String? createdAt;
  final ScheduleInfo? schedule;

  const BookingModel({
    required this.id,
    required this.code,
    required this.status,
    required this.amount,
    this.expiresAt,
    this.createdAt,
    this.schedule,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      amount: (json['amount'] ?? 0).toDouble(),
      expiresAt: json['expires_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      schedule: json['schedule'] != null
          ? ScheduleInfo.fromJson(json['schedule'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Menunggu';
    }
  }
}
