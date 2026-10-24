import 'dart:math' as math;
import 'package:flutter/material.dart';
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
      duration: const Duration(milliseconds: 800),
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

      if (bannerItems.isEmpty) {
        bannerItems = [
          const BannerItem(
            imageUrl:
                'https://images.unsplash.com/photo-1581092335397-9583fe92d232?w=1000&auto=format&fit=crop&q=80',
            title: 'LPK Merah Putih Indramayu',
            subtitle: 'Pelatihan Teknik Mesin, Bubut & Otomotif Standar Industri',
            id: 'banner-1',
            tag: 'RESMI DISNAKER',
          ),
          const BannerItem(
            imageUrl:
                'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1000&auto=format&fit=crop&q=80',
            title: 'Techno Skill Center Indramayu',
            subtitle: 'Kursus Komputer, Web Coding & Desain Grafis Komersial',
            id: 'banner-2',
            tag: 'SERTIFIKASI BNSP',
          ),
          const BannerItem(
            imageUrl:
                'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1000&auto=format&fit=crop&q=80',
            title: 'Global English House Indramayu',
            subtitle: 'Program Bahasa Asing & Magang Kerja ke Jepang Resmi',
            id: 'banner-3',
            tag: 'PENEMPATAN KERJA',
          ),
        ];
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
        _animController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await Future.wait([_loadProfile(), _loadData()]);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Premium App Bar ──────────────────────────────────────────
            SliverAppBar(
              floating: false,
              pinned: true,
              expandedHeight: 170,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF0F172A),
                              const Color(0xFF1E293B),
                            ]
                          : [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 40,
                        bottom: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context),
                              const SizedBox(height: 14),
                              _buildSearchRow(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Banner
                    _isLoading
                        ? const SkeletonBanner()
                        : _banners.isEmpty
                            ? const SizedBox(height: 8)
                            : HeroBanner(items: _banners),
                    const SizedBox(height: 24),
                    // Category chips
                    CategoryFilterChips(
                      categories: _categories,
                      selectedCategory: _selectedCategoryName,
                      onSelected: (category) async {
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

                    // Personalized Recommendations Section (PRD 2.3 & 8.3)
                    if (!_isLoading) _buildPersonalizedSection(context),
                    const SizedBox(height: 28),

                    // LPK Section
                    _buildSectionHeader(
                      context,
                      title: 'LPK Terdekat',
                      subtitle: '${_lpks.length} lembaga',
                      icon: Icons.location_city_rounded,
                      onSeeAll: () => context.push(AppRouter.search),
                    ),
                    const SizedBox(height: 12),
                    _isLoading ? const SkeletonLPKList() : _buildLPKList(),
                    const SizedBox(height: 28),
                    // Course Section
                    _buildSectionHeader(
                      context,
                      title: 'Kursus Populer',
                      subtitle: '${_courses.length} kursus',
                      icon: Icons.school_rounded,
                      onSeeAll: () => context.push(AppRouter.search),
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const SkeletonCourseGrid()
                        : _buildCourseGrid(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Isi minat & jenjang studi agar pelatihan relevan muncul otomatis.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => context.push(AppRouter.educationOnboarding),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Atur Minat',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _greeting,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _isLoadingProfile ? '...' : _userName,
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push(AppRouter.notifications),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(AppRouter.search),
            child: AbsorbPointer(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.7), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Cari kursus atau LPK...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
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
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openFilter,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: const Icon(Icons.tune_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Chatbot shortcut
        Material(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(AppRouter.chatbot),
            child: Tooltip(
              message: 'Tanya Loka AI',
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.primary),
                ],
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
          childAspectRatio: 0.85,
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
