import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/atoms/animated_button.dart';

class PendingBookingScreen extends StatefulWidget {
  final String bookingId;
  const PendingBookingScreen({super.key, required this.bookingId});

  @override
  State<PendingBookingScreen> createState() => _PendingBookingScreenState();
}

class _PendingBookingScreenState extends State<PendingBookingScreen> {
  bool _isApproved = false;
  bool _isCancelled = false;
  String? _qrUrl;
  String _statusLabel = 'Menunggu Persetujuan Admin LPK...';
  Map<String, dynamic>? _bookingData;
  Timer? _timer;
  int _pollCount = 0;
  static const int _maxPolls = 60; // max 5 menit polling (5s * 60)

  @override
  void initState() {
    super.initState();
    // Langsung cek sekali saat pertama buka
    _checkStatus();
    // Kemudian polling tiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_pollCount >= _maxPolls) {
      _timer?.cancel();
      return;
    }
    _pollCount++;

    try {
      final response =
          await sl<ApiClient>().get('/bookings/${widget.bookingId}');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        // 🔥 Ubah ke huruf kecil semua agar lebih kebal terhadap typo/case sensitive
        final status = (data['status'] as String? ?? 'pending').toLowerCase();

        if (!mounted) return;

        // 🔥 FIX 1: Ganti 'confirmed' menjadi 'selesai'
        if (status == 'selesai') {
          _timer?.cancel();
          setState(() {
            _isApproved = true;
            _bookingData = data;
            _qrUrl = data['qr_code_url'] as String?;
          });
        // 🔥 FIX 2: Ganti 'cancelled' menjadi 'dibatalkan'
        } else if (status == 'dibatalkan') {
          _timer?.cancel();
          setState(() {
            _isCancelled = true;
            _bookingData = data;
          });
        } else {
          // Masih pending / Menunggu
          setState(() {
            _bookingData = data;
            _statusLabel = 'Menunggu Persetujuan Admin LPK...';
          });
        }
      }
    } catch (e) {
      debugPrint("Polling error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Booking'),
        // Cegah back saat masih pending agar user tidak skip proses
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

  // ─── State: Masih Menunggu ───────────────────────────────────────────────
  Widget _buildPending() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox.shrink(),
        const Spacer(),
        // Animasi loading
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Booking Sedang Diproses',
          style: AppTypography.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _statusLabel,
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Info booking (jika sudah ter-load)
        if (_bookingData != null) _buildBookingInfo(),

        const Spacer(),

        // Info polling
        Text(
          'Halaman ini akan otomatis diperbarui setiap 5 detik.',
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _checkStatus,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Periksa Sekarang'),
        ),
      ],
    );
  }

  // ─── State: Disetujui ────────────────────────────────────────────────────
  Widget _buildApproved() {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: AppColors.successContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Booking Disetujui!',
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Tunjukkan QR Code ini kepada staf LPK saat hadir.',
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // QR Code dari backend
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppShapes.cardRadius,
            border: Border.all(color: AppColors.outline),
            boxShadow: AppShapes.shadowMD,
          ),
          child: Column(
            children: [
              if (_bookingData != null) _buildBookingInfo(),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // QR Code
              if (_qrUrl != null && _qrUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: AppShapes.borderRadiusMD,
                  child: Image.network(
                    _qrUrl!,
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 160,
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, __, ___) => _buildQrFallback(),
                  ),
                )
              else
                _buildQrFallback(),

              const SizedBox(height: 12),
              Text(
                'Tunjukkan QR Code ini ke LPK',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Tombol ke halaman pesanan
        AnimatedPrimaryButton(
          text: 'Lihat Pesanan Saya',
          onPressed: () => context.go(AppRouter.bookings),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go(AppRouter.home),
          child: const Text('Kembali ke Beranda'),
        ),
      ],
    );
  }

  // ─── State: Dibatalkan ───────────────────────────────────────────────────
  Widget _buildCancelled() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cancel,
            color: AppColors.error,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Booking Ditolak',
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Maaf, booking Anda tidak dapat disetujui oleh LPK.',
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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

  // ─── Widget: Info Booking ────────────────────────────────────────────────
  Widget _buildBookingInfo() {
    final data = _bookingData!;
    final courseTitle = data['course']?['title'] ??
        data['schedule']?['course_title'] ??
        'Kursus';
    final lpkName = data['course']?['lpk']?['name'] ??
        data['schedule']?['lpk_name'] ??
        'LPK';
    final bookingCode = data['code'] ?? widget.bookingId;

    return Column(
      children: [
        _buildInfoRow('Kode Booking', bookingCode),
        _buildInfoRow('Kursus', courseTitle),
        _buildInfoRow('LPK', lpkName),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: AppTypography.labelMedium),
          ),
        ],
      ),
    );
  }

  // QR fallback jika URL kosong / error
  Widget _buildQrFallback() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.borderRadiusSM,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code, size: 80, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text(
            'QR Code\ntidak tersedia',
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
