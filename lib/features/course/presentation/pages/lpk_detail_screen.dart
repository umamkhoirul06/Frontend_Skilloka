import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/widgets/molecules/course_card.dart';
import '../../../../core/services/api_service.dart';

class LPKDetailScreen extends StatefulWidget {
  final String lpkId;
  const LPKDetailScreen({super.key, required this.lpkId});

  @override
  State<LPKDetailScreen> createState() => _LPKDetailScreenState();
}

class _LPKDetailScreenState extends State<LPKDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _lpk;
  List<dynamic> _courses = [];
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchLpkDetail();
  }

  Future<void> _fetchLpkDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.getLpkDetail(widget.lpkId);
      if (!mounted) return;
      if (result['success']) {
        final raw = result['data'];
        final data = raw['data'] ?? raw;
        final lpkData = data['lpk'] ?? data;
        final coursesData = data['courses'] ?? lpkData['courses'] ?? [];
        setState(() {
          _lpk = lpkData is Map<String, dynamic> ? lpkData : null;
          _courses = coursesData is List ? coursesData : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _lpk == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error ?? 'Data tidak ditemukan',
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      );
    }

    // --- DATA MAPPING ---
    final name = _lpk!['name'] ?? '-';
    final address = _lpk!['address'] ?? '-';
    final phone = (_lpk!['phone'] ?? '').toString();
    final whatsapp = (_lpk!['whatsapp'] ?? phone).toString();
    final rating = (_lpk!['rating'] ?? 0).toString();
    final ratingCount = (_lpk!['rating_count'] ?? 0).toString();
    final alumniCount = (_lpk!['alumni_count'] ?? 0).toString();
    final isVerified = _lpk!['is_verified'] ?? false;
    final coverUrl =
        ApiService.toFullUrl(_lpk!['cover_url'] ?? _lpk!['cover'] ?? '');
    final logoUrl =
        ApiService.toFullUrl(_lpk!['logo_url'] ?? _lpk!['logo'] ?? '');

    // 🔥 FIX UTAMA: Normalisasi Fasilitas agar tidak Crash jika String
    final rawFacilities = _lpk!['facilities'];
    List<String> facilities = [];
    if (rawFacilities is List) {
      facilities = List<String>.from(rawFacilities.map((e) => e.toString()));
    } else if (rawFacilities is String) {
      facilities = [rawFacilities];
    }

    // 🔥 FIX GALERI: Ambil dari list atau cover
    final rawImages = _lpk!['images'];
    List<String> galleryImages = [];
    if (rawImages is List && rawImages.isNotEmpty) {
      galleryImages =
          rawImages.map((e) => ApiService.toFullUrl(e.toString())).toList();
    } else if (coverUrl.isNotEmpty) {
      galleryImages = [coverUrl];
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                if (galleryImages.isNotEmpty)
                  PageView.builder(
                    itemCount: galleryImages.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => Image.network(galleryImages[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.primary)),
                  )
                else
                  Container(color: AppColors.primary),
                Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8)
                    ]))),
                Positioned(
                    left: 16,
                    bottom: 16,
                    right: 16,
                    child: Row(children: [
                      Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppShapes.borderRadiusMD),
                          child: ClipRRect(
                              borderRadius: AppShapes.borderRadiusMD,
                              child: Image.network(logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.business)))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(name,
                              style: AppTypography.titleLarge
                                  .copyWith(color: Colors.white)))
                    ]))
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _buildStat(rating, 'Rating'),
                      const SizedBox(width: 24),
                      _buildStat(alumniCount, 'Alumni')
                    ]),
                    const SizedBox(height: 24),
                    Text('Alamat', style: AppTypography.titleMedium),
                    Text(address, style: AppTypography.bodyMedium),
                    const SizedBox(height: 24),
                    if (facilities.isNotEmpty) ...[
                      Text('Fasilitas', style: AppTypography.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                          spacing: 8,
                          children: facilities
                              .map((f) =>
                                  _buildFacilityChip(_facilityIcon(f), f))
                              .toList())
                    ],
                    const SizedBox(height: 24),
                    Text('Kursus Tersedia', style: AppTypography.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                        height: 280,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _courses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, index) {
                            final c = _courses[index];
                            final courseId = c['id']?.toString() ?? '$index';

                            // 🔥 FIX 1: Prioritaskan 'title' karena Laravel mengirimnya sebagai 'title', bukan 'name'
                            final courseTitle =
                                c['title'] ?? c['name'] ?? 'Kursus';

                            // 🔥 FIX 2: Bongkar array 'images' dari Laravel untuk mengambil foto kursus
                            String rawCourseImg = '';
                            if (c['images'] != null &&
                                c['images'] is List &&
                                (c['images'] as List).isNotEmpty) {
                              rawCourseImg = c['images'][0]
                                  .toString(); // Ambil foto urutan pertama
                            } else {
                              rawCourseImg = c['image_url'] ?? c['image'] ?? '';
                            }

                            // 🔥 FIX 3: Ambil Kategori dengan aman (terkadang berbentuk Object/Map)
                            String categoryName = 'General';
                            if (c['category'] is Map) {
                              categoryName = c['category']['name'] ?? 'General';
                            } else if (c['category_name'] != null) {
                              categoryName = c['category_name'].toString();
                            }

                            return SizedBox(
                              width: 180,
                              child: CourseCard(
                                id: courseId,
                                title: courseTitle,
                                lpkName: name,
                                imageUrl: ApiService.toFullUrl(
                                    rawCourseImg), // Foto pasti muncul!
                                rating: (c['rating'] ?? 0).toDouble(),
                                reviewCount: c['rating_count'] ?? 0,
                                distanceKm: 0,
                                price: (c['price'] ?? 0).toInt(),
                                category: categoryName,
                                onTap: () => context.push('/course/$courseId'),
                              ),
                            );
                          },
                        )),
                    const SizedBox(height: 120),
                  ]),
            ),
          )
        ],
      ),
      bottomSheet: _buildContactSheet(context, phone, whatsapp, name),
    );
  }

  // --- Helper Widgets (TIDAK PERLU DIUBAH) ---
  Widget _buildStat(String value, String label) => Column(children: [
        Text(value, style: AppTypography.headlineSmall),
        Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary))
      ]);
  Widget _buildFacilityChip(IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.surfaceVariant, borderRadius: AppShapes.chipRadius),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelMedium)
      ]));
  IconData _facilityIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('parkir')) return Icons.local_parking;
    if (n.contains('ac')) return Icons.ac_unit;
    if (n.contains('wifi')) return Icons.wifi;
    return Icons.check_circle_outline;
  }

  Widget _buildContactSheet(
          BuildContext context, String phone, String wa, String lpkName) =>
      Container(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ]),
          child: Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed:
                        phone.isNotEmpty ? () => _callPhone(phone) : null,
                    icon: const Icon(Icons.phone),
                    label: const Text('Telepon'))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton.icon(
                    onPressed:
                        wa.isNotEmpty ? () => _openWhatsApp(wa, lpkName) : null,
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white)))
          ]));
  void _openMaps(String lat, String lng) async {
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _callPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _openWhatsApp(String phone, String lpkName) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final wa = clean.startsWith('0') ? '62${clean.substring(1)}' : clean;
    final msg = Uri.encodeFull('Halo, saya tertarik dengan kursus di $lpkName');
    final url = Uri.parse('https://wa.me/$wa?text=$msg');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
