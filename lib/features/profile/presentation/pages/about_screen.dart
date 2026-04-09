import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: Column(
                children: [
                  // App Icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppShapes.borderRadiusXL,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Skilloka',
                    style: AppTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi 1.0.0 (Build 1)',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: AppShapes.chipRadius,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Kompetensi Tanpa Batas',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About
                  _buildCard(
                    title: 'Tentang Skilloka',
                    child: Text(
                      'Skilloka adalah platform hyperlocal yang menghubungkan masyarakat '
                      'Kabupaten Indramayu dengan Lembaga Pelatihan Kerja (LPK) '
                      'terverifikasi di sekitar mereka.\n\n'
                      'Kami hadir untuk mempermudah akses terhadap pendidikan vokasi '
                      'berkualitas, membantu warga mendapatkan keterampilan kerja yang '
                      'diakui secara resmi oleh Dinas Ketenagakerjaan.',
                      style: AppTypography.bodyMedium.copyWith(height: 1.7),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Stats
                  _buildCard(
                    title: 'Pencapaian Kami',
                    child: Row(
                      children: [
                        _buildStat('50+', 'LPK Mitra'),
                        _buildStatDivider(),
                        _buildStat('200+', 'Kursus'),
                        _buildStatDivider(),
                        _buildStat('5.000+', 'Alumni'),
                        _buildStatDivider(),
                        _buildStat('4.8', 'Rating'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info
                  _buildCard(
                    title: 'Informasi Aplikasi',
                    child: Column(
                      children: [
                        _buildInfoRow('Versi Aplikasi', '1.0.0'),
                        _buildInfoRow('Build Number', '1'),
                        _buildInfoRow('Platform', 'Android & iOS'),
                        _buildInfoRow(
                          'Dikembangkan oleh',
                          'Tim Skilloka',
                        ),
                        _buildInfoRow(
                          'Kontak Developer',
                          'dev@skilloka.id',
                        ),
                        _buildInfoRow(
                          'Didukung oleh',
                          'Disnakertranskab Indramayu',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Legal
                  _buildCard(
                    title: 'Legal & Kebijakan',
                    child: Column(
                      children: [
                        _buildLinkRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Kebijakan Privasi',
                          onTap: () => _launchUrl(
                            'https://skilloka.id/privacy-policy',
                          ),
                        ),
                        const Divider(height: 1),
                        _buildLinkRow(
                          icon: Icons.gavel_outlined,
                          title: 'Syarat & Ketentuan',
                          onTap: () =>
                              _launchUrl('https://skilloka.id/terms'),
                        ),
                        const Divider(height: 1),
                        _buildLinkRow(
                          icon: Icons.cookie_outlined,
                          title: 'Kebijakan Cookie',
                          onTap: () =>
                              _launchUrl('https://skilloka.id/cookies'),
                        ),
                        const Divider(height: 1),
                        _buildLinkRow(
                          icon: Icons.code_outlined,
                          title: 'Open Source Licenses',
                          onTap: () => showLicensePage(
                            context: context,
                            applicationName: 'Skilloka',
                            applicationVersion: '1.0.0',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Social Media
                  _buildCard(
                    title: 'Ikuti Kami',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialButton(
                          icon: Icons.language,
                          label: 'Website',
                          color: AppColors.primary,
                          url: 'https://skilloka.id',
                        ),
                        _buildSocialButton(
                          icon: Icons.camera_alt_outlined,
                          label: 'Instagram',
                          color: const Color(0xFFE4405F),
                          url: 'https://instagram.com/skilloka_id',
                        ),
                        _buildSocialButton(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: const Color(0xFF1877F2),
                          url: 'https://facebook.com/skilloka',
                        ),
                        _buildSocialButton(
                          icon: Icons.play_circle_outline,
                          label: 'YouTube',
                          color: const Color(0xFFFF0000),
                          url: 'https://youtube.com/@skilloka',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '© 2025 Skilloka. All rights reserved.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Made with ❤️ in Indramayu',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppShapes.cardRadius,
        boxShadow: AppShapes.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleSmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.outline,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: AppTypography.bodyMedium),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
