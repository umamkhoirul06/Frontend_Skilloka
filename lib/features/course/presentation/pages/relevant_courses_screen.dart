import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/course_relevance_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';
import '../../../home/data/repositories/home_repository.dart';
import '../../data/models/course_model.dart';

/// Screen displaying algorithmically curated courses based on user's onboarding profiling
/// Addresses PRD 2.3, 8.3 & user prompt:
/// "SAAT KITA ISI SEMUA DATA DI AWAL MASUK NANTI LANGSUNG DI ARAHKAN DENGAN KURUSUS YANG RELEVAN"
class RelevantCoursesScreen extends StatefulWidget {
  final UserProfilePreference? preference;

  const RelevantCoursesScreen({
    super.key,
    this.preference,
  });

  @override
  State<RelevantCoursesScreen> createState() => _RelevantCoursesScreenState();
}

class _RelevantCoursesScreenState extends State<RelevantCoursesScreen> {
  final ApiService _api = ApiService();

  UserProfilePreference? _preference;
  List<ScoredCourse> _scoredCourses = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _preference = widget.preference;
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);

    // 1. Load preference if not provided
    _preference ??= await CourseRelevanceService.getPreference();

    // Default fallback if still null
    _preference ??= const UserProfilePreference(
      educationLevel: 'SMK',
      major: 'Teknik',
      careerGoal: 'Mempersiapkan kerja pertama',
      preferredLocation: 'Indramayu',
    );

    // 2. Load courses from API using HomeRepository (primary) or ApiService (fallback)
    try {
      List<CourseModel> loadedCourses = [];

      try {
        final homeRepo = HomeRepository(apiClient: sl<ApiClient>());
        loadedCourses = await homeRepo.getCourses(search: '');
        debugPrint('Loaded courses from HomeRepository: ${loadedCourses.length}');
      } catch (e) {
        debugPrint('HomeRepository getCourses error: $e');
      }

      // Robust fallback using ApiService if needed
      if (loadedCourses.isEmpty) {
        final result = await _api.getCourses();
        if (result['success'] == true) {
          final rawData = result['data'];
          List<dynamic> list = [];
          if (rawData is List) {
            list = rawData;
          } else if (rawData is Map) {
            final inner = rawData['data'];
            if (inner is List) {
              list = inner;
            } else if (inner is Map && inner['data'] is List) {
              list = inner['data'];
            } else if (rawData['items'] is List) {
              list = rawData['items'];
            }
          }

          loadedCourses = list
              .whereType<Map>()
              .map((item) =>
                  CourseModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          debugPrint('Loaded courses from ApiService fallback: ${loadedCourses.length}');
        }
      }

      // 3. Compute relevance algorithm
      if (mounted) {
        final scored = CourseRelevanceService.rankCourses(
          courses: loadedCourses,
          preference: _preference!,
        );

        setState(() {
          _scoredCourses = scored;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in RelevantCoursesScreen _initData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ScoredCourse> get _filteredList {
    if (_selectedFilter == 'Tinggi (80%+)') {
      return _scoredCourses.where((sc) => sc.score >= 80).toList();
    }
    if (_selectedFilter == 'Bersertifikat') {
      return _scoredCourses
          .where((sc) =>
              sc.course.facilities.any((f) => f.toLowerCase().contains('sertifikat')))
          .toList();
    }
    return _scoredCourses;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pref = _preference;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.home);
            }
          },
        ),
        title: Text(
          'Kurasi Kursus Untukmu',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRouter.home),
            child: Text(
              'Ke Beranda',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Menyelaraskan data algoritma...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _initData,
              color: AppColors.primary,
              child: CustomScrollView(
              slivers: [
                // 1. Profile Context Summary Header Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : AppColors.outline,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.successContainer,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.verifiedBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 13,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Profil Terverifikasi',
                                      style: AppTypography.badge.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => context.push(AppRouter.educationOnboarding),
                                child: Text(
                                  'Sesuaikan Minat',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pref != null && pref.major.isNotEmpty
                                ? 'Peluang Pelatihan untuk ${pref.major}'
                                : 'Rekomendasi Pelatihan Kejuruan',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Algoritma Skilloka menyortir kursus berdasarkan relevansi keahlian, akreditasi LPK, dan peluang industri kerja di Indramayu.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (pref != null) ...[
                                _buildDetailChip(
                                  Icons.school_outlined,
                                  pref.educationLevel,
                                  isDark,
                                ),
                                if (pref.major.isNotEmpty)
                                  _buildDetailChip(
                                    Icons.engineering_outlined,
                                    pref.major,
                                    isDark,
                                  ),
                                if (pref.careerGoal.isNotEmpty)
                                  _buildDetailChip(
                                    Icons.flag_outlined,
                                    pref.careerGoal,
                                    isDark,
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Filter Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterTab('Semua', isDark),
                          const SizedBox(width: 8),
                          _buildFilterTab('Tinggi (80%+)', isDark),
                          const SizedBox(width: 8),
                          _buildFilterTab('Bersertifikat', isDark),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Results Header count
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredList.length} Kursus Paling Relevan',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.sort_rounded, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Skor Tertinggi',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Course Cards List
                if (_filteredList.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textDisabled),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFilter == 'Semua'
                                ? 'Belum ada kursus yang terdeteksi.'
                                : 'Belum ada kursus dengan filter $_selectedFilter.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _initData,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Sinkronkan Ulang'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _filteredList[index];
                          return _buildScoredCourseItem(item, isDark);
                        },
                        childCount: _filteredList.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isDark) {
    final isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : AppColors.outline),
          ),
        ),
        child: Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildScoredCourseItem(ScoredCourse item, bool isDark) {
    final course = item.course;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.outline,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(AppRouter.courseDetailPath(course.id)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top match rationale bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.verifiedBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        item.matchReason,
                        style: AppTypography.badge.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Skor ${item.score}%',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Image Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: CachedNetworkImage(
                          imageUrl: course.firstImage.isNotEmpty
                              ? course.firstImage
                              : course.fallbackImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => CachedNetworkImage(
                            imageUrl: course.fallbackImage,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.school,
                                  color: AppColors.textTertiary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title, LPK & Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.business_outlined,
                                  size: 13, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  course.lpkName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            course.price > 0
                                ? 'Rp ${course.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'
                                : 'Gratis / Beasiswa',
                            style: AppTypography.priceTag.copyWith(
                              color: AppColors.primary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.outline),
                const SizedBox(height: 10),

                // Footer CTA Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.level.isNotEmpty ? 'Tingkat: ${course.level}' : 'Terakreditasi',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Lihat Detail & Jadwal',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
