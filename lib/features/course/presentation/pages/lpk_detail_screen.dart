import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/services/api_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _course;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _error;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetail();
  }

  Future<void> _fetchCourseDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _api.getCourseDetail(widget.courseId);
      if (!mounted) return;
      if (result['success']) {
        final data = result['data']['data'] ?? result['data'];
        setState(() {
          _course = data is Map<String, dynamic> ? data : null;
          _isLoading = false;
        });
      } else {
        setState(() { _error = result['message']; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _course == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error ?? 'Data tidak ditemukan', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchCourseDetail, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    // Ambil data dari API response
    final title = _course!['name'] ?? _course!['title'] ?? 'Kursus';
    final description = _course!['description'] ?? '';
    final category = _course!['category'] ?? _course!['category_name'] ?? '';
    final price = (_course!['price'] ?? 0).toDouble();
    final rating = (_course!['rating'] ?? 0).toDouble();
    final ratingCount = _course!['rating_count'] ?? 0;
    final duration = _course!['duration'] ?? '';
    final lpkName = _course!['lpk']?['name'] ?? _course!['lpk_name'] ?? '';
    final lpkId = _course!['lpk']?['id']?.toString() ?? _course!['lpk_id']?.toString() ?? '';
    final isVerified = _course!['lpk']?['is_verified'] ?? false;

    // Gambar — bisa array atau single string
    final List<String> images = [];
    if (_course!['images'] is List) {
      for (final img in _course!['images']) {
        final url = img is String ? img : (img['url'] ?? img['image_url'] ?? '');
        if (url.isNotEmpty) images.add(url);
      }
    } else if (_course!['image_url'] != null) {
      images.add(_course!['image_url']);
    } else if (_course!['image'] != null) {
      images.add(_course!['image']);
    }
    // Fallback kalau tidak ada gambar
    if (images.isEmpty) images.add('');

    // Syllabus / Materi
    final List<dynamic> syllabus = _course!['syllabus'] ?? _course!['modules'] ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image Gallery AppBar
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
                onPressed: () async {
                  setState(() => _isFavorite = !_isFavorite);
                  await _api.toggleFavorite(
                    itemId: widget.courseId,
                    itemType: 'course',
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: '${AppAnimations.heroTagCourse}${widget.courseId}',
                        child: images[index].isNotEmpty
                            ? Image.network(
                                images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.primaryLight,
                                  child: const Icon(Icons.school, size: 60, color: Colors.white),
                                ),
                              )
                            : Container(
                                color: AppColors.primaryLight,
                                child: const Icon(Icons.school, size: 60, color: Colors.white),
                              ),
                      );
                    },
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 16, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          return AnimatedContainer(
                            duration: AppAnimations.fast,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Kategori
                  if (category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: AppShapes.chipRadius,
                      ),
                      child: Text(category,
                          style: AppTypography.badge.copyWith(color: AppColors.primary)),
                    ),
                  const SizedBox(height: 12),

                  // Judul
                  Text(title, style: AppTypography.headlineSmall),
                  const SizedBox(height: 8),

                  // Info LPK
                  if (lpkName.isNotEmpty)
                    GestureDetector(
                      onTap: lpkId.isNotEmpty
                          ? () => context.push('/lpk/$lpkId')
                          : null,
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppShapes.borderRadiusSM,
                            ),
                            child: const Icon(Icons.business, size: 18, color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lpkName, style: AppTypography.labelMedium),
                                if (isVerified)
                                  Row(
                                    children: [
                                      const Icon(Icons.verified, size: 12, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Text('Terverifikasi',
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.success)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (lpkId.isNotEmpty)
                            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    children: [
                      _buildStat(Icons.star, rating.toStringAsFixed(1), '($ratingCount ulasan)'),
                      if (duration.isNotEmpty) ...[
                        const SizedBox(width: 24),
                        _buildStat(Icons.schedule, duration, null),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Deskripsi
                  if (description.isNotEmpty) ...[
                    Text('Deskripsi', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Text(description,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                  ],

                  // Silabus / Materi
                  if (syllabus.isNotEmpty) ...[
                    Text('Materi Kursus', style: AppTypography.titleMedium),
                    const SizedBox(height: 12),
                    ...syllabus.asMap().entries.map((entry) {
                      final item = entry.value;
                      final moduleTitle = item['title'] ?? item['name'] ?? 'Modul ${entry.key + 1}';
                      final moduleDuration = item['duration'] ?? '';
                      final moduleItems = List<String>.from(item['items'] ?? item['topics'] ?? []);
                      return _SyllabusAccordion(
                        index: entry.key + 1,
                        title: moduleTitle,
                        duration: moduleDuration,
                        items: moduleItems,
                      );
                    }),
                  ],

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomSheet(context, price),
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
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        ],
      ],
    );
  }

  Widget _buildBottomSheet(BuildContext context, double price) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Biaya Kursus',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                RollingPrice(price: price),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedPrimaryButton(
              text: 'Daftar Sekarang',
              onPressed: () => context.push('/booking/${widget.courseId}'),
            ),
          ),
        ],
      ),
    );
  }
}

// Accordion Silabus (tidak berubah)
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
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: AppShapes.borderRadiusMD,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${widget.index}',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTypography.labelMedium),
                        if (widget.duration.isNotEmpty)
                          Text(widget.duration,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: AppAnimations.fast,
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: AppAnimations.fast,
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: widget.items.isEmpty
                ? const SizedBox.shrink()
                : Padding(
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
                                width: 6, height: 6,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(item,
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
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