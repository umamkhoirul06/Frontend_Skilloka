import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<_FavItem> _favCourses = [
    _FavItem(
      id: 'c1',
      title: 'Las Listrik untuk Pemula',
      subtitle: 'LPK Mitra Karya · 4.8 ⭐',
      imageTag: '35',
      color: AppColors.categoryLas,
      price: 'Rp 1.500.000',
      type: 'course',
    ),
    _FavItem(
      id: 'c2',
      title: 'Desain Grafis & UI/UX Dasar',
      subtitle: 'LPK Digital Indramayu · 4.9 ⭐',
      imageTag: '36',
      color: AppColors.categoryIT,
      price: 'Rp 2.000.000',
      type: 'course',
    ),
    _FavItem(
      id: 'c3',
      title: 'Tata Boga Profesional',
      subtitle: 'LPK Kuliner Jaya · 4.7 ⭐',
      imageTag: '37',
      color: AppColors.categoryTataBoga,
      price: 'Rp 1.800.000',
      type: 'course',
    ),
  ];

  final List<_FavItem> _favLPKs = [
    _FavItem(
      id: 'l1',
      title: 'LPK Mitra Karya',
      subtitle: '15 kursus · 4.8 ⭐ · 500+ alumni',
      imageTag: '20',
      color: AppColors.primary,
      price: '',
      type: 'lpk',
    ),
    _FavItem(
      id: 'l2',
      title: 'LPK Digital Nusantara',
      subtitle: '8 kursus · 4.9 ⭐ · 300+ alumni',
      imageTag: '21',
      color: AppColors.categoryIT,
      price: '',
      type: 'lpk',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _removeFromFav(String id, String type) {
    setState(() {
      if (type == 'course') {
        _favCourses.removeWhere((e) => e.id == id);
      } else {
        _favLPKs.removeWhere((e) => e.id == id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Dihapus dari favorit'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusMD),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primaryLight,
          onPressed: () => setState(() {}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: 'Kursus (${_favCourses.length})'),
            Tab(text: 'LPK (${_favLPKs.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_favCourses),
          _buildList(_favLPKs),
        ],
      ),
    );
  }

  Widget _buildList(List<_FavItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text('Belum ada favorit', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Simpan kursus atau LPK favorit Anda\nuntuk akses cepat',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _buildFavCard(item);
      },
    );
  }

  Widget _buildFavCard(_FavItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppShapes.cardRadius,
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _removeFromFav(item.id, item.type),
      child: GestureDetector(
        onTap: () {
          if (item.type == 'course') {
            context.push('/course/${item.id}');
          } else {
            context.push('/lpk/${item.id}');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppShapes.cardRadius,
            boxShadow: AppShapes.shadowSM,
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.network(
                  'https://picsum.photos/100/100?random=${item.imageTag}',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: AppShapes.chipRadius,
                        ),
                        child: Text(
                          item.type == 'course' ? 'Kursus' : 'LPK',
                          style: AppTypography.badge.copyWith(
                            color: item.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: AppTypography.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.price.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.price,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Fav button
              IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.error),
                onPressed: () => _removeFromFav(item.id, item.type),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavItem {
  final String id;
  final String title;
  final String subtitle;
  final String imageTag;
  final Color color;
  final String price;
  final String type;

  const _FavItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageTag,
    required this.color,
    required this.price,
    required this.type,
  });
}
