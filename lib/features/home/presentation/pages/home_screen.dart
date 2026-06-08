/// Home Screen with greeting, search, categories, and content sections
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/chips.dart';
import '../../../../core/widgets/atoms/search_bar.dart';
import '../../../../core/widgets/molecules/course_card.dart';
import '../../../../core/widgets/molecules/lpk_card.dart';
import '../../../../core/widgets/organisms/hero_banner.dart';
import '../../../../core/widgets/organisms/filter_bottom_sheet.dart';
import '../../../../core/widgets/skeleton/skeleton_loader.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/models/lpk_model.dart';
import '../../../course/data/models/course_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  String _currentLocation = 'Semua';
  bool _isLoading = true;

  List<LpkModel> _lpks = [];
  List<CourseModel> _courses = [];
  List<BannerItem> _banners = [];

  // ✅ FIX: nama user dari API, bukan hardcoded
  String _userName = 'Pengguna';
  bool _isLoadingProfile = true;

  late final HomeRepository _homeRepository;

  final List<String> _categories = [
    'Las',
    'IT',
    'Otomotif',
    'Tata Busana',
    'Tata Boga',
    'Bahasa',
  ];

  final Map<String, String> _categorySlugMap = {
    'Las': 'las',
    'IT': 'it',
    'Otomotif': 'otomotif',
    'Tata Busana': 'tata-busana',
    'Tata Boga': 'tata-boga',
    'Bahasa': 'bahasa',
  };

  @override
  void initState() {
    super.initState();
    _homeRepository = HomeRepository(apiClient: sl());
    _loadProfile();
    _loadData();
  }

  // ✅ FIX: Ambil nama user dari API /auth/me
  Future<void> _loadProfile() async {
    try {
      final apiService = ApiService();
      final result = await apiService.getProfile();
      if (result['success'] == true) {
        final data = result['data']['data'] ?? result['data'];
        final name = data?['name']?.toString() ?? 'Pengguna';
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
        lpks =
            lpks.where((lpk) => lpk.locationName == _currentLocation).toList();
      }

      final courses = responses[1] as List<CourseModel>;
      debugPrint('COURSES PARSED LENGTH: ${courses.length}');

      // ✅ FIX: Banners dari LPK yang terverifikasi (fallback kalau tidak ada API banner)
      final bannerItems = lpks
          .where((lpk) => lpk.isVerified && (lpk.logoUrl?.isNotEmpty ?? false))
          .take(5)
          .map((lpk) => BannerItem(
                imageUrl: ApiService.toFullUrl(lpk.logoUrl ?? ''),
                title: lpk.name,
                subtitle: lpk.address ?? '',
                id: '',
              ))
          .toList();

      if (mounted) {
        setState(() {
          _lpks = lpks;
          _courses = courses;
          _banners = bannerItems;
          _isLoading = false;
        });
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
          _selectedCategory != null ? [_selectedCategory!] : null,
    );

    if (result != null) {
      setState(() {
        if (result.kecamatan != null) _currentLocation = result.kecamatan!;
        if (result.categories.isNotEmpty) {
          _selectedCategory = _categorySlugMap[result.categories.first];
        }
        _isLoading = true;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await Future.wait([_loadProfile(), _loadData()]);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 160,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color:
                          Theme.of(context).colorScheme.outline.withAlpha(50),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ FIX: userName dari state (diisi oleh _loadProfile)
                        GreetingBanner(
                          userName: _isLoadingProfile ? '...' : _userName,
                          notificationCount: 3,
                          onNotificationTap: () {},
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppSearchBar(
                                hint: 'Cari kursus atau LPK...',
                                onSubmitted: (query) async {
                                  setState(() {
                                    _searchQuery = query;
                                    _isLoading = true;
                                  });
                                  await _loadData();
                                },
                                onFilterPressed: _openFilter,
                                showFilterButton: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            LocationChip(
                              location: _currentLocation,
                              onTap: _openFilter,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ FIX: Banner tampil dari data _banners yang sudah diisi
                  _isLoading
                      ? const SkeletonBanner()
                      : _banners.isEmpty
                          ? const SizedBox(height: 8)
                          : HeroBanner(items: _banners),
                  const SizedBox(height: 24),
                  CategoryFilterChips(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onSelected: (category) async {
                      setState(() {
                        _selectedCategory = _categorySlugMap[category];
                        _isLoading = true;
                      });
                      await _loadData();
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    title: 'LPK Terdekat',
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: 12),
                  _isLoading ? const SkeletonLPKList() : _buildLPKList(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    title: 'Kursus Populer',
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: 12),
                  _isLoading ? const SkeletonCourseGrid() : _buildCourseGrid(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: AppTypography.titleMedium),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('Lihat Semua')),
        ],
      ),
    );
  }

  Widget _buildLPKList() {
    if (_lpks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(child: Text('Belum ada LPK')),
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
                : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(lpk.name)}&background=random',
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
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(child: Text('Belum ada Kursus')),
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
          childAspectRatio: 0.9,
        ),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          String rawImg =
              course.images.isNotEmpty ? course.images.first.toString() : '';
          final String imageUrl = rawImg.isNotEmpty
              ? ApiService.toFullUrl(rawImg)
              : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(course.title)}&background=random&size=400';

          return CourseCard(
            id: course.id.toString(),
            title: course.title,
            // ✅ FIX: ambil lpkName dengan null-safety
            lpkName: course.lpk['name']?.toString() ?? 'LPK Mitra',
            imageUrl: imageUrl,
            rating: 0.0,
            reviewCount: 0,
            distanceKm: 0.0,
            price: course.price.toInt(),
            category: course.category['name']?.toString() ?? 'Umum',
            isVerified: true,
            onTap: () =>
                context.push(AppRouter.courseDetailPath(course.id.toString())),
          );
        },
      ),
    );
  }
}
