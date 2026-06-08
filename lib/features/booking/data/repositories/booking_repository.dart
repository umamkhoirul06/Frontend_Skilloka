/// Repository untuk mengambil data Booking dari API
import '../models/booking_model.dart';
import '../../../../core/network/api_client.dart';

class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Ambil semua booking user yang login
  Future<List<BookingModel>> getMyBookings() async {
    // 🔥 FIX: Menembak tepat ke /bookings (Sesuai dengan api.php Laravel)
    final response = await _apiClient.get('/bookings');
    final data = response.data['data'];
    final items = (data['data'] ?? data) as List;
    return items.map((e) => BookingModel.fromJson(e)).toList();
  }

  /// Detail satu booking
  Future<BookingModel> getBookingDetail(String id) async {
    // 🔥 FIX: Menembak tepat ke /bookings/{id}
    final response = await _apiClient.get('/bookings/$id');
    return BookingModel.fromJson(response.data['data']);
  }

  /// Buat booking baru
  Future<BookingModel> createBooking({required String scheduleId}) async {
    // 🔥 FIX: Menembak tepat ke /bookings
    final response = await _apiClient.post(
      '/bookings',
      data: {'schedule_id': scheduleId},
    );
    return BookingModel.fromJson(response.data['data']);
  }

  /// Batalkan booking
  Future<BookingModel> cancelBooking(String id) async {
    // 🔥 FIX: Menembak tepat ke /bookings/{id}/cancel
    final response = await _apiClient.patch('/bookings/$id/cancel');
    return BookingModel.fromJson(response.data['data']);
  }
}
