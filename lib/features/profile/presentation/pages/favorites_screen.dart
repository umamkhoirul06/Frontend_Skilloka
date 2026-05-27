import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _favCourses = [];
  List<Map<String, dynamic>> _favLPKs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.getFavorites();
      if (!mounted) return;
      if (result['success']) {
        final raw = result['data'];
        final data = raw['data'] ?? raw;
        // Backend bisa return { courses: [], lpks: [] }
        // atau flat list dengan field 'type'
        final courses = <Map<String, dynamic>>[];
        final lpks = <Map<String, dynamic>>[];

        if (data is Map) {
          // Format: { courses: [...], lpks: [...] }
          final c = data['courses'] ?? data['course'] ?? [];
          final l = data['lpks'] ?? data['lpk'] ?? [];
          for (final item in c) {
            if (item is Map<String, dynamic>) courses.add(item);
          }
          for (final item in l) {
            if (item is Map<String, dynamic>) lpks.add(item);
          }
        } else if (data is List) {
          // Format: flat list dengan field type
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final type = item['type'] ?? item['item_type'] ?? '';
              if (type == 'lpk') {
                lpks.add(item['lpk'] ?? item);
              } else {
                courses.add(item['course'] ?? item);
              }
            }
          }
        }

        setState(() {
          _favCourses = courses;
          _favLPKs = lpks;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  Future<void> _removeFromFav(String id, String type) async {
    await _api.toggleFavorite(itemId: id, itemType: type);
    setState(() {
      if (type == 'course') {
        _favCourses.removeWhere((e) => e['id'].toString() == id);
      } else {
        _favLPKs.removeWhere((e) => e['id'].toString() == id);
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dihapus dari favorit'),
        behavior: SnackBarBehavior.floating,
      ));
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_favCourses, 'course'),
                    _buildList(_favLPKs, 'lpk'),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(_error ?? 'Terjadi kesalahan', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _fetchFavorites, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant, shape: BoxShape.circle),
              child: const Icon(Icons.favorite_border,
                  size: 40, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text('Belum ada favorit', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Simpan kursus atau LPK favorit\nuntuk akses cepat',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) => _buildFavCard(items[i], type),
      ),
    );
  }

  Widget _buildFavCard(Map<String, dynamic> item, String type) {
    final id = item['id']?.toString() ?? '';
    final title = item['name'] ?? item['title'] ?? '-';
    final imageUrl = ApiService.toFullUrl(
        item['image_url'] ?? item['image'] ?? item['logo_url'] ?? item['logo']);
    final price = item['price'];
    final rating = item['rating'];
    final lpkName = item['lpk']?['name'] ?? item['lpk_name'] ?? '';

    return Dismissible(
      key: Key('$type-$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: AppColors.error, borderRadius: AppShapes.cardRadius),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _removeFromFav(id, type),
      child: GestureDetector(
        onTap: () {
          if (type == 'course') {
            context.push('/course/$id');
          } else {
            context.push('/lpk/$id');
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
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder())
                    : _imagePlaceholder(),
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
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (type == 'course'
                                  ? AppColors.primary
                                  : AppColors.secondary)
                              .withValues(alpha: 0.1),
                          borderRadius: AppShapes.chipRadius,
                        ),
                        child: Text(
                          type == 'course' ? 'Kursus' : 'LPK',
                          style: AppTypography.badge.copyWith(
                            color: type == 'course'
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(title,
                          style: AppTypography.labelLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (lpkName.isNotEmpty)
                        Text(lpkName,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      if (rating != null)
                        Text('⭐ $rating',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      if (price != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${_formatPrice(price)}',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.error),
                onPressed: () => _removeFromFav(id, type),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.surfaceVariant,
      child:
          const Icon(Icons.image_not_supported, color: AppColors.textTertiary),
    );
  }

  String _formatPrice(dynamic price) {
    final num p = price is num ? price : num.tryParse(price.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
