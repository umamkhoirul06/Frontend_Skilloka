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

  // 🔥 Ubah status ke Bahasa Indonesia (Kapital di awal)
  bool get isPending => status == 'Menunggu';
  bool get isConfirmed => status == 'Selesai';
  bool get isCompleted => status == 'Selesai';
  bool get isCancelled => status == 'Dibatalkan';

  String get statusLabel {
    switch (status) {
      case 'Menunggu':
        return 'Menunggu Pembayaran';
      case 'Selesai':
        return 'Lunas';
      case 'Dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}

// 🔥 KELAS INI HARUS BERDIRI SENDIRI DI LUAR BookingModel
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
      // 🔥 FIX FORMAT TANGGAL
      startDate: json['date']?.toString() ?? 'Belum ditentukan',
      endDate: json['end_date']?.toString(),
      courseTitle: json['title'] ?? json['name'] ?? 'Kursus',
      courseImageUrl: ApiService.toFullUrl(rawImg),
      lpkName: lpk?['name'] ?? 'LPK Tidak Diketahui',
      categoryName: category?['name'] ?? 'Umum',
    );
  }
}
