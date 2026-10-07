/// Home Screen with greeting, search, categories, and content sections
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/chips.dart';
import '../../../../core/widgets/molecules/course_card.dart';
import '../../../../core/widgets/molecules/lpk_card.dart';
import '../../../../core/widgets/organisms/hero_banner.dart';
import '../../../../core/widgets/organisms/filter_bottom_sheet.dart';
import '../../../../core/widgets/skeleton/skeleton_loader.dart';
import '../../../../core/widgets/chatbot_avatar_3d.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
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
  String _searchQuery = '';
  String? _selectedCategory;       // slug untuk API
  String? _selectedCategoryName;   // nama tampilan untuk chip highlight
  String _currentLocation = 'Semua';
  bool _isLoading = true;

  List<LpkModel> _lpks = [];
  List<CourseModel> _courses = [];
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
        _homeRepository.getLpks(search: _searchQuery),
        _homeRepository.getCourses(
          search: _searchQuery,
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
        bannerItems = lpks
            .where((lpk) => lpk.logoUrl != null && lpk.logoUrl!.isNotEmpty)
            .take(5)
            .map((lpk) => BannerItem(
                  imageUrl: ApiService.toFullUrl(lpk.logoUrl ?? ''),
                  title: lpk.name,
                  subtitle: lpk.address,
                  id: lpk.id,
                ))
            .toList();
      }

      if (mounted) {
        setState(() {
          _lpks = lpks;
          _courses = courses;
          _banners = bannerItems;
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
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(' $_emoji', style: const TextStyle(fontSize: 14)),
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
          color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(AppRouter.chatbot),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: const ChatBotAvatar3D(
                size: 34,
                showShadow: false,
                showRing: true,
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

  String get _emoji {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 15) return '🌤️';
    if (hour < 18) return '🌅';
    return '🌙';
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
          final String rawImg =
              course.images.isNotEmpty ? course.images.first.toString() : '';
          final String imageUrl = rawImg.isNotEmpty
              ? ApiService.toFullUrl(rawImg)
              : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(course.title)}&background=2563EB&color=fff&size=400';

          return CourseCard(
            id: course.id.toString(),
            title: course.title,
            lpkName: course.lpk['name']?.toString() ?? 'LPK Mitra',
            imageUrl: imageUrl,
            rating: 0.0,
            reviewCount: 0,
            distanceKm: 0.0,
            price: course.price.toInt(),
            category: course.category['name']?.toString() ?? 'Umum',
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
