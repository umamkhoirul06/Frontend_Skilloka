/// Payment Screen with method selection and countdown
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';

class PaymentScreen extends StatefulWidget {
  final String courseId;

  const PaymentScreen({super.key, required this.courseId});

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
      'type': 'va',
    },
    {
      'name': 'Mandiri Virtual Account',
      'icon': Icons.account_balance,
      'type': 'va',
    },
    {'name': 'GoPay', 'icon': Icons.qr_code, 'type': 'ewallet'},
    {'name': 'OVO', 'icon': Icons.qr_code, 'type': 'ewallet'},
    {'name': 'DANA', 'icon': Icons.qr_code, 'type': 'ewallet'},
  ];

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

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      context.push('${AppRouter.bookingSuccess}${widget.courseId}');
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
                Text(
                  'Selesaikan pembayaran dalam',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: AppShapes.chipRadius,
                  ),
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
                      borderRadius: AppShapes.borderRadiusMD,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Pesanan',
                          style: AppTypography.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        _buildOrderRow('Kursus Las Listrik untuk Pemula'),
                        _buildOrderRow('Jadwal: 15 Feb 2025, 08:00 - 12:00'),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: AppTypography.labelLarge,
                            ),
                            Text(
                              'Rp 1.505.000',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Methods
                  Text(
                    'Pilih Metode Pembayaran',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Virtual Account Section
                  Text(
                    'Transfer Bank',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._paymentMethods
                      .asMap()
                      .entries
                      .where((e) => e.value['type'] == 'va')
                      .map(
                        (entry) =>
                            _buildPaymentMethodTile(entry.key, entry.value),
                      ),

                  const SizedBox(height: 16),

                  // E-Wallet Section
                  Text(
                    'E-Wallet',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._paymentMethods
                      .asMap()
                      .entries
                      .where((e) => e.value['type'] == 'ewallet')
                      .map(
                        (entry) =>
                            _buildPaymentMethodTile(entry.key, entry.value),
                      ),

                  // Payment Instructions (if method selected)
                  if (_selectedMethodIndex != null) ...[
                    const SizedBox(height: 24),
                    _buildPaymentInstructions(),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Pay Button
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
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
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
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
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                method['icon'],
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(method['name'], style: AppTypography.labelLarge),
              const Spacer(),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    final vaNumber = '8806 0812 3456 7890';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoContainer,
        borderRadius: AppShapes.borderRadiusMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Instruksi Pembayaran', style: AppTypography.titleSmall),
          const SizedBox(height: 12),
          Text(
            'Transfer ke Virtual Account berikut:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppShapes.borderRadiusSM,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    vaNumber,
                    style: AppTypography.titleMedium.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: vaNumber.replaceAll(' ', '')),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nomor VA disalin')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '1. Buka aplikasi mobile banking Anda\n'
            '2. Pilih menu Transfer > Virtual Account\n'
            '3. Masukkan nomor VA di atas\n'
            '4. Konfirmasi pembayaran',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
