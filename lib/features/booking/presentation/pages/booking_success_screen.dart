import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';

class BookingSuccessScreen extends StatefulWidget {
  // ✅ FIX: Ganti courseId → bookingId
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

  bool _isLoading = true;
  String _courseTitle = 'Memuat...';
  String _lpkName = 'Memuat...';
  String _bookingCode = '-';
  String? _qrUrl;

  @override
  void initState() {
    super.initState();
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

    // ✅ FIX: Fetch dari /bookings/:id, bukan /courses/:id
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/bookings/${widget.bookingId}');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;

        // Support berbagai struktur JSON dari backend
        final courseTitle = data['course']?['title'] ??
            data['schedule']?['course_title'] ??
            'Kursus';
        final lpkName = data['course']?['lpk']?['name'] ??
            data['schedule']?['lpk_name'] ??
            'LPK Skilloka';

        setState(() {
          _courseTitle = courseTitle;
          _lpkName = lpkName;
          _bookingCode = data['code']?.toString() ?? widget.bookingId;
          _qrUrl = data['qr_code_url'] as String?;
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context)
          .scaffoldBackgroundColor, // Pastikan background konsisten
      body: SafeArea(
        child: Column(
          children: [
            // ─── 1. KONTEN UTAMA (BISA DI-SCROLL JIKA LAYAR KECIL) ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20), // Pengganti top Spacer()

                    // Success Icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: AppColors.successContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 64,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                        style: AppTypography.bodyLarge
                            .copyWith(color: AppColors.textSecondary),
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
                                          borderRadius:
                                              AppShapes.borderRadiusSM,
                                        ),
                                        child: const Icon(
                                          Icons.confirmation_number,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('E-TICKET',
                                              style: AppTypography.badge),
                                          Text(_bookingCode,
                                              style: AppTypography.titleSmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),

                                  // Info detail
                                  _buildInfoRow('Kursus', _courseTitle),
                                  _buildInfoRow('LPK', _lpkName),
                                  _buildInfoRow(
                                      'Status', 'Dikonfirmasi (Lunas)'),

                                  const SizedBox(height: 20),

                                  // QR Code dari backend
                                  if (_qrUrl != null && _qrUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: AppShapes.borderRadiusSM,
                                      child: Image.network(
                                        _qrUrl!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            _buildQrFallback(),
                                      ),
                                    )
                                  else
                                    _buildQrFallback(),

                                  const SizedBox(height: 8),
                                  Text(
                                    'Tunjukkan QR code ini saat hadir',
                                    style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(
                        height: 40), // Jarak lega ke bagian bawah scroll
                  ],
                ),
              ),
            ),

            // ─── 2. TOMBOL BAWAH (DIPAKU AGAR TIDAK HILANG) ───
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5), // Efek bayangan halus ke atas
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
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
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.borderRadiusSM,
      ),
      child: const Icon(Icons.qr_code, size: 60, color: AppColors.textTertiary),
    );
  }
}
