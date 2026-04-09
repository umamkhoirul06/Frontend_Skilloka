/// Booking Screen with course summary, batch selection, and form
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/widgets/atoms/input_field.dart';
import '../../../../core/widgets/molecules/course_card.dart';

class BookingScreen extends StatefulWidget {
  final String courseId;

  const BookingScreen({super.key, required this.courseId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedBatchIndex = 0;
  bool _agreedToTerms = false;
  final _nameController = TextEditingController(text: 'Pengguna');
  final _phoneController = TextEditingController(text: '081234567890');
  final _emailController = TextEditingController(text: 'user@example.com');

  final List<Map<String, dynamic>> _batches = [
    {'date': '15 Feb 2025', 'slots': 8, 'time': '08:00 - 12:00'},
    {'date': '1 Mar 2025', 'slots': 12, 'time': '13:00 - 17:00'},
    {'date': '15 Mar 2025', 'slots': 15, 'time': '08:00 - 12:00'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pendaftaran Kursus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppShapes.borderRadiusMD,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppShapes.borderRadiusSM,
                    child: Image.network(
                      'https://picsum.photos/100/100?random=1',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kursus Las Listrik untuk Pemula',
                          style: AppTypography.titleSmall,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LPK Mitra Kerja',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RollingPrice(price: 1500000),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Batch Selection
            Text('Pilih Jadwal', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            ...List.generate(_batches.length, (index) {
              final batch = _batches[index];
              final isSelected = _selectedBatchIndex == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedBatchIndex = index),
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
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                batch['date'],
                                style: AppTypography.labelLarge,
                              ),
                              Text(
                                batch['time'],
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successContainer,
                            borderRadius: AppShapes.chipRadius,
                          ),
                          child: Text(
                            '${batch['slots']} slot',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Personal Data
            Text('Data Pribadi', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            AppInputField(
              label: 'Nama Lengkap',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            AppInputField(
              label: 'Nomor Telepon',
              controller: _phoneController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppInputField(
              label: 'Email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 24),

            // Terms
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() => _agreedToTerms = value ?? false);
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text.rich(
                      TextSpan(
                        text: 'Saya menyetujui ',
                        style: AppTypography.bodySmall,
                        children: [
                          TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const TextSpan(text: ' dan '),
                          TextSpan(
                            text: 'Kebijakan Privasi',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Price Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppShapes.borderRadiusMD,
              ),
              child: Column(
                children: [
                  _buildPriceRow('Biaya Kursus', 'Rp 1.500.000'),
                  const SizedBox(height: 8),
                  _buildPriceRow('Biaya Admin', 'Rp 5.000'),
                  const Divider(height: 24),
                  _buildPriceRow('Total', 'Rp 1.505.000', isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Continue Button
            AnimatedPrimaryButton(
              text: 'Lanjut ke Pembayaran',
              isEnabled: _agreedToTerms,
              onPressed: () {
                context.push('${AppRouter.payment}${widget.courseId}');
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.labelLarge
              : AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
        Text(
          price,
          style: isTotal
              ? AppTypography.titleMedium.copyWith(color: AppColors.primary)
              : AppTypography.labelMedium,
        ),
      ],
    );
  }
}
