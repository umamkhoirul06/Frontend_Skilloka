/// Course Detail Screen with image gallery, syllabus, and booking CTA
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/widgets/molecules/course_card.dart';
import '../../../../core/widgets/molecules/review_card.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  // Mock data
  final List<String> _images = [
    'https://picsum.photos/800/500?random=1',
    'https://picsum.photos/800/500?random=2',
    'https://picsum.photos/800/500?random=3',
  ];

  final List<Map<String, dynamic>> _syllabus = [
    {
      'title': 'Modul 1: Pengenalan',
      'duration': '2 Jam',
      'items': ['Pengantar materi', 'Peralatan dasar', 'Keselamatan kerja'],
    },
    {
      'title': 'Modul 2: Praktik Dasar',
      'duration': '8 Jam',
      'items': ['Teknik dasar', 'Latihan terbimbing', 'Evaluasi awal'],
    },
    {
      'title': 'Modul 3: Praktik Lanjutan',
      'duration': '16 Jam',
      'items': ['Teknik lanjutan', 'Proyek mandiri', 'Ujian akhir'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image Gallery App Bar
          SliverAppBar(
            expandedHeight: 280,
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
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? AppColors.error : Colors.white,
                  ),
                ),
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white),
                ),
                onPressed: () {
                  // TODO: Share course
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image Gallery
                  PageView.builder(
                    itemCount: _images.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: '${AppAnimations.heroTagCourse}${widget.courseId}',
                        child: Image.network(
                          _images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
                  // Page Indicator
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_images.length, (index) {
                        return AnimatedContainer(
                          duration: AppAnimations.fast,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentImageIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
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
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.categoryLas.withValues(alpha: 0.15),
                      borderRadius: AppShapes.chipRadius,
                    ),
                    child: Text(
                      'Las',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.categoryLas,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    'Kursus Las Listrik untuk Pemula',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: 8),

                  // LPK Info
                  GestureDetector(
                    onTap: () => context.push('${AppRouter.lpkDetail}lpk_1'),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppShapes.borderRadiusSM,
                          ),
                          child: const Icon(
                            Icons.business,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LPK Mitra Kerja',
                                style: AppTypography.labelMedium,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Terverifikasi',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      _buildStat(Icons.star, '4.8', '(128 ulasan)'),
                      const SizedBox(width: 24),
                      _buildStat(Icons.location_on_outlined, '2.5 km', null),
                      const SizedBox(width: 24),
                      _buildStat(Icons.schedule, '26 Jam', null),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Description
                  Text('Deskripsi', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Kursus ini dirancang untuk pemula yang ingin mempelajari teknik '
                    'pengelasan listrik dari dasar hingga mahir. Anda akan belajar '
                    'berbagai teknik pengelasan, keselamatan kerja, dan praktik langsung '
                    'dengan peralatan standar industri.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Syllabus
                  Text('Materi Kursus', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  ..._syllabus.asMap().entries.map((entry) {
                    return _SyllabusAccordion(
                      index: entry.key + 1,
                      title: entry.value['title'],
                      duration: entry.value['duration'],
                      items: List<String>.from(entry.value['items']),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Reviews Section
                  Row(
                    children: [
                      Text('Ulasan Peserta', style: AppTypography.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // TODO: See all reviews
                        },
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ReviewCard(
                    reviewerName: 'Ahmad Fauzi',
                    reviewText:
                        'Kursus yang sangat bermanfaat! Instruktur sangat sabar dan '
                        'menjelaskan dengan detail. Setelah selesai kursus, saya langsung '
                        'bisa bekerja di bengkel las.',
                    rating: 5,
                    courseName: 'Las Listrik Pemula',
                    completedAt: DateTime(2024, 8, 15),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildStat(IconData icon, String value, String? label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(value, style: AppTypography.labelMedium),
        if (label != null) ...[
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomSheet() {
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
          // Price
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biaya Kursus',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                RollingPrice(price: 1500000),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Book Button
          Expanded(
            child: AnimatedPrimaryButton(
              text: 'Daftar Sekarang',
              onPressed: () {
                context.push('${AppRouter.booking}${widget.courseId}');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SyllabusAccordion extends StatefulWidget {
  final int index;
  final String title;
  final String duration;
  final List<String> items;

  const _SyllabusAccordion({
    required this.index,
    required this.title,
    required this.duration,
    required this.items,
  });

  @override
  State<_SyllabusAccordion> createState() => _SyllabusAccordionState();
}

class _SyllabusAccordionState extends State<_SyllabusAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.borderRadiusMD,
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: AppShapes.borderRadiusMD,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTypography.labelMedium),
                        Text(
                          widget.duration,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: AppAnimations.fast,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            duration: AppAnimations.fast,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(60, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
