/// Profile Screen with user info, bookings, and settings
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Open settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppShapes.cardRadius,
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengguna',
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+62 812-3456-7890',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      // TODO: Edit profile
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Stats
            Row(
              children: [
                Expanded(child: _buildStatCard('2', 'Kursus Aktif')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('5', 'Sertifikat')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('3', 'Ulasan')),
              ],
            ),

            const SizedBox(height: 24),

            // My Bookings
            Row(
              children: [
                Text('Booking Saya', style: AppTypography.titleMedium),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('Lihat Semua')),
              ],
            ),
            const SizedBox(height: 12),
            _buildBookingCard(
              context,
              status: 'active',
              courseName: 'Las Listrik untuk Pemula',
              lpkName: 'LPK Mitra Kerja',
              date: '15 Feb 2025',
            ),
            const SizedBox(height: 12),
            _buildBookingCard(
              context,
              status: 'completed',
              courseName: 'Komputer Dasar',
              lpkName: 'LPK Digital Nusantara',
              date: '10 Jan 2025',
            ),

            const SizedBox(height: 24),

            // Menu Items
            Text('Menu', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.workspace_premium_outlined,
              title: 'Sertifikat Saya',
              subtitle: 'Lihat dan unduh sertifikat',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.favorite_outline,
              title: 'Favorit',
              subtitle: 'Kursus & LPK yang disimpan',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              subtitle: 'Pengaturan notifikasi',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: 'Bantuan',
              subtitle: 'FAQ dan hubungi kami',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.info_outline,
              title: 'Tentang Aplikasi',
              subtitle: 'Versi 1.0.0',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Keluar',
              subtitle: 'Keluar dari akun',
              isDestructive: true,
              onTap: () {
                context.go(AppRouter.login);
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.borderRadiusMD,
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineSmall),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context, {
    required String status,
    required String courseName,
    required String lpkName,
    required String date,
  }) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.borderRadiusMD,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryContainer
                  : AppColors.successContainer,
              borderRadius: AppShapes.borderRadiusSM,
            ),
            child: Icon(
              isActive ? Icons.school : Icons.check_circle,
              color: isActive ? AppColors.primary : AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courseName, style: AppTypography.labelMedium),
                Text(
                  lpkName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.success,
                    borderRadius: AppShapes.chipRadius,
                  ),
                  child: Text(
                    isActive ? 'Aktif - $date' : 'Selesai - $date',
                    style: AppTypography.badge.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppShapes.borderRadiusMD,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.errorContainer
                    : AppColors.surfaceVariant,
                borderRadius: AppShapes.borderRadiusSM,
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDestructive ? AppColors.error : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isDestructive)
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
