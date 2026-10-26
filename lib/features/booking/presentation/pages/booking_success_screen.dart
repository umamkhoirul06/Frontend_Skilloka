import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';

/// Layar Pembayaran & Pendaftaran Sukses — PRD 8.7 & Akses Fitur Langganan
class BookingSuccessScreen extends StatefulWidget {
  final String bookingId;
  const BookingSuccessScreen({super.key, required this.bookingId});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  bool _isLoading = true;
  String _courseTitle = 'Memuat...';
  String _lpkName = 'Memuat...';
  String _bookingCode = '-';
  String? _courseId;
  bool _hasSubscription = false;
  String? _qrUrl;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _controller =
        AnimationController(vsync: this, duration: AppAnimations.slower);
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.overshoot),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    _confettiController.play();

    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/bookings/${widget.bookingId}');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;

        final courseTitle = data['course']?['title'] ??
            data['schedule']?['course_title'] ??
            'Kursus Pelatihan';
        final lpkName = data['course']?['lpk']?['name'] ??
            data['schedule']?['lpk_name'] ??
            'LPK Skilloka';

        final courseId = data['course_id']?.toString() ??
            data['course']?['id']?.toString() ??
            data['schedule']?['course_id']?.toString();

        final hasSubscription = data['service_type'] == 'subscription' ||
            data['include_subscription'] == true ||
            (data['subscription_fee'] != null &&
                (double.tryParse(data['subscription_fee'].toString()) ?? 0) > 0);

        setState(() {
          _courseTitle = courseTitle;
          _lpkName = lpkName;
          _bookingCode = data['code']?.toString() ?? widget.bookingId;
          _qrUrl = data['qr_code_url'] as String?;
          _courseId = courseId;
          _hasSubscription = hasSubscription;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Fetching Booking Details: $e");
      setState(() {
        _courseTitle = 'Kursus Pilihan Anda';
        _lpkName = 'LPK Mitra';
        _bookingCode = widget.bookingId;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ─── 1. KONTEN UTAMA SCROLLABLE ────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        // Animated Success Icon
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              color: AppColors.successContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 58,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Pembayaran Berhasil!',
                            style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Selamat! Pendaftaran & pembayaran pelatihan Anda telah dikonfirmasi.',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Kartu Fitur Berlangganan Aktif (PRD 2.2)
                        if (_hasSubscription)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryContainer.withValues(alpha: 0.8),
                                    AppColors.primaryLight.withValues(alpha: 0.15),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: AppShapes.cardRadius,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fitur Langganan Skilloka Aktif! 🚀',
                                          style: AppTypography.titleSmall.copyWith(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Akses penuh modul materi digital, silabus interaktif, dan presensi absensi online untuk kursus ini telah terbuka.',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textPrimary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // E-Ticket Card
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppShapes.cardRadius,
                              border: Border.all(color: AppColors.outline),
                              boxShadow: AppShapes.shadowMD,
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      // Header tiket
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryContainer,
                                              borderRadius: AppShapes.borderRadiusSM,
                                            ),
                                            child: const Icon(
                                              Icons.confirmation_number_outlined,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('E-TICKET RESMI', style: AppTypography.badge),
                                              Text(
                                                _bookingCode,
                                                style: AppTypography.titleSmall.copyWith(
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.successContainer,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'LUNAS',
                                              style: AppTypography.badge.copyWith(color: AppColors.success),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 16),

                                      // Info detail
                                      _buildInfoRow('Kursus', _courseTitle),
                                      _buildInfoRow('LPK Mitra', _lpkName),
                                      _buildInfoRow(
                                        'Paket Layanan',
                                        _hasSubscription
                                            ? 'Booking + Langganan Premium'
                                            : 'Booking Reguler',
                                      ),
                                      _buildInfoRow('Status', 'Dikonfirmasi (Lunas via Midtrans)'),

                                      const SizedBox(height: 18),

                                      // QR Code
                                      if (_qrUrl != null && _qrUrl!.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: AppShapes.borderRadiusSM,
                                          child: Image.network(
                                            _qrUrl!,
                                            width: 130,
                                            height: 130,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => _buildQrFallback(),
                                          ),
                                        )
                                      else
                                        _buildQrFallback(),

                                      const SizedBox(height: 8),
                                      Text(
                                        'Tunjukkan QR Code ini kepada staf LPK saat hadir',
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ─── 2. TOMBOL AKSI BAWAH (STICKY ACTION BAR) ─────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(top: BorderSide(color: AppColors.outline.withValues(alpha: 0.6))),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Akses Fitur Berlangganan jika ada subscription
                      if (_hasSubscription && _courseId != null && _courseId!.isNotEmpty) ...[
                        AnimatedPrimaryButton(
                          text: 'Mulai Belajar & Akses Materi',
                          icon: Icons.play_circle_outline,
                          onPressed: () {
                            context.push(AppRouter.courseContentPath(_courseId!));
                          },
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go(AppRouter.myCourses),
                            icon: const Icon(Icons.school_outlined, size: 18),
                            label: const Text('Buka Menu Kursus Saya'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ] else ...[
                        AnimatedPrimaryButton(
                          text: 'Lihat Pesanan Saya',
                          onPressed: () => context.go(AppRouter.bookings),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go(AppRouter.myCourses),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Ke Kursus Saya'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go(AppRouter.home),
                        child: const Text('Kembali ke Beranda'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confetti celebratory animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.success,
                Color(0xFF3B82F6),
                Color(0xFFF59E0B),
              ],
              numberOfParticles: 25,
              gravity: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildQrFallback() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.borderRadiusSM,
      ),
      child: const Icon(Icons.qr_code, size: 60, color: AppColors.textTertiary),
    );
  }
}
