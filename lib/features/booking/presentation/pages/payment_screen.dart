import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';

class PaymentScreen extends StatefulWidget {
  final String courseId;
  final String? bookingId;
  final String? amount;

  const PaymentScreen({
    super.key,
    required this.courseId,
    this.bookingId,
    this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  String? _qrCodeUrl;
  String _errorMessage = '';

  String? get _safeBookingId {
    final id = widget.bookingId;
    if (id == null || id.isEmpty) return null;
    return id.replaceAll(':', ''); // Membersihkan artefak string
  }

  @override
  void initState() {
    super.initState();
    _fetchQrCode();
  }

  // 🔥 Mengambil URL QR Code asli dari server Laravel kamu
  Future<void> _fetchQrCode() async {
    if (_safeBookingId == null) {
      setState(() {
        _errorMessage = 'ID Booking tidak ditemukan.';
        _isLoading = false;
      });
      return;
    }

    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/bookings/$_safeBookingId');
      final data = response.data['data'];

      setState(() {
        _qrCodeUrl = data['qr_code_url'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat QR Code pembayaran.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Manual')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage,
                      style: const TextStyle(color: Colors.red)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 💳 Kartu Total Pembayaran
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppShapes.borderRadiusMD,
                        ),
                        child: Column(
                          children: [
                            Text('Total Tagihan',
                                style: AppTypography.labelLarge),
                            const SizedBox(height: 8),
                            Text(
                              'Rp ${widget.amount ?? '0'}',
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Silakan Scan QR Code berikut\nuntuk melakukan pembayaran',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 24),

                      // 🖼️ Menampilkan Gambar QR Code
                      if (_qrCodeUrl != null && _qrCodeUrl!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: Image.network(
                            _qrCodeUrl!,
                            width: 250,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    size: 100, color: Colors.grey),
                          ),
                        )
                      else
                        const Text(
                          'QR Code belum tersedia.',
                          style: TextStyle(color: Colors.red),
                        ),

                      const SizedBox(height: 32),

                      Text(
                        'Setelah melakukan pembayaran, Admin LPK akan memverifikasi dan memperbarui status Anda menjadi LUNAS.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 32),

                      // ✅ Tombol Konfirmasi Selesai
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Langsung arahkan ke halaman Sukses
                            context.push(
                                AppRouter.bookingSuccessPath(_safeBookingId!));
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppShapes.borderRadiusMD,
                            ),
                          ),
                          child: const Text(
                            'Saya Sudah Bayar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
