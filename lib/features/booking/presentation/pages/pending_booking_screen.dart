import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/atoms/animated_button.dart';

/// Halaman Menunggu Pembayaran & Approval — PRD Section 25 & Midtrans Integration
class PendingBookingScreen extends StatefulWidget {
  final String bookingId;
  const PendingBookingScreen({super.key, required this.bookingId});

  @override
  State<PendingBookingScreen> createState() => _PendingBookingScreenState();
}

class _PendingBookingScreenState extends State<PendingBookingScreen> {
  bool _isApproved = false;
  bool _isCancelled = false;
  bool _isPaying = false;
  String _statusLabel = 'Menunggu pembayaran kursus via Midtrans.';
  Map<String, dynamic>? _bookingData;
  Timer? _timer;
  int _pollCount = 0;
  static const int _maxPolls = 60; // max 5 menit polling (5s * 60)

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Langsung cek status saat layar pertama dibuka
    _checkStatus();
    // Kemudian polling otomatis tiap 4 detik
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Membuka popup / in-app browser Midtrans Snap Checkout
  Future<void> _startPayment() async {
    if (_isPaying) return;

    setState(() => _isPaying = true);

    try {
      String? snapToken;
      String? redirectUrl;

      // 1. Coba inisiasi via endpoint standar PRD /bookings/{id}/payment
      try {
        final payResult = await _apiService.createBookingPayment(
          bookingId: widget.bookingId,
          paymentMethod: 'midtrans',
        );

        if (payResult['success'] == true) {
          final payData = payResult['data'] is Map ? payResult['data'] : {};
          snapToken = payData['snap_token']?.toString() ??
              payData['data']?['snap_token']?.toString();
          redirectUrl = payData['redirect_url']?.toString() ??
              payData['data']?['redirect_url']?.toString();
        }
      } catch (e) {
        debugPrint("Error createBookingPayment: $e");
      }

      // 2. Fallback via endpoint /payment/create-transaction
      if (snapToken == null && redirectUrl == null) {
        final response = await sl<ApiClient>().post(
          '/payment/create-transaction',
          data: {'order_id': widget.bookingId},
        );
        final data = response.data as Map<String, dynamic>;
        snapToken = data['snap_token'] as String?;
        redirectUrl = data['redirect_url'] as String?;
      }

      // 3. Format URL Snap Midtrans
      if ((redirectUrl == null || redirectUrl.isEmpty) &&
          snapToken != null &&
          snapToken.isNotEmpty) {
        redirectUrl = AppConfig.getMidtransSnapUrl(snapToken);
      }

      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('Token atau tautan pembayaran tidak diterima dari server.');
      }

      final checkoutUri = Uri.parse(redirectUrl);

      // 4. Buka dengan inAppBrowserView (Chrome Custom Tabs) agar pengalaman mulus di dalam app
      bool opened = false;
      try {
        opened = await launchUrl(
          checkoutUri,
          mode: LaunchMode.inAppBrowserView,
        );
      } catch (_) {
        opened = await launchUrl(
          checkoutUri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!opened) {
        throw Exception('Halaman pembayaran Midtrans gagal dibuka.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout Midtrans dibuka. Silakan selesaikan pembayaran.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Cek status segera setelah user kembali
      Future.delayed(const Duration(seconds: 2), _checkStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka pembayaran: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  /// Cek status booking secara real-time ke backend Laravel
  Future<void> _checkStatus() async {
    if (_pollCount >= _maxPolls) {
      _timer?.cancel();
      return;
    }
    _pollCount++;

    try {
      final response = await sl<ApiClient>().get('/bookings/${widget.bookingId}');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final status = (data['status'] as String? ?? 'pending').toLowerCase();

        if (!mounted) return;

        // Status sukses / lunas / terkonfirmasi
        final isApproved = [
          'confirmed',
          'approved',
          'completed',
          'paid',
          'lunas',
          'selesai',
          'disetujui',
          'dikonfirmasi',
          'settlement',
          'capture',
          'success',
        ].contains(status);

        // Status dibatalkan / gagal
        final isCancelled = [
          'cancelled',
          'canceled',
          'rejected',
          'dibatalkan',
          'ditolak',
          'expire',
          'expired',
          'deny',
        ].contains(status);

        if (isApproved) {
          _timer?.cancel();
          setState(() {
            _isApproved = true;
            _bookingData = data;
          });

          // Otomatis transisi ke halaman sukses jika pembayaran sudah terverifikasi!
          if (mounted) {
            context.pushReplacement(AppRouter.bookingSuccessPath(widget.bookingId));
          }
          return;
        } else if (isCancelled) {
          _timer?.cancel();
          setState(() {
            _isCancelled = true;
            _bookingData = data;
          });
        } else {
          setState(() {
            _bookingData = data;
            if (status.contains('menunggu') || status.contains('pending')) {
              _statusLabel = 'Pendaftaran berhasil dibuat. Silakan lakukan pembayaran via Midtrans.';
            } else {
              _statusLabel = 'Status pendaftaran: ${data['status'] ?? 'Menunggu Verifikasi'}.';
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Polling error: $e");
    }
  }

  /// Simulasi pembayaran berhasil (fitur bantuan testing sandbox / development)
  Future<void> _simulatePaymentSuccess() async {
    try {
      final apiClient = sl<ApiClient>();
      await apiClient.post('/payment/confirm-dummy', data: {
        'booking_id': widget.bookingId,
        'method': 'qris',
      });
    } catch (e) {
      debugPrint("Simulate payment error: $e");
    }

    await _checkStatus();
    if (!_isApproved && mounted) {
      context.pushReplacement(AppRouter.bookingSuccessPath(widget.bookingId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Status Pendaftaran'),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: _isApproved || _isCancelled,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isCancelled
              ? _buildCancelled()
              : _isApproved
                  ? _buildApproved()
                  : _buildPending(),
        ),
      ),
    );
  }

  // ─── STATE: MENUNGGU PEMBAYARAN ───────────────────────────────────────────
  Widget _buildPending() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Loading / Status Visual
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(22),
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Menunggu Pembayaran Midtrans',
          style: AppTypography.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Text(
          _statusLabel,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Info Booking Ringkas
        if (_bookingData != null) _buildBookingInfoCard(),

        const SizedBox(height: 24),

        // Tombol Bayar via Midtrans
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isPaying ? null : _startPayment,
            icon: _isPaying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.payment, size: 20),
            label: Text(
              _isPaying ? 'Menyiapkan Midtrans...' : 'Bayar Sekarang via Midtrans',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ),

        const Spacer(),

        // Info polling & tombol cek manual
        Text(
          'Halaman ini akan otomatis diperbarui setiap 4 detik.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _checkStatus,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Periksa Status Sekarang'),
            ),
            if (!kReleaseMode) ...[
              const Text(' • ', style: TextStyle(color: AppColors.textTertiary)),
              TextButton(
                onPressed: _simulatePaymentSuccess,
                child: const Text('Simulasi Sukses (Dev)', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ─── STATE: DISETUJUI / SUKSES ────────────────────────────────────────────
  Widget _buildApproved() {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: AppColors.successContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 56,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Pembayaran Terkonfirmasi!',
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Pendaftaran pelatihan Anda telah berhasil dan terverifikasi.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        if (_bookingData != null) _buildBookingInfoCard(),

        const Spacer(),

        AnimatedPrimaryButton(
          text: 'Lihat Tiket & Fitur Langganan',
          onPressed: () => context.pushReplacement(AppRouter.bookingSuccessPath(widget.bookingId)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go(AppRouter.home),
          child: const Text('Kembali ke Beranda'),
        ),
      ],
    );
  }

  // ─── STATE: DIBATALKAN ────────────────────────────────────────────────────
  Widget _buildCancelled() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel, color: AppColors.error, size: 56),
        ),
        const SizedBox(height: 20),
        Text('Pendaftaran Dibatalkan', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Pendaftaran atau pembayaran ini telah dibatalkan / kedaluwarsa.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        AnimatedPrimaryButton(
          text: 'Cari Kursus Lain',
          onPressed: () => context.go(AppRouter.home),
        ),
      ],
    );
  }

  // ─── INFO CARD ────────────────────────────────────────────────────────────
  Widget _buildBookingInfoCard() {
    final data = _bookingData!;
    final courseTitle = data['course']?['title'] ??
        data['schedule']?['course_title'] ??
        'Kursus';
    final lpkName = data['course']?['lpk']?['name'] ??
        data['schedule']?['lpk_name'] ??
        'LPK Mitra';
    final bookingCode = data['code'] ?? widget.bookingId;
    final isSubscription = data['service_type'] == 'subscription' ||
        data['include_subscription'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShapes.borderRadiusMD,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          _buildInfoRow('Kode Booking', bookingCode),
          _buildInfoRow('Kursus', courseTitle),
          _buildInfoRow('LPK', lpkName),
          _buildInfoRow(
            'Layanan',
            isSubscription ? 'Booking + Langganan Premium' : 'Booking Reguler',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: AppTypography.labelMedium)),
        ],
      ),
    );
  }
}
