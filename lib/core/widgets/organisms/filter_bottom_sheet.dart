/// Filter Bottom Sheet with location, category, and price selectors
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_typography.dart';
import '../../animations/app_animations.dart';
import '../atoms/animated_button.dart';
import '../atoms/input_field.dart';
import '../../services/location_service.dart';
import '../../error/exceptions.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<String> kecamatanList;
  final List<String> categories;
  final String? selectedKecamatan;
  final List<String>? selectedCategories;
  final RangeValues? priceRange;
  final double? maxDistance;
  final Function(FilterResult)? onApply;

  const FilterBottomSheet({
    super.key,
    required this.kecamatanList,
    required this.categories,
    this.selectedKecamatan,
    this.selectedCategories,
    this.priceRange,
    this.maxDistance,
    this.onApply,
  });

  static Future<FilterResult?> show(
    BuildContext context, {
    required List<String> kecamatanList,
    required List<String> categories,
    String? selectedKecamatan,
    List<String>? selectedCategories,
    RangeValues? priceRange,
    double? maxDistance,
  }) {
    return showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        kecamatanList: kecamatanList,
        categories: categories,
        selectedKecamatan: selectedKecamatan,
        selectedCategories: selectedCategories,
        priceRange: priceRange,
        maxDistance: maxDistance,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late TextEditingController _searchController;
  String? _selectedKecamatan;
  late List<String> _selectedCategories;
  RangeValues _priceRange = const RangeValues(0, 10000000);
  double _maxDistance = 50;
  String _searchQuery = '';

  bool _isLocating = false;
  bool _useGpsLocation = false;
  double? _detectedLat;
  double? _detectedLng;
  String? _gpsKecamatan;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedKecamatan = widget.selectedKecamatan;
    _selectedCategories = widget.selectedCategories ?? [];
    _priceRange = widget.priceRange ?? const RangeValues(0, 10000000);
    _maxDistance = widget.maxDistance ?? 50;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await LocationService().getCurrentLocation();
      final nearest = LocationService().findNearestKecamatan(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _useGpsLocation = true;
          _detectedLat = pos.latitude;
          _detectedLng = pos.longitude;
          _gpsKecamatan = nearest.$1;
          _selectedKecamatan = nearest.$1;
          _isLocating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi GPS terdeteksi: Kecamatan ${nearest.$1} (~${nearest.$2.toStringAsFixed(1)} km)',
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppExceptionHandler.getFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _selectedKecamatan = null;
      _selectedCategories = [];
      _priceRange = const RangeValues(0, 10000000);
      _maxDistance = 50;
      _searchQuery = '';
      _searchController.clear();
      _useGpsLocation = false;
      _detectedLat = null;
      _detectedLng = null;
      _gpsKecamatan = null;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      FilterResult(
        kecamatan: _selectedKecamatan,
        categories: _selectedCategories,
        priceRange: _priceRange,
        maxDistance: _maxDistance,
        useGpsLocation: _useGpsLocation,
        userLat: _detectedLat,
        userLng: _detectedLng,
      ),
    );
  }

  String _formatPrice(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(0)} jt';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)} rb';
    }
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredKecamatan = widget.kecamatanList
        .where((k) => k.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
        maxWidth: MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppShapes.bottomSheetRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Filter', style: AppTypography.titleLarge),
                const Spacer(),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Section
                  Text('Kecamatan / Lokasi', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),

                  // GPS / Maps Quick Location Action Card
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: _useGpsLocation
                              ? AppColors.primary.withValues(alpha: 0.10)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _useGpsLocation
                                ? AppColors.primary
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: 1.2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isLocating ? null : _detectLocation,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _useGpsLocation
                                          ? AppColors.primary
                                          : AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _isLocating
                                        ? const Padding(
                                            padding: EdgeInsets.all(10),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : Icon(
                                            Icons.my_location_rounded,
                                            color: _useGpsLocation ? Colors.white : AppColors.primary,
                                            size: 20,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _useGpsLocation
                                              ? 'GPS Aktif: Kec. ${_gpsKecamatan ?? ''}'
                                              : 'Gunakan Lokasi Saat Ini (Maps/GPS)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: _useGpsLocation
                                                ? AppColors.primary
                                                : AppColors.textPrimaryFor(context),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _useGpsLocation
                                              ? 'LPK terdekat akan diprioritaskan otomatis.'
                                              : 'Cari & rekomendasikan LPK terdekat dari posisi Anda.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _useGpsLocation ? AppColors.primary : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: _useGpsLocation ? 1.0 : 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      _useGpsLocation ? 'Ganti' : 'Aktifkan',
                                      style: TextStyle(
                                        color: _useGpsLocation ? Colors.white : AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Search
                  AppInputField(
                    label: 'Cari kecamatan manual',
                    prefixIcon: Icons.search,
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Kecamatan Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filteredKecamatan.map((kecamatan) {
                      final isSelected = _selectedKecamatan == kecamatan;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedKecamatan = isSelected ? null : kecamatan;
                            if (isSelected) {
                              _useGpsLocation = false;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: AppAnimations.fast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: AppShapes.chipRadius,
                            border: isSelected
                                ? null
                                : Border.all(color: AppColors.outline),
                          ),
                          child: Text(
                            kecamatan,
                            style: AppTypography.labelMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Category Section
                  Text('Kategori', style: AppTypography.titleSmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCategories.remove(category);
                            } else {
                              _selectedCategories.add(category);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: AppAnimations.fast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: AppShapes.chipRadius,
                            border: isSelected
                                ? null
                                : Border.all(color: AppColors.outline),
                          ),
                          child: Text(
                            category,
                            style: AppTypography.labelMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Distance Section
                  Row(
                    children: [
                      Text('Jarak Maksimal', style: AppTypography.titleSmall),
                      const Spacer(),
                      Text(
                        '${_maxDistance.toInt()} km',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.outline,
                    onChanged: (value) {
                      setState(() => _maxDistance = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  // Price Range Section
                  Row(
                    children: [
                      Text('Rentang Harga', style: AppTypography.titleSmall),
                      const Spacer(),
                      Text(
                        '${_formatPrice(_priceRange.start)} - ${_formatPrice(_priceRange.end)}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 10000000,
                    divisions: 100,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.outline,
                    onChanged: (values) {
                      setState(() => _priceRange = values);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Apply Button
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: AnimatedPrimaryButton(
              text: 'Terapkan Filter',
              onPressed: _apply,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterResult {
  final String? kecamatan;
  final List<String> categories;
  final RangeValues priceRange;
  final double maxDistance;
  final bool useGpsLocation;
  final double? userLat;
  final double? userLng;

  const FilterResult({
    this.kecamatan,
    required this.categories,
    required this.priceRange,
    required this.maxDistance,
    this.useGpsLocation = false,
    this.userLat,
    this.userLng,
  });
}

/// Indramayu Kecamatan list
class IndramayuKecamatan {
  static const List<String> list = [
    'Semua',
    'Anjatan',
    'Arahan',
    'Balongan',
    'Bangodua',
    'Bongas',
    'Cantigi',
    'Cikedung',
    'Gabuswetan',
    'Gantar',
    'Haurgeulis',
    'Indramayu',
    'Jatibarang',
    'Juntinyuat',
    'Kandanghaur',
    'Karangampel',
    'Kedokanbunder',
    'Kertasemaya',
    'Krangkeng',
    'Kroya',
    'Lelea',
    'Lohbener',
    'Losarang',
    'Pasekan',
    'Patrol',
    'Sindang',
    'Sliyeg',
    'Sukagumiwang',
    'Sukra',
    'Terisi',
    'Tukdana',
    'Widasari',
  ];
}
