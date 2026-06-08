import '../../../../core/services/api_service.dart';

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
    // 🔥 PINTARKAN BACA JSON: Coba baca 'course' dulu (dari Laravel), kalau gak ada baru 'schedule'
    final courseData = json['course'] ?? json['schedule'];

    return BookingModel(
      id: json['id'].toString(),
      code: json['code'] ?? '',
      status: json['status'] ?? 'pending',
      amount: (json['amount'] ?? 0).toDouble(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      schedule:
          courseData != null ? BookingScheduleModel.fromJson(courseData) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'confirmed':
        return 'Dikonfirmasi (Lunas)';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}

class BookingScheduleModel {
  final String id;
  final String? startDate;
  final String? endDate;
  final String? courseTitle;
  final String? courseImageUrl;
  final String? lpkName;
  final String? categoryName;

  const BookingScheduleModel({
    required this.id,
    this.startDate,
    this.endDate,
    this.courseTitle,
    this.courseImageUrl,
    this.lpkName,
    this.categoryName,
  });

  factory BookingScheduleModel.fromJson(Map<String, dynamic> json) {
    final lpk = json['lpk'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;

    // 🔥 PENGAMAN FOTO AGAR TAB PESANAN TIDAK CRASH
    String rawImg = '';
    if (json['images'] != null &&
        json['images'] is List &&
        (json['images'] as List).isNotEmpty) {
      rawImg = json['images'][0].toString();
    } else {
      rawImg = json['image_url'] ?? '';
    }

    return BookingScheduleModel(
      id: json['id'].toString(),
      startDate: json['start_date'] ?? 'Belum ditentukan',
      endDate: json['end_date'],
      courseTitle: json['title'] ?? json['name'] ?? 'Kursus',
      courseImageUrl: ApiService.toFullUrl(rawImg),
      lpkName: lpk?['name'] ?? 'LPK Tidak Diketahui',
      categoryName: category?['name'] ?? 'Umum',
    );
  }
}
