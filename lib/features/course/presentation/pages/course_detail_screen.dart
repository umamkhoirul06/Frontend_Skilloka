/// Course Detail Screen with image gallery, syllabus, and booking CTA
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/widgets/molecules/course_card.dart';
import '../../../../core/widgets/atoms/skilloka_loader.dart';
import '../../../../core/services/api_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  final _api = ApiService();

  Map<String, dynamic>? courseData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetail();
  }

  Future<void> _fetchCourseDetail() async {
    try {
      // ✅ FIX: Gunakan ApiService.getCourseDetail() — environment-aware, auth token otomatis
      final result = await _api.getCourseDetail(widget.courseId);

      if (!mounted) return;

      if (result['success'] == true) {
        final raw = result['data'];
        // Tangani berbagai format response Laravel
        final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
        setState(() {
          courseData = Map<String, dynamic>.from(data as Map);
          isLoading = false;
        });
      } else {
        debugPrint('Course detail error: ${result['message']}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching course: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  static final List<Map<String, dynamic>> _defaultSyllabus = [
    {
      'title': 'Modul 1: Pengenalan & K3',
      'duration': '2 Jam',
      'items': [
        'Pengantar materi kejuruan & keselamatan kerja (K3)',
        'Pengenalan peralatan dan standar operasional bengkel/lab',
      ],
    },
    {
      'title': 'Modul 2: Teori & Praktik Dasar',
      'duration': '8 Jam',
      'items': [
        'Teknik dan prosedur dasar kejuruan',
        'Latihan terbimbing instruktur',
        'Praktik penggunaan instrumen & bahan pelatihan',
      ],
    },
    {
      'title': 'Modul 3: Praktik Lanjutan & Proyek',
      'duration': '12 Jam',
      'items': [
        'Penerapan teknik lanjutan standar industri',
        'Studi kasus dan penyelesaian proyek kerja nyata',
      ],
    },
    {
      'title': 'Modul 4: Uji Kompetensi & Sertifikasi',
      'duration': '4 Jam',
      'items': [
        'Evaluasi hasil kerja praktik',
        'Persiapan uji kompetensi kejuruan',
        'Penerbitan sertifikat kelulusan LPK',
      ],
    },
  ];

  List<Map<String, dynamic>> get _syllabus {
    final rawSyllabus = courseData?['syllabus']?.toString();
    final rawContents = courseData?['contents'];

    // 1. Prioritas 1: Jika admin LPK mengunggah materi digital / contents
    if (rawContents is List && rawContents.isNotEmpty) {
      return rawContents.asMap().entries.map((entry) {
        final item = Map<String, dynamic>.from(entry.value as Map);
        final title = item['title']?.toString() ?? 'Materi ${entry.key + 1}';
        final type = (item['type']?.toString() ?? 'MODUL').toUpperCase();
        final dur = type == 'VIDEO' ? 'Video Pembelajaran' : 'Modul Digital';
        return {
          'title': title,
          'duration': dur,
          'items': [
            item['description']?.toString() ??
                'Materi pokok bahasan resmi dari instruktur LPK.'
          ],
        };
      }).toList();
    }

    // 2. Prioritas 2: Jika admin LPK mengisi teks Silabus Materi / Pokok Pembahasan
    if (rawSyllabus != null && rawSyllabus.trim().isNotEmpty) {
      final parsed = _parseSyllabusText(rawSyllabus.trim());
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    // 3. Fallback: Gunakan template default jika data kosong / belum diisi admin LPK
    return _defaultSyllabus;
  }

  List<Map<String, dynamic>> _parseSyllabusText(String text) {
    final rawLines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (rawLines.isEmpty) return [];

    final List<Map<String, dynamic>> modules = [];
    Map<String, dynamic>? currentModule;
    List<String> currentItems = [];

    for (final line in rawLines) {
      final isBullet = RegExp(r'^[\-\*•–—]\s*').hasMatch(line);
      final isNumbered = RegExp(
        r'^(\d+[\.\)]|modul\s*\d+|bab\s*\d+|sesi\s*\d+|pertemuan\s*\d+|topik\s*\d+)',
        caseSensitive: false,
      ).hasMatch(line);

      if (isBullet && currentModule != null) {
        // Sub-item pokok bahasan di bawah modul
        final cleanItem = line.replaceFirst(RegExp(r'^[\-\*•–—]\s*'), '').trim();
        if (cleanItem.isNotEmpty) {
          currentItems.add(cleanItem);
        }
      } else if (isNumbered || currentModule == null) {
        if (currentModule != null) {
          currentModule['items'] = currentItems.isNotEmpty
              ? List<String>.from(currentItems)
              : ['Pokok pembahasan & materi kejuruan sesuai kurikulum'];
          modules.add(currentModule);
          currentItems = [];
        }

        String cleanLine = line.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '').trim();
        String title = cleanLine;
        String? detailDesc;

        if (cleanLine.contains(':')) {
          final parts = cleanLine.split(':');
          title = parts[0].trim();
          detailDesc = parts.sublist(1).join(':').trim();
        } else if (cleanLine.contains(' - ')) {
          final parts = cleanLine.split(' - ');
          title = parts[0].trim();
          detailDesc = parts.sublist(1).join(' - ').trim();
        }

        if (detailDesc != null && detailDesc.isNotEmpty) {
          currentItems.add(detailDesc);
        }

        currentModule = {
          'title': title.isNotEmpty ? title : 'Pokok Pembahasan',
          'duration': 'Pokok Pembahasan',
          'items': <String>[],
        };
      } else {
        currentItems.add(line);
      }
    }

    if (currentModule != null) {
      currentModule['items'] = currentItems.isNotEmpty
          ? List<String>.from(currentItems)
          : ['Pokok pembahasan & materi kejuruan sesuai kurikulum'];
      modules.add(currentModule);
    }

    return modules;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SkillokaLoading.page(
        message: 'Memuat kurikulum & silabus pelatihan...',
      );
    }

    if (courseData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kursus')),
        body: const Center(child: Text('Gagal memuat data kursus.')),
      );
    }

    final String title = courseData!['title'] ?? 'Tanpa Judul';
    final String description =
        courseData!['description'] ?? 'Belum ada deskripsi untuk kursus ini.';
    final int price = (courseData!['price'] ?? 0).toInt();
    final String categoryName = courseData!['category']?['name'] ?? 'Umum';
    final String duration = '${courseData!['duration_hours'] ?? 0} Jam';
    final String lpkName = courseData!['lpk']?['name'] ?? 'LPK Tidak Diketahui';
    final String? lpkLogo = courseData!['lpk']?['logo'] != null
        ? ApiService.toFullUrl(courseData!['lpk']!['logo'].toString())
        : (courseData!['lpk']?['logo_url'] != null
            ? ApiService.toFullUrl(courseData!['lpk']!['logo_url'].toString())
            : null);

    final List<String> images = [];
    final rawImagesData = courseData!['images'];
    if (rawImagesData is List) {
      for (final e in rawImagesData) {
        if (e != null && e.toString().trim().isNotEmpty) {
          final full = ApiService.toFullUrl(e.toString().trim());
          if (full.isNotEmpty) images.add(full);
        }
      }
    } else if (rawImagesData is String && rawImagesData.trim().isNotEmpty) {
      final s = rawImagesData.trim();
      final full = ApiService.toFullUrl(s);
      if (full.isNotEmpty) images.add(full);
    }

    if (images.isEmpty) {
      final single = courseData!['image_url'] ??
          courseData!['image'] ??
          courseData!['thumbnail'] ??
          courseData!['cover_image'];
      if (single != null && single.toString().trim().isNotEmpty) {
        final full = ApiService.toFullUrl(single.toString().trim());
        if (full.isNotEmpty) images.add(full);
      }
    }

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
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<bool>(_isFavorite),
                    tween: Tween<double>(begin: 0.7, end: 1.0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? AppColors.error : Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final result = await _api.toggleFavorite(
                    courseId: widget.courseId,
                  );

                  if (result['success']) {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  }
                },
              ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
                images.isNotEmpty
                    ? PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Hero(
                            tag: '${AppAnimations.heroTagCourse}${widget.courseId}',
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.15),
                                      AppColors.secondary.withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.school_rounded,
                                          size: 64, color: AppColors.primary),
                                      const SizedBox(height: 8),
                                      Text(
                                        title,
                                        style: AppTypography.titleMedium.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.secondary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.school_rounded,
                                  size: 64, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: AppShapes.chipRadius,
                    ),
                    child: Text(
                      categoryName,
                      style: AppTypography.badge
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(title, style: AppTypography.headlineSmall),
                  const SizedBox(height: 8),

                  // LPK Info
                  GestureDetector(
                    onTap: () {
                      final lpk = courseData!['lpk'];
                      if (lpk != null && lpk['id'] != null) {
                        // ✅ FIX: Pakai lpkDetailPath() helper, BUKAN string concatenation
                        context.push(
                            AppRouter.lpkDetailPath(lpk['id'].toString()));
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppShapes.borderRadiusSM,
                          ),
                          child: (lpkLogo != null && lpkLogo.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: AppShapes.borderRadiusSM,
                                  child: CachedNetworkImage(
                                    imageUrl: lpkLogo,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.surfaceVariant,
                                    ),
                                    errorWidget: (c, e, s) =>
                                        const Icon(Icons.business, size: 18),
                                  ),
                                )
                              : const Icon(Icons.business,
                                  size: 18, color: AppColors.textTertiary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lpkName, style: AppTypography.labelMedium),
                              Row(
                                children: [
                                  const Icon(Icons.verified,
                                      size: 12, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Terverifikasi',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: AppColors.success),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      _buildStat(Icons.star, '4.8', '(0 rating)'),
                      const SizedBox(width: 24),
                      _buildStat(Icons.schedule, duration, null),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Description
                  Text('Deskripsi', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
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

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomSheet(price),
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
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary)),
        ],
      ],
    );
  }

  Widget _buildBottomSheet(int price) {
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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biaya Kursus',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                RollingPrice(price: price),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedPrimaryButton(
              text: 'Daftar Sekarang',
              onPressed: () {
                // ✅ FIX: Pakai bookingPath() helper, BUKAN string concatenation
                context.push(AppRouter.bookingPath(widget.courseId));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: AppAnimations.medium,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _isExpanded
            ? (isDark
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.04))
            : Theme.of(context).colorScheme.surface,
        borderRadius: AppShapes.borderRadiusMD,
        border: Border.all(
          color: _isExpanded
              ? AppColors.primary.withValues(alpha: 0.35)
              : (isDark ? AppColors.outlineDark : AppColors.outline),
          width: _isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: AppShapes.borderRadiusMD,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppAnimations.medium,
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _isExpanded
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: AppTypography.labelLarge.copyWith(
                          color: _isExpanded ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: _isExpanded ? FontWeight.w700 : FontWeight.w600,
                            color: _isExpanded ? AppColors.primary : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              widget.duration,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            if (widget.items.isNotEmpty) ...[
                              Container(
                                width: 3,
                                height: 3,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              Text(
                                '${widget.items.length} materi',
                                style: AppTypography.bodySmall.copyWith(
                                  color: _isExpanded ? AppColors.primary : AppColors.textTertiary,
                                  fontWeight: _isExpanded ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: AppAnimations.medium,
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _isExpanded ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: AppAnimations.medium,
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(62, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
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
