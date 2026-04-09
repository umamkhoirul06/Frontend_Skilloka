/// Booking Success Screen with E-Ticket style confirmation
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';

class BookingSuccessScreen extends StatefulWidget {
  final String courseId;

  const BookingSuccessScreen({super.key, required this.courseId});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slower,
    );
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // FIX: Menggunakan CustomScrollView agar konten bisa di-scroll jika layar terlalu kecil
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody:
                  false, // Memastikan konten mengisi layar tapi tetap bisa scroll jika over
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Memberikan jarak atas yang fleksibel
                    const Spacer(),

                    // Success Animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 100, // Sedikit diperkecil untuk menghemat ruang
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 64, // Sedikit diperkecil
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Pembayaran Berhasil!',
                        style: AppTypography.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Selamat! Anda telah terdaftar di kursus ini',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

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
                        child: Column(
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: AppShapes.borderRadiusSM,
                                  ),
                                  child: const Icon(
                                    Icons.confirmation_number,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'E-TICKET',
                                      style: AppTypography.badge,
                                    ),
                                    Text(
                                      'SKL-2025-001234',
                                      style: AppTypography.titleSmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            // Course Info
                            _buildInfoRow('Kursus', 'Las Listrik untuk Pemula'),
                            _buildInfoRow('LPK', 'LPK Mitra Kerja'),
                            _buildInfoRow('Jadwal', '15 Feb 2025, 08:00'),
                            _buildInfoRow(
                              'Alamat',
                              'Jl. Merdeka No. 123, Indramayu',
                            ),
                            const SizedBox(height: 16),
                            // QR Code placeholder
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: AppShapes.borderRadiusSM,
                              ),
                              child: const Icon(
                                Icons.qr_code,
                                size: 60,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tunjukkan QR code ini saat hadir',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Jarak dinamis untuk mendorong tombol ke bawah
                    const SizedBox(height: 32),
                    const Spacer(),

                    // Actions
                    AnimatedPrimaryButton(
                      text: 'Lihat Detail Booking',
                      onPressed: () {
                        context.go(AppRouter.home);
                      },
                    ),
                    const SizedBox(height: 12),
                    GhostButton(
                      text: 'Kembali ke Beranda',
                      onPressed: () {
                        context.go(AppRouter.home);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: AppTypography.labelMedium)),
        ],
      ),
    );
  }
}
