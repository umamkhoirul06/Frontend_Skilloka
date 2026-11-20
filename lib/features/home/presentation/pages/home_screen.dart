import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/chips.dart';
import '../../../../core/widgets/molecules/course_card.dart';
import '../../../../core/widgets/molecules/lpk_card.dart';
import '../../../../core/widgets/organisms/hero_banner.dart';
import '../../../../core/widgets/organisms/filter_bottom_sheet.dart';
import '../../../../core/widgets/skeleton/skeleton_loader.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/course_relevance_service.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/models/lpk_model.dart';
import '../../../course/data/models/course_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedCategory;       // slug untuk API
  String? _selectedCategoryName;   // nama tampilan untuk chip highlight
  String _currentLocation = 'Semua';
  bool _isLoading = true;

  List<LpkModel> _lpks = [];
  List<CourseModel> _courses = [];
  List<ScoredCourse> _relevantCourses = [];
  UserProfilePreference? _userPreference;
  List<BannerItem> _banners = [];

  String _userName = 'Pengguna';
  bool _isLoadingProfile = true;

  late final HomeRepository _homeRepository;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  final List<String> _categories = [
    'Teknologi & Digital',
    'Bahasa Asing',
    'Teknik Otomotif & Manufaktur',
    'Bisnis & Manajemen',
    'Perhotelan & Pariwisata',
  ];

  final Map<String, String> _categorySlugMap = {
    'Teknologi & Digital': 'teknologi-digital',
    'Bahasa Asing': 'bahasa-asing',
    'Teknik Otomotif & Manufaktur': 'teknik-otomotif-manufaktur',
    'Bisnis & Manajemen': 'bisnis-manajemen',
    'Perhotelan & Pariwisata': 'perhotelan-pariwisata',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _homeRepository = HomeRepository(apiClient: sl());
    _loadProfile();
    _loadCategories();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final apiService = ApiService();
      final result = await apiService.getCategories();
      if (result['success'] == true) {
        final data = result['data'];
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['data'] is List) {
          list = data['data'];
        }
        if (list.isNotEmpty && mounted) {
          final names = <String>[];
          final slugMap = <String, String>{};
          for (final item in list) {
            if (item is Map) {
              final name = item['name']?.toString() ?? '';
              final slug = item['slug']?.toString() ?? '';
              if (name.isNotEmpty) {
                names.add(name);
                slugMap[name] = slug;
              }
            }
          }
          if (mounted) {
            setState(() {
              _categories.clear();
              _categories.addAll(names);
              _categorySlugMap.clear();
              _categorySlugMap.addAll(slugMap);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      final apiService = ApiService();
      final result = await apiService.getProfile();
      if (result['success'] == true) {
        final raw = result['data'];
        final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
        final name =
            (data is Map ? data['name']?.toString() : null) ?? 'Pengguna';
        if (mounted) {
          setState(() {
            _userName = name;
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadData() async {
    try {
      debugPrint('CATEGORY = $_selectedCategory');

      final responses = await Future.wait([
        _homeRepository.getLpks(search: ''),
        _homeRepository.getCourses(
          search: '',
          category: _selectedCategory,
        ),
      ]);

      List<LpkModel> lpks = responses[0] as List<LpkModel>;
      if (_currentLocation != 'Semua') {
        lpks = lpks
            .where((lpk) => lpk.locationName == _currentLocation)
            .toList();
      }

      final courses = responses[1] as List<CourseModel>;
      debugPrint('COURSES PARSED LENGTH: ${courses.length}');

      List<BannerItem> bannerItems = [];
      try {
        final apiBanners = await _homeRepository.getBanners();
        if (apiBanners.isNotEmpty) {
          bannerItems = apiBanners;
        }
      } catch (_) {}

      if (bannerItems.isEmpty && courses.isNotEmpty) {
        // Tampilkan kursus resmi online sebagai banner dinamis
        bannerItems = courses.take(4).map((c) {
          return BannerItem(
            id: 'featured-${c.id}',
            title: c.title,
            subtitle: '${c.lpkName} • ${c.categoryName}',
            imageUrl: c.firstImage,
            tag: c.level.isNotEmpty ? c.level.toUpperCase() : 'RESMI',
          );
        }).toList();
      }

      // Compute algorithmically relevant courses based on user education & career profile
      final pref = await CourseRelevanceService.getPreference();
      List<ScoredCourse> scored = [];
      if (pref != null && courses.isNotEmpty) {
        scored = CourseRelevanceService.rankCourses(
          courses: courses,
          preference: pref,
        );
      }

      if (mounted) {
        setState(() {
          _lpks = lpks;
          _courses = courses;
          _banners = bannerItems;
          _userPreference = pref;
          _relevantCourses = scored;
          _isLoading = false;
        });
        _animController.forward(from: 0.4);
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.value = 1.0;
      }
    }
  }

  void _openFilter() async {
    final result = await FilterBottomSheet.show(
      context,
      kecamatanList: IndramayuKecamatan.list,
      categories: _categories,
      selectedCategories:
          _selectedCategoryName != null ? [_selectedCategoryName!] : null,
    );

    if (result != null) {
      setState(() {
        if (result.kecamatan != null) _currentLocation = result.kecamatan!;
        if (result.categories.isNotEmpty) {
          _selectedCategoryName = result.categories.first;
          _selectedCategory = _categorySlugMap[result.categories.first];
        }
        _isLoading = true;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBar = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF090D16),
                    const Color(0xFF05080E),
                  ]
                : [
                    const Color(0xFFEEF4FF), // Soft smooth gradient near top
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9),
                  ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _isLoading = true);
            await Future.wait([_loadProfile(), _loadData()]);
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── Premium App Bar dengan Proteksi Status Bar & Transisi Halus ──
              SliverAppBar(
                floating: false,
                pinned: true,
                expandedHeight: 180,
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E3A8A),
                elevation: 3,
                shadowColor: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                systemOverlayStyle: SystemUiOverlayStyle.light,
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final top = constraints.biggest.height;
                    final isCollapsed = top <= (statusBar + kToolbarHeight + 25);

                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF0A0F1D),
                                  const Color(0xFF111827),
                                  const Color(0xFF1E293B),
                                ]
                              : [
                                  const Color(0xFF1E3A8A), // deep royal navy
                                  const Color(0xFF2563EB), // brand royal blue
                                  const Color(0xFF3B82F6), // vibrant blue
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.black : const Color(0xFF1E3A8A))
                                .withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative ambient circles
                          Positioned(
                            right: -25,
                            top: -25,
                            child: Container(
                              width: 155,
                              height: 155,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 45,
                            bottom: -30,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          SafeArea(
                            bottom: false,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: isCollapsed
                                  ? _buildCollapsedHeader(context)
                                  : _buildExpandedHeader(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Menyinkronkan data kursus & LPK resmi...',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // ── 1. Hero Card "Progres Belajar Kamu" (Reference Style) ──
                      _buildHeroLearningProgressCard(context),
                      const SizedBox(height: 20),

                      // ── 2. Menu Utama 8 Grid (Reference Style) ────────────────
                      _buildQuickMainMenuGrid(context),
                      const SizedBox(height: 24),

                      // ── 3. Banner Carousel ────────────────────────────────────
                      _isLoading
                          ? const SkeletonBanner()
                          : _banners.isEmpty
                              ? const SizedBox.shrink()
                              : HeroBanner(items: _banners),
                      const SizedBox(height: 24),

                      // ── 4. Kategori Kelas Card Slider (Reference Style) ───────
                      _buildCategoryCardSlider(context),
                      const SizedBox(height: 24),

                      // ── 5. Category filter chips ──────────────────────────────
                      CategoryFilterChips(
                        categories: _categories,
                        selectedCategory: _selectedCategoryName,
                        onSelected: (category) async {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategoryName = category;
                            _selectedCategory = category != null
                                ? _categorySlugMap[category]
                                : null;
                            _isLoading = true;
                          });
                          await _loadData();
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── 6. Rekomendasi Algoritma Profil ───────────────────────
                      if (!_isLoading) _buildPersonalizedSection(context),
                      const SizedBox(height: 28),

                      // ── 7. LPK Terdekat ───────────────────────────────────────
                      _buildSectionHeader(
                        context,
                        title: 'LPK Terdekat',
                        subtitle: '${_lpks.length} lembaga terverifikasi',
                        icon: Icons.location_city_rounded,
                        onSeeAll: () => context.push(AppRouter.search),
                      ),
                      const SizedBox(height: 12),
                      _isLoading ? const SkeletonLPKList() : _buildLPKList(),
                      const SizedBox(height: 28),

                      // ── 8. Kursus Populer ─────────────────────────────────────
                      _buildSectionHeader(
                        context,
                        title: 'Kursus Populer',
                        subtitle: '${_courses.length} pilihan kursus siap kerja',
                        icon: Icons.school_rounded,
                        onSeeAll: () => context.push(AppRouter.search),
                      ),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const SkeletonCourseGrid()
                          : _buildCourseGrid(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalizedSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_userPreference != null && _relevantCourses.isNotEmpty) {
      final majorTitle = _userPreference!.major.isNotEmpty
          ? 'Kurasi Spesial: ${_userPreference!.major}'
          : 'Rekomendasi Profilmu';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            title: majorTitle,
            subtitle: '${_relevantCourses.length} kursus disesuaikan latar belakangmu',
            icon: Icons.auto_awesome_rounded,
            onSeeAll: () => context.push(
              AppRouter.relevantCourses,
              extra: _userPreference,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: math.min(6, _relevantCourses.length),
              itemBuilder: (context, index) {
                final item = _relevantCourses[index];
                final course = item.course;
                return Container(
                  width: 255,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.outlineDark : AppColors.outline,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push(AppRouter.courseDetailPath(course.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Match badge & category (Constrained to prevent overflow)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.successContainer,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.verifiedBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${item.score}% Cocok',
                                    style: AppTypography.badge.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    course.categoryName,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textTertiary,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Thumbnail Image with dynamic loaded photo & fallback
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 86,
                                width: double.infinity,
                                child: course.firstImage.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: course.firstImage,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: AppColors.surfaceVariant,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, url, error) => Container(
                                          color: AppColors.surfaceVariant,
                                          child: const Icon(Icons.school,
                                              color: AppColors.textTertiary),
                                        ),
                                      )
                                    : Container(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        child: const Center(
                                          child: Icon(Icons.school_rounded,
                                              color: AppColors.primary),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Title
                            Text(
                              course.title,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),

                            // Price & LPK
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    course.lpkName,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  course.price > 0
                                      ? 'Rp ${(course.price / 1000).toInt()}rb'
                                      : 'Gratis',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Callout card if user hasn't set education profile yet
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFEFF6FF), // Soft Blue tint
                    const Color(0xFFF8FAFC), // Crisp White/Slate
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalisasi Kursus',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Isi minat & jenjang studi agar pelatihan relevan muncul otomatis.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(AppRouter.educationOnboarding);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: Text(
                'Atur Minat',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedHeader(BuildContext context) {
    return Container(
      key: const ValueKey('expanded_header'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 14),
          _buildSearchRow(context),
        ],
      ),
    );
  }

  Widget _buildCollapsedHeader(BuildContext context) {
    return Container(
      key: const ValueKey('collapsed_header'),
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        children: [
          // Brand Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_rounded, color: Colors.white, size: 14),
                SizedBox(width: 5),
                Text(
                  'Skilloka',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Compact Search Pill
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(AppRouter.search);
              },
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: Colors.white, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cari kursus atau LPK...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter button
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                _openFilter();
              },
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                child: const Icon(Icons.tune_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Notification button
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(AppRouter.notifications),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Avatar circle matching reference image
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // User Greeting & Member Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoadingProfile
                    ? '...'
                    : '$_greeting, ${_userName.split(' ').first}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Siswa Vokasi Indramayu',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Toggle Switch matching reference image
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('ON',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5)),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('OFF',
                    style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.5)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Notification Bell
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push(AppRouter.notifications),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Reference Component 1: Hero Card "Progres Belajar Kamu" ─────────────
  Widget _buildHeroLearningProgressCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int progressPercent = _courses.isNotEmpty ? 75 : 60;
    final int completedLessons = _courses.isNotEmpty ? 3 : 2;
    final int totalLessons = _courses.isNotEmpty ? 5 : 4;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F1E36),
                    const Color(0xFF162E56),
                  ]
                : [
                    const Color(0xFF0A192F),
                    const Color(0xFF11254A),
                    const Color(0xFF163266),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Circular Progress Indicator Ring matching reference
                SizedBox(
                  width: 66,
                  height: 66,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 66,
                        height: 66,
                        child: CircularProgressIndicator(
                          value: progressPercent / 100,
                          strokeWidth: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981), // Emerald green like reference
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$progressPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Text Information & Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progres Belajar Kamu',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$completedLessons dari $totalLessons Materi ',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: 'Selesai',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Linear Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100,
                          minHeight: 5.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Action Button: "Lanjut Belajar ➔"
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRouter.myCourses);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lanjut Belajar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Reference Component 2: Menu Utama 8 Grid ────────────────────────────
  Widget _buildQuickMainMenuGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final menuItems = [
      {
        'title': 'Kategori\nKelas',
        'icon': Icons.menu_book_rounded,
        'badge': null,
        'badgeColor': null,
        'color': const Color(0xFF2563EB),
        'onTap': () => _openFilter(),
      },
      {
        'title': 'Materi',
        'icon': Icons.play_circle_fill_rounded,
        'badge': 'NEW',
        'badgeColor': const Color(0xFF10B981),
        'color': const Color(0xFF0284C7),
        'onTap': () => context.push(AppRouter.myCourses),
      },
      {
        'title': 'Diskusi',
        'icon': Icons.forum_rounded,
        'badge': '8',
        'badgeColor': const Color(0xFFEF4444),
        'color': const Color(0xFF4F46E5),
        'onTap': () => context.push(AppRouter.chatbot),
      },
      {
        'title': 'List\nSetoran',
        'icon': Icons.assignment_turned_in_rounded,
        'badge': null,
        'badgeColor': null,
        'color': const Color(0xFF0D9488),
        'onTap': () => context.push(AppRouter.bookings),
      },
      {
        'title': 'Remin\nToday',
        'icon': Icons.campaign_rounded,
        'badge': null,
        'badgeColor': null,
        'color': const Color(0xFF0284C7),
        'onTap': () => context.push(AppRouter.notifications),
      },
      {
        'title': 'Jadwal\nSeminar',
        'icon': Icons.calendar_month_rounded,
        'badge': null,
        'badgeColor': null,
        'color': const Color(0xFF38BDF8),
        'onTap': () => context.push(AppRouter.search),
      },
      {
        'title': 'Rekapan',
        'icon': Icons.folder_shared_rounded,
        'badge': null,
        'badgeColor': null,
        'color': const Color(0xFF2563EB),
        'onTap': () => context.push(AppRouter.bookings),
      },
      {
        'title': 'Lainnya',
        'icon': Icons.apps_rounded,
        'badge': null,
        'badgeColor': null,
        'color': const Color(0xFF6366F1),
        'onTap': () => context.push(AppRouter.search),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Menu Utama',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: menuItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _buildMenuGridTile(
                context,
                title: item['title'] as String,
                icon: item['icon'] as IconData,
                badge: item['badge'] as String?,
                badgeColor: item['badgeColor'] as Color?,
                color: item['color'] as Color,
                onTap: item['onTap'] as VoidCallback,
                isDark: isDark,
              );
            },
          ),
          const SizedBox(height: 10),
          // 3 Page Indicator dots matching reference design
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 6,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGridTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? badge,
    Color? badgeColor,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Squircle Box matching reference
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1E293B),
                              const Color(0xFF0F172A),
                            ]
                          : [
                              const Color(0xFFEEF5FF),
                              const Color(0xFFE0EDFF),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFBFDBFE).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 28,
                      color: color,
                    ),
                  ),
                ),

                // Micro Badge (e.g. "NEW", "8")
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Reference Component 3: Kategori Kelas Card Slider ───────────────────
  Widget _buildCategoryCardSlider(BuildContext context) {
    final cardGradients = [
      // Card 1: Dark Navy / Green accent
      [const Color(0xFF0F1E36), const Color(0xFF132B52)],
      // Card 2: Royal Blue gradient
      [const Color(0xFF1E40AF), const Color(0xFF2563EB)],
      // Card 3: Deep Slate / Indigo
      [const Color(0xFF1E293B), const Color(0xFF0F172A)],
      // Card 4: Dark Amber / Navy
      [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Kategori Kelas',
          subtitle: '${_categories.length} bidang kejuruan',
          icon: Icons.layers_rounded,
          onSeeAll: () => _openFilter(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final gradient = cardGradients[index % cardGradients.length];
              final isLocked = index >= 3;
              final progress = index == 0 ? 0.75 : (index == 1 ? 0.40 : 0.0);
              final courseCount = (index * 2 + 3);

              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategoryName = cat;
                    _selectedCategory = _categorySlugMap[cat];
                    _isLoading = true;
                  });
                  await _loadData();
                },
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category Title
                      Text(
                        cat,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Subtitle
                      Text(
                        '*$courseCount Materi',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Progress Bar & Lock Status matching reference image
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isLocked)
                            const Icon(
                              Icons.lock_rounded,
                              size: 13,
                              color: Color(0xFFFBBF24),
                            )
                          else if (progress > 0)
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRouter.search);
            },
            child: AbsorbPointer(
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cari kursus atau LPK...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Filter button
        Material(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.lightImpact();
              _openFilter();
            },
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.tune_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Chatbot shortcut
        Material(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRouter.chatbot);
            },
            child: Tooltip(
              message: 'Tanya Loka AI',
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? icon,
    VoidCallback? onSeeAll,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF1E3A8A).withValues(alpha: 0.5),
                          const Color(0xFF2563EB).withValues(alpha: 0.3),
                        ]
                      : [
                          const Color(0xFF2563EB).withValues(alpha: 0.14),
                          const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    fontSize: 17,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSeeAll();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 13, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLPKList() {
    if (_lpks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.location_city_outlined,
        message: 'Belum ada LPK tersedia',
      );
    }
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _lpks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final lpk = _lpks[index];
          final logoSafe = ApiService.toFullUrl(lpk.logoUrl ?? '');
          return LPKCard(
            id: lpk.id.toString(),
            name: lpk.name,
            logoUrl: logoSafe.isNotEmpty
                ? logoSafe
                : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(lpk.name)}&background=2563EB&color=fff&size=200',
            address: lpk.address,
            rating: lpk.rating,
            reviewCount: lpk.reviewCount,
            isVerified: lpk.isVerified,
            onTap: () =>
                context.push(AppRouter.lpkDetailPath(lpk.id.toString())),
          );
        },
      ),
    );
  }

  Widget _buildCourseGrid() {
    if (_courses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.school_outlined,
        message: 'Belum ada kursus tersedia',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.74,
        ),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          final String imageUrl = course.firstImage;

          return CourseCard(
            id: course.id.toString(),
            title: course.title,
            lpkName: course.lpkName,
            imageUrl: imageUrl,
            rating: 0.0,
            reviewCount: 0,
            distanceKm: 0.0,
            price: course.price.toInt(),
            category: course.categoryName,
            isVerified: true,
            onTap: () => context
                .push(AppRouter.courseDetailPath(course.id.toString())),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.outline),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
