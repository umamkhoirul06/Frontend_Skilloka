import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/navigation/app_router.dart';

/// Search Screen — PRD: pencarian kursus dan LPK dengan filter
/// Fitur: debounce search, filter kategori, sort, bottom sheet filter
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  late TabController _tabController;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _lpks = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  bool _initialLoad = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
    _loadCategories();
    _search();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery == null) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final result = await _api.getCategories();
    if (result['success'] == true && mounted) {
      final data = result['data'];
      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        rawList = data['data'] ?? [];
      }
      setState(() {
        _categories = rawList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search();
    });
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _initialLoad = false;
    });

    final q = _searchController.text.trim();
    final cat = _selectedCategory;

    try {
      final coursesFuture = _api.getCourses(search: q, category: cat);
      final lpksFuture = _api.getLpks(search: q, category: cat);

      final results = await Future.wait([coursesFuture, lpksFuture]);

      if (!mounted) return;

      final coursesResult = results[0];
      final lpksResult = results[1];

      List<Map<String, dynamic>> courses = [];
      List<Map<String, dynamic>> lpks = [];

      List<dynamic> extractList(dynamic resData) {
        if (resData == null) return [];
        if (resData is List) return resData;
        if (resData is Map) {
          final d = resData['data'];
          if (d is List) return d;
          if (d is Map && d['data'] is List) return d['data'];
          if (resData['items'] is List) return resData['items'];
          if (resData['value'] is List) return resData['value'];
        }
        return [];
      }

      if (coursesResult['success'] == true) {
        final list = extractList(coursesResult['data']);
        courses = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (lpksResult['success'] == true) {
        final list = extractList(lpksResult['data']);
        lpks = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      setState(() {
        _courses = courses;
        _lpks = lpks;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        categories: _categories,
        selectedCategory: _selectedCategory,
        onApply: (category) {
          setState(() => _selectedCategory = category);
          _search();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryChips(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCourseResults(),
                  _buildLPKResults(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _search(),
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Cari kursus atau LPK...',
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                prefixIcon: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: Stack(
              children: [
                const Icon(Icons.tune),
                if (_selectedCategory != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_categories.isEmpty) return const SizedBox();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            final isSelected = _selectedCategory == null;
            return FilterChip(
              label: const Text('Semua'),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = null);
                _search();
              },
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }
          final cat = _categories[i - 1];
          final catId = cat['id']?.toString() ?? '';
          final catName = cat['name']?.toString() ?? '';
          final isSelected = _selectedCategory == catId;
          return FilterChip(
            label: Text(catName),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedCategory = isSelected ? null : catId);
              _search();
            },
            selectedColor: AppColors.primary.withOpacity(0.15),
            checkmarkColor: AppColors.primary,
            labelStyle: AppTypography.labelSmall.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelStyle: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: AppTypography.labelMedium,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      tabs: [
        Tab(text: 'Kursus (${_courses.length})'),
        Tab(text: 'LPK (${_lpks.length})'),
      ],
    );
  }

  Widget _buildCourseResults() {
    if (_initialLoad) return const SizedBox();
    if (_isLoading) return _buildLoading();
    if (_courses.isEmpty) return _buildNoResult('kursus');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final course = _courses[i];
        return _CourseResultCard(course: course);
      },
    );
  }

  Widget _buildLPKResults() {
    if (_initialLoad) return const SizedBox();
    if (_isLoading) return _buildLoading();
    if (_lpks.isEmpty) return _buildNoResult('LPK');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _lpks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final lpk = _lpks[i];
        return _LPKResultCard(lpk: lpk);
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildNoResult(String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Tidak ada $type ditemukan',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain atau hapus filter yang aktif.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseResultCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseResultCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final id = course['id']?.toString() ?? '';
    final title = course['title']?.toString() ?? 'Kursus';
    final lpk = course['lpk'];
    final lpkName = (lpk is Map ? lpk['name'] : null)?.toString() ?? 'LPK';
    final category = course['category'];
    final catName = (category is Map ? category['name'] : null)?.toString() ?? '';
    final price = course['price'];
    final formattedPrice = price != null
        ? 'Rp ${_formatNumber(double.tryParse(price.toString()) ?? 0)}'
        : 'Cek harga';
    final level = course['level']?.toString() ?? '';
    final duration = course['duration_hours']?.toString();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outline),
      ),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(AppRouter.courseDetailPath(id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (catName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        catName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (level.isNotEmpty)
                    Text(
                      _levelLabel(level),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                lpkName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    formattedPrice,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (duration != null) ...[
                    Icon(Icons.access_time,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$duration jam',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _levelLabel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'Pemula';
      case 'intermediate':
        return 'Menengah';
      case 'advanced':
        return 'Mahir';
      default:
        return level;
    }
  }

  String _formatNumber(double num) {
    final n = num.toInt();
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}jt';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(0)}rb';
    }
    return n.toString();
  }
}

class _LPKResultCard extends StatelessWidget {
  final Map<String, dynamic> lpk;
  const _LPKResultCard({required this.lpk});

  @override
  Widget build(BuildContext context) {
    final id = lpk['id']?.toString() ?? '';
    final name = lpk['name']?.toString() ?? 'LPK';
    final address = lpk['address']?.toString() ?? '';
    final logoUrl = ApiService.toFullUrl(
        lpk['logo_url']?.toString() ?? lpk['logo']?.toString());
    final coursesCount = lpk['courses_count']?.toString() ?? '0';
    final isVerified = lpk['is_verified'] == true;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outline),
      ),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(AppRouter.lpkDetailPath(id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _LPKPlaceholder(),
                      )
                    : _LPKPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified,
                              size: 16, color: AppColors.primary),
                        ],
                      ],
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '$coursesCount kursus tersedia',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _LPKPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.business, color: AppColors.textTertiary),
    );
  }
}

/// Filter Bottom Sheet
class _FilterBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedCategory;
  final void Function(String?) onApply;

  const _FilterBottomSheet({
    required this.categories,
    required this.selectedCategory,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Filter Kategori',
                    style: AppTypography.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _selected = null);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: widget.categories.map((cat) {
                final id = cat['id']?.toString() ?? '';
                final name = cat['name']?.toString() ?? '';
                return ListTile(
                  dense: true,
                  title: Text(name, style: AppTypography.bodyMedium),
                  leading: Radio<String?>(
                    value: id,
                    groupValue: _selected,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _selected = v),
                  ),
                  onTap: () => setState(
                      () => _selected = _selected == id ? null : id),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_selected);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Terapkan Filter'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
