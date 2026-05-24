import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/widgets/molecules/course_card.dart';
import '../../../../core/navigation/app_router.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchLpkDetail();
  }

  Future<void> _fetchLpkDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _api.getLpkDetail(widget.lpkId);
      if (!mounted) return;
      if (result['success']) {
        final raw = result['data'];
        // Handle format: { status, data: { lpk: {}, courses: [] } }
        final data = raw['data'] ?? raw;
        final lpkData = data['lpk'] ?? data;
        final coursesData = data['courses'] ?? lpkData['courses'] ?? [];
        setState(() {
          _lpk = lpkData is Map<String, dynamic> ? lpkData : null;
          _courses = coursesData is List ? coursesData : [];
          _isLoading = false;
        });
      } else {
        setState(() { _error = result['message']; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
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
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _fetchLpkDetail,
                  child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final name = _lpk!['name'] ?? '-';
    final address = _lpk!['address'] ?? '-';
    final phone = (_lpk!['phone'] ?? '').toString();
    final whatsapp = (_lpk!['whatsapp'] ?? phone).toString();
    final rating = (_lpk!['rating'] ?? 0).toString();
    final ratingCount = (_lpk!['rating_count'] ?? 0).toString();
    final alumniCount = (_lpk!['alumni_count'] ?? 0).toString();
    final isVerified = _lpk!['is_verified'] ?? false;
    final coverUrl = (_lpk!['cover_url'] ?? _lpk!['cover'] ?? '').toString();
    final logoUrl = (_lpk!['logo_url'] ?? _lpk!['logo'] ?? '').toString();
    final facilities = List<String>.from(_lpk!['facilities'] ?? []);
    final lat = (_lpk!['latitude'] ?? '-6.3279').toString();
    final lng = (_lpk!['longitude'] ?? '108.3265').toString();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover
                  coverUrl.isNotEmpty
                      ? Hero(
                          tag: '${AppAnimations.heroTagLPK}${widget.lpkId}',
                          child: Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary,
                              child: const Icon(Icons.business,
                                  size: 60, color: Colors.white),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.primary,
                          child: const Icon(Icons.business,
                              size: 60, color: Colors.white),
                        ),
                  // Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7)
                        ],
                      ),
                    ),
                  ),
                  // Info LPK di bawah
                  Positioned(
                    left: 16, right: 16, bottom: 16,
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppShapes.borderRadiusMD,
                          ),
                          child: logoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: AppShapes.borderRadiusMD,
                                  child: Image.network(logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.business,
                                          color: AppColors.textTertiary,
                                          size: 32)),
                                )
                              : const Icon(Icons.business,
                                  color: AppColors.textTertiary, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(name,
                                  style: AppTypography.titleLarge
                                      .copyWith(color: Colors.white)),
                              const SizedBox(height: 4),
                              if (isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: AppShapes.chipRadius,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified,
                                          color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text('Terverifikasi Dinas',
                                          style: AppTypography.badge
                                              .copyWith(color: Colors.white)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  Row(
                    children: [
                      _buildStat(rating, 'Rating'),
                      const SizedBox(width: 24),
                      _buildStat(ratingCount, 'Ulasan'),
                      const SizedBox(width: 24),
                      _buildStat('$alumniCount+', 'Alumni'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Alamat
                  Text('Alamat', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppShapes.borderRadiusMD,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(address,
                                style: AppTypography.bodyMedium)),
                        IconButton(
                          icon: const Icon(Icons.directions),
                          color: AppColors.primary,
                          onPressed: () => _openMaps(lat, lng),
                        ),
                      ],
                    ),
                  ),

                  if (facilities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Fasilitas', style: AppTypography.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: facilities
                          .map((f) => _buildFacilityChip(_facilityIcon(f), f))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Kursus
                  Row(
                    children: [
                      Text('Kursus Tersedia',
                          style: AppTypography.titleMedium),
                      const Spacer(),
                      TextButton(
                          onPressed: () {},
                          child: const Text('Lihat Semua')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_courses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Belum ada kursus tersedia',
                            style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 280,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 16),
                        itemCount: _courses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final course = _courses[index];
                          final courseId =
                              course['id']?.toString() ?? '$index';
                          final courseTitle = course['name'] ??
                              course['title'] ??
                              'Kursus';
                          final courseImage = course['image_url'] ??
                              course['image'] ??
                              '';
                          final courseRating =
                              (course['rating'] ?? 0).toDouble();
                          final courseReviews =
                              course['rating_count'] ?? 0;
                          final coursePrice =
                              (course['price'] ?? 0).toDouble();
                          final courseCategory =
                              course['category'] ?? '';

                          return SizedBox(
                            width: 180,
                            child: CourseCard(
                              id: courseId,
                              title: courseTitle,
                              lpkName: name,
                              imageUrl: courseImage,
                              rating: courseRating,
                              reviewCount: courseReviews,
                              distanceKm: 0,
                              price: coursePrice,
                              category: courseCategory,
                              onTap: () => context.push(
                                  '${AppRouter.courseDetail}$courseId'),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildContactSheet(context, phone, whatsapp, name),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTypography.headlineSmall),
        Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildFacilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }

  IconData _facilityIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('parkir')) return Icons.local_parking;
    if (n.contains('ac')) return Icons.ac_unit;
    if (n.contains('wifi')) return Icons.wifi;
    if (n.contains('kantin')) return Icons.restaurant;
    if (n.contains('toilet') || n.contains('wc')) return Icons.wc;
    if (n.contains('musholla') || n.contains('masjid')) return Icons.mosque;
    return Icons.check_circle_outline;
  }

  Widget _buildContactSheet(
      BuildContext context, String phone, String wa, String lpkName) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: phone.isNotEmpty ? () => _callPhone(phone) : null,
              icon: const Icon(Icons.phone),
              label: const Text('Telepon'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  wa.isNotEmpty ? () => _openWhatsApp(wa, lpkName) : null,
              icon: const Icon(Icons.message),
              label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMaps(String lat, String lng) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _callPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _openWhatsApp(String phone, String lpkName) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final wa =
        clean.startsWith('0') ? '62${clean.substring(1)}' : clean;
    final msg =
        Uri.encodeFull('Halo, saya tertarik dengan kursus di $lpkName');
    final url = Uri.parse('https://wa.me/$wa?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}