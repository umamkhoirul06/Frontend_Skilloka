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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  String _currentLocation = 'Indramayu';
  bool _isLoading = true;

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
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
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
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return LPKCard(
            id: 'lpk_$index',
            name: 'LPK Mitra Kerja ${index + 1}',
            logoUrl: 'https://picsum.photos/100/100?random=$index',
            address: 'Jl. Merdeka No. ${index + 1}, Indramayu',
            rating: 4.5 + (index * 0.1),
            reviewCount: 120 + (index * 10),
            isVerified: index % 2 == 0,
            onTap: () => context.push('${AppRouter.lpkDetail}lpk_$index'),
          );
        },
      ),
    );
  }

  Widget _buildCourseGrid() {
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
        itemCount: 6,
        itemBuilder: (context, index) {
          return CourseCard(
            id: 'course_$index',
            title: 'Kursus ${_categories[index % _categories.length]}',
            lpkName: 'LPK Mitra Kerja',
            imageUrl: 'https://picsum.photos/400/300?random=${index + 10}',
            rating: 4.5 + (index * 0.1),
            reviewCount: 50 + index * 5,
            distanceKm: 2.5 + index,
            price: 1500000 + (index * 250000),
            category: _categories[index % _categories.length],
            isVerified: index % 3 == 0,
            onTap: () => context.push('${AppRouter.courseDetail}course_$index'),
          );
        },
      ),
    );
  }
}
