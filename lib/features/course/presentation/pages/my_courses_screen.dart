import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/navigation/app_router.dart';

/// My Courses / Kursus Saya — PRD 8.8
/// Kategori: Akan datang | Sedang berjalan | Selesai
class MyCourseScreen extends StatefulWidget {
  const MyCourseScreen({super.key});

  @override
  State<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends State<MyCourseScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _ongoing = [];
  List<Map<String, dynamic>> _completed = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyCourses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.getMyCourses();
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'];
        List<dynamic> rawList = [];

        // Tangani berbagai format response
        if (data is List) {
          rawList = data;
        } else if (data is Map) {
          rawList = data['data'] ?? data['items'] ?? [];
        }

        final all = rawList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (!mounted) return;
        setState(() {
          _upcoming = all
              .where((e) =>
                  (e['status'] ?? '').toString().toLowerCase() == 'upcoming' ||
                  (e['status'] ?? '').toString().toLowerCase() ==
                      'pending_payment' ||
                  (e['booking_status'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains('upcoming'))
              .toList();

          _ongoing = all
              .where((e) =>
                  (e['status'] ?? '').toString().toLowerCase() == 'ongoing' ||
                  (e['status'] ?? '').toString().toLowerCase() ==
                      'confirmed' ||
                  (e['booking_status'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains('ongoing'))
              .toList();

          _completed = all
              .where((e) =>
                  (e['status'] ?? '').toString().toLowerCase() == 'completed' ||
                  (e['booking_status'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains('completed'))
              .toList();

          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = result['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Kursus Saya', style: AppTypography.titleLarge),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTypography.labelMedium,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Akan Datang (${_upcoming.length})'),
            Tab(text: 'Berjalan (${_ongoing.length})'),
            Tab(text: 'Selesai (${_completed.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCourseList(_upcoming, 'upcoming'),
                    _buildCourseList(_ongoing, 'ongoing'),
                    _buildCourseList(_completed, 'completed'),
                  ],
                ),
    );
  }

  Widget _buildCourseList(List<Map<String, dynamic>> courses, String type) {
    if (courses.isEmpty) {
      return _buildEmptyState(type);
    }
    return RefreshIndicator(
      onRefresh: _loadMyCourses,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _MyCourseCard(
          course: courses[i],
          type: type,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    final messages = {
      'upcoming': {
        'title': 'Belum ada kursus yang akan datang',
        'subtitle':
            'Temukan kursus yang sesuai minatmu dan lakukan booking sekarang.',
        'icon': Icons.event_outlined,
      },
      'ongoing': {
        'title': 'Tidak ada kursus yang sedang berjalan',
        'subtitle':
            'Kursus aktif akan muncul di sini setelah booking dikonfirmasi.',
        'icon': Icons.play_circle_outline,
      },
      'completed': {
        'title': 'Belum ada kursus yang selesai',
        'subtitle':
            'Kursus yang telah kamu selesaikan dan sertifikat akan tampil di sini.',
        'icon': Icons.check_circle_outline,
      },
    };
    final data = messages[type]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data['icon'] as IconData,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              data['title'] as String,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['subtitle'] as String,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (type != 'completed') ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(AppRouter.home),
                icon: const Icon(Icons.search),
                label: const Text('Cari Kursus'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            Text('Gagal Memuat Data', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadMyCourses,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }
}

class _MyCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final String type;

  const _MyCourseCard({required this.course, required this.type});

  @override
  Widget build(BuildContext context) {
    final title = (course['course_title'] ?? course['title'] ?? 'Kursus')
        .toString();
    final lpkName = (course['lpk_name'] ??
            (course['lpk'] is Map ? course['lpk']['name'] : null) ??
            'LPK')
        .toString();
    final startDate = course['start_date']?.toString() ??
        course['schedule_start']?.toString();
    final endDate = course['end_date']?.toString() ??
        course['schedule_end']?.toString();
    final imageUrl = ApiService.toFullUrl(
        course['course_image'] ?? course['image'] ?? course['image_url']);
    final bookingId = course['booking_id']?.toString() ?? course['id']?.toString() ?? '';
    final courseId = course['course_id']?.toString() ?? '';

    String statusLabel = '';
    Color statusColor = AppColors.info;
    switch (type) {
      case 'upcoming':
        statusLabel = 'Akan Datang';
        statusColor = AppColors.info;
        break;
      case 'ongoing':
        statusLabel = 'Sedang Berjalan';
        statusColor = AppColors.success;
        break;
      case 'completed':
        statusLabel = 'Selesai';
        statusColor = AppColors.textSecondary;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (type == 'ongoing' && courseId.isNotEmpty) {
            context.push(AppRouter.courseContentPath(courseId));
          } else if (type == 'upcoming' && bookingId.isNotEmpty) {
            context.push(AppRouter.pendingBookingPath(bookingId));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _PlaceholderImage(size: 64),
                          )
                        : _PlaceholderImage(size: 64),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (startDate != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.outline),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      endDate != null
                          ? '$startDate – $endDate'
                          : startDate,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (type == 'completed') ...[
                      Icon(Icons.workspace_premium_outlined,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Sertifikat',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (type == 'ongoing') ...[
                      Text(
                        'Lihat Materi →',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final double size;
  const _PlaceholderImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.school_outlined,
        size: size * 0.5,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14, color: AppColors.surfaceVariant,
                    margin: const EdgeInsets.only(right: 40)),
                const SizedBox(height: 8),
                Container(
                    height: 12,
                    width: 100,
                    color: AppColors.surfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
