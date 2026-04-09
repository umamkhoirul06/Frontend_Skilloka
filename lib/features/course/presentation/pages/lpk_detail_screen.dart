/// LPK Detail Screen with cover, map, facilities, and contact
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/widgets/molecules/course_card.dart';
import '../../../../core/widgets/molecules/review_card.dart';
import '../../../../core/navigation/app_router.dart';

class LPKDetailScreen extends StatelessWidget {
  final String lpkId;

  const LPKDetailScreen({super.key, required this.lpkId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Cover image with LPK info
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: '${AppAnimations.heroTagLPK}$lpkId',
                    child: Image.network(
                      'https://picsum.photos/800/400?random=100',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // LPK Info
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        // Logo
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppShapes.borderRadiusMD,
                          ),
                          child: const Icon(
                            Icons.business,
                            color: AppColors.textTertiary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name & Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'LPK Mitra Kerja',
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: AppShapes.chipRadius,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Terverifikasi Dinas',
                                      style: AppTypography.badge.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  Row(
                    children: [
                      _buildStat('4.8', 'Rating'),
                      const SizedBox(width: 24),
                      _buildStat('128', 'Ulasan'),
                      const SizedBox(width: 24),
                      _buildStat('500+', 'Alumni'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Address
                  Text('Alamat', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppShapes.borderRadiusMD,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Jl. Merdeka No. 123, Kec. Indramayu, '
                            'Kab. Indramayu, Jawa Barat 45211',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.directions),
                          color: AppColors.primary,
                          onPressed: () => _openMaps(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Facilities
                  Text('Fasilitas', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFacilityChip(Icons.local_parking, 'Parkir'),
                      _buildFacilityChip(Icons.ac_unit, 'AC'),
                      _buildFacilityChip(Icons.wifi, 'WiFi'),
                      _buildFacilityChip(Icons.restaurant, 'Kantin'),
                      _buildFacilityChip(Icons.wc, 'Toilet'),
                      _buildFacilityChip(Icons.mosque, 'Musholla'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Courses
                  Row(
                    children: [
                      Text('Kursus Tersedia', style: AppTypography.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 180,
                          child: CourseCard(
                            id: 'course_$index',
                            title: 'Kursus Las Listrik ${index + 1}',
                            lpkName: 'LPK Mitra Kerja',
                            imageUrl:
                                'https://picsum.photos/400/300?random=${index + 50}',
                            rating: 4.5,
                            reviewCount: 50,
                            distanceKm: 0,
                            price: 1500000,
                            category: 'Las',
                            onTap: () => context.push(
                              '${AppRouter.courseDetail}course_$index',
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reviews
                  Row(
                    children: [
                      Text('Ulasan', style: AppTypography.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ReviewCard(
                    reviewerName: 'Budi Santoso',
                    reviewText:
                        'LPK yang sangat profesional. Fasilitas lengkap dan instruktur '
                        'sangat berpengalaman. Saya berhasil mendapat pekerjaan setelah '
                        'lulus dari sini.',
                    rating: 5,
                    courseName: 'Las Listrik',
                    completedAt: DateTime(2024, 6, 20),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildContactSheet(context),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTypography.headlineSmall),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }

  Widget _buildContactSheet(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          // Phone button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _callPhone(),
              icon: const Icon(Icons.phone),
              label: const Text('Telepon'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // WhatsApp button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(),
              icon: const Icon(Icons.message),
              label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=-6.3279,108.3265',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _callPhone() async {
    final url = Uri.parse('tel:+6281234567890');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openWhatsApp() async {
    final url = Uri.parse(
      'https://wa.me/6281234567890?text=Halo,%20saya%20tertarik%20dengan%20kursus%20di%20LPK%20Anda',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
