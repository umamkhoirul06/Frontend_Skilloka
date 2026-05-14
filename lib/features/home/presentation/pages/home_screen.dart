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
import '../../data/repositories/home_repository.dart';
import '../../data/models/lpk_model.dart';
import '../../../course/data/models/course_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  String _currentLocation = 'Indramayu';
  bool _isLoading = true;

  List<LpkModel> _lpks = [];
  List<CourseModel> _courses = [];
  late final HomeRepository _homeRepository;

  final List<String> _categories = [
    'Las',
    'IT',
    'Otomotif',
    'Tata Busana',
    'Tata Boga',
    'Bahasa',
  ];

  // Mock data
  final List<BannerItem> _banners = [
    const BannerItem(
      id: '1',
      title: 'Diskon 50% untuk Kursus Las',
      subtitle: 'Berlaku hingga akhir bulan',
      imageUrl: 'https://picsum.photos/800/400?random=1',
      tag: 'Promo',
    ),
    const BannerItem(
      id: '2',
      title: 'Sertifikasi IT Gratis',
      subtitle: 'Program pemerintah',
      imageUrl: 'https://picsum.photos/800/400?random=2',
      tag: 'Baru',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _homeRepository = HomeRepository(apiClient: sl());
    _loadData();
  }

  Future<void> _loadData() async {
    final responses = await Future.wait([
      _homeRepository.getLpks(),
      _homeRepository.getCourses(),
    ]);

    if (mounted) {
      setState(() {
        _lpks = responses[0] as List<LpkModel>;
        _courses = responses[1] as List<CourseModel>;
        _isLoading = false;
      });
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
        if (result.kecamatan != null) {
          _currentLocation = result.kecamatan!;
        }
        if (result.categories.isNotEmpty) {
          _selectedCategory = result.categories.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await _loadData();
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
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha(50),
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
                        // Greeting Banner
                        GreetingBanner(
                          userName: 'Pengguna',
                          notificationCount: 3,
                          onNotificationTap: () {
                            // TODO: Open notifications
                          },
                        ),
                        const SizedBox(height: 16),
                        // Search Bar
                        Row(
                          children: [
                            Expanded(
                              child: AppSearchBar(
                                hint: 'Cari kursus atau LPK...',
                                onSubmitted: (query) {
                                  // TODO: Navigate to search results
                                },
                                onFilterPressed: _openFilter,
                                showFilterButton: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Location Chip
                            LocationChip(
                              location: _currentLocation,
                              onTap: _openFilter,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ), // SafeArea
              ), // Container (flexibleSpace)
            ), // SliverAppBar
            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Banner
                  _isLoading
                      ? const SkeletonBanner()
                      : HeroBanner(items: _banners),

                  const SizedBox(height: 24),

                  // Category Filter
                  CategoryFilterChips(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onSelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),

                  const SizedBox(height: 24),

                  // LPK Terdekat Section
                  _buildSectionHeader(
                    title: 'LPK Terdekat',
                    onSeeAll: () {
                      // TODO: Navigate to all LPKs
                    },
                  ),
                  const SizedBox(height: 12),
                  _isLoading ? const SkeletonLPKList() : _buildLPKList(),

                  const SizedBox(height: 24),

                  // Kursus Populer Section
                  _buildSectionHeader(
                    title: 'Kursus Populer',
                    onSeeAll: () {
                      // TODO: Navigate to all courses
                    },
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
    if (_lpks.isEmpty) return const Center(child: Text("Belum ada LPK"));

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _lpks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final lpk = _lpks[index];
          return LPKCard(
            id: lpk.id.toString(),
            name: lpk.name,
            logoUrl: lpk.logoUrl ?? 'https://via.placeholder.com/100',
            address: lpk.address,
            rating: lpk.rating,
            reviewCount: lpk.reviewCount,
            isVerified: lpk.isVerified,
            onTap: () => context.push('${AppRouter.lpkDetail}${lpk.id}'),
          );
        },
      ),
    );
  }

  Widget _buildCourseGrid() {
    if (_courses.isEmpty) return const Center(child: Text("Belum ada Kursus"));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          String imageUrl = course.images.isNotEmpty
              ? '${AppConfig.baseStorageUrl}${course.images.first}'
              : 'https://via.placeholder.com/400';

          return CourseCard(
            id: course.id.toString(),
            title: course.title,
            lpkName: course.lpk['name'] ?? 'LPK Tidak Diketahui',
            imageUrl: imageUrl,
            rating: 0.0,
            reviewCount: 0,
            distanceKm: 0.0,
            price: course.price.toInt(),
            category: course.category['name'] ?? 'Umum',
            isVerified: true,
            onTap: () => context.push('${AppRouter.courseDetail}${course.id}'),
          );
        },
      ),
    );
  }
}
