import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final String courseId;
  final String? bookingId; // ✅ FIX: Tambah bookingId (dari BookingScreen)
  final String? amount;

  const PaymentScreen({
    super.key,
    required this.courseId,
    this.bookingId, // ✅ FIX: Terima bookingId
    this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int? _selectedMethodIndex;
  Duration _countdown = const Duration(hours: 24);
  Timer? _timer;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'BCA Virtual Account',
      'icon': Icons.account_balance,
      'type': 'va'
    },
    {
      'name': 'Mandiri Virtual Account',
      'icon': Icons.account_balance,
      'type': 'va'
    },
    {'name': 'GoPay', 'icon': Icons.qr_code, 'type': 'ewallet'},
    {'name': 'OVO', 'icon': Icons.qr_code, 'type': 'ewallet'},
    {'name': 'DANA', 'icon': Icons.qr_code, 'type': 'ewallet'},
  ];

  // ✅ FIX: Pembersih courseId kalau masih ada artefak ':courseId'
  String get _safeCourseId {
    return widget.courseId.replaceAll(':courseId', '').replaceAll(':', '');
  }

  // ✅ FIX: Getter bookingId yang bersih
  String? get _safeBookingId {
    final id = widget.bookingId;
    if (id == null || id.isEmpty) return null;
    return id.replaceAll(':', '');
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown.inSeconds > 0) {
          _countdown = _countdown - const Duration(seconds: 1);
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatCountdown() {
    final hours = _countdown.inHours.toString().padLeft(2, '0');
    final minutes = (_countdown.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_countdown.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _processPayment() async {
    if (_selectedMethodIndex == null) return;
    setState(() => _isProcessing = true);

    try {
      final apiClient = sl<ApiClient>();

      // Membersihkan format harga (menghapus titik)
      final String rawAmount = widget.amount ?? '1505000';
      final double amountValue =
          double.tryParse(rawAmount.replaceAll('.', '')) ?? 0;

      // ✅ FIX: Nembak API Create Transaction, sertakan bookingId kalau ada
      final response = await apiClient.post(
        '/payment/create-transaction',
        data: {
          'course_id': _safeCourseId,
          if (_safeBookingId != null) 'booking_id': _safeBookingId,
          'amount': amountValue,
          'payment_method': _paymentMethods[_selectedMethodIndex!]['name'],
        },
      );

      final snapToken = response.data['data']?['snap_token'];

      // ✅ FIX: Ambil bookingId dari response API (prioritas utama),
      //         fallback ke widget.bookingId yang diteruskan dari BookingScreen
      final String? bookingIdFromResponse =
          response.data['data']?['booking_id']?.toString() ??
              response.data['data']?['id']?.toString();

      final String finalBookingId =
          bookingIdFromResponse ?? _safeBookingId ?? _safeCourseId;

      if (snapToken != null) {
        final url = Uri.parse(
            'https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          if (mounted) {
            // ✅ FIX: Pakai bookingSuccessPath(bookingId), BUKAN string concatenation
            context.push(AppRouter.bookingSuccessPath(finalBookingId));
          }
        }
      } else {
        throw Exception('Snap Token tidak ditemukan di response API');
      }
    } catch (e) {
      debugPrint("Error Payment: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pembayaran. Coba lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Column(
        children: [
          // Countdown Timer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.warningContainer,
            child: Row(
              children: [
                const Icon(Icons.timer, color: AppColors.warning),
                const SizedBox(width: 12),
                Text('Selesaikan pembayaran dalam',
                    style: AppTypography.bodyMedium),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: AppShapes.chipRadius),
                  child: Text(
                    _formatCountdown(),
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppShapes.borderRadiusMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ringkasan Pesanan',
                            style: AppTypography.titleSmall),
                        const SizedBox(height: 12),
                        _buildOrderRow('Kursus Terpilih'),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Pembayaran',
                                style: AppTypography.labelLarge),
                            Text(
                              'Rp ${widget.amount ?? '1.505.000'}',
                              style: AppTypography.titleMedium
                                  .copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('Pilih Metode Pembayaran',
                      style: AppTypography.titleMedium),
                  const SizedBox(height: 12),

                  // Transfer Bank
                  Text('Transfer Bank',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ..._paymentMethods
                      .asMap()
                      .entries
                      .where((e) => e.value['type'] == 'va')
                      .map((e) => _buildPaymentMethodTile(e.key, e.value)),

                  const SizedBox(height: 16),

                  // E-Wallet
                  Text('E-Wallet',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ..._paymentMethods
                      .asMap()
                      .entries
                      .where((e) => e.value['type'] == 'ewallet')
                      .map((e) => _buildPaymentMethodTile(e.key, e.value)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Pay Button
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ],
            ),
            child: AnimatedPrimaryButton(
              text: 'Bayar Sekarang',
              isLoading: _isProcessing,
              isEnabled: _selectedMethodIndex != null,
              onPressed: _processPayment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Text(text,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(int index, Map<String, dynamic> method) {
    final isSelected = _selectedMethodIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedMethodIndex = index),
        borderRadius: AppShapes.borderRadiusMD,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.surfaceVariant,
            borderRadius: AppShapes.borderRadiusMD,
            border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2),
          ),
          child: Row(
            children: [
              Icon(method['icon'],
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(method['name'], style: AppTypography.labelLarge),
              const Spacer(),
              Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color:
                      isSelected ? AppColors.primary : AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
