import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/widgets/molecules/empty_state.dart';

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
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      }
    });
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
          _upcoming = all.where((e) {
            final s = (e['status'] ?? '').toString().toLowerCase();
            final bs = (e['booking_status'] ?? '').toString().toLowerCase();
            return s == 'upcoming' ||
                s == 'pending' ||
                s == 'pending_payment' ||
                s == 'menunggu' ||
                bs.contains('upcoming') ||
                bs.contains('pending');
          }).toList();

          _ongoing = all.where((e) {
            final s = (e['status'] ?? '').toString().toLowerCase();
            final bs = (e['booking_status'] ?? '').toString().toLowerCase();
            return s == 'ongoing' ||
                s == 'confirmed' ||
                s == 'approved' ||
                s == 'paid' ||
                s == 'lunas' ||
                s == 'berjalan' ||
                s == 'active' ||
                bs.contains('ongoing') ||
                bs.contains('confirmed') ||
                bs.contains('paid');
          }).toList();

          _completed = all.where((e) {
            final s = (e['status'] ?? '').toString().toLowerCase();
            final bs = (e['booking_status'] ?? '').toString().toLowerCase();
            return s == 'completed' || s == 'selesai' || bs.contains('completed');
          }).toList();

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
    switch (type) {
      case 'ongoing':
        return AppEmptyState.courses(
          title: 'Tidak ada kursus yang sedang berjalan',
          message: 'Kursus aktif akan muncul di sini setelah pendaftaran dikonfirmasi oleh LPK.',
          actionLabel: 'Cari Kursus Baru',
          onExplore: () => context.go(AppRouter.home),
        );
      case 'completed':
        return AppEmptyState.completed(
          title: 'Belum ada kursus yang selesai',
          message: 'Selesaikan modul kursusmu untuk membuka sertifikat kompetensi resmi.',
          onExplore: () {
            _tabController.animateTo(1);
          },
        );
      case 'upcoming':
      default:
        return AppEmptyState.courses(
          title: 'Belum ada kursus yang akan datang',
          message: 'Temukan pelatihan vokasi yang sesuai minatmu dan lakukan booking sekarang.',
          actionLabel: 'Eksplor Kursus',
          onExplore: () => context.go(AppRouter.home),
        );
    }
  }

  Widget _buildError() {
    return AppEmptyState.error(
      title: 'Gagal Memuat Data',
      message: _error ?? 'Terjadi kendala saat menghubungkan ke server. Silakan coba lagi.',
      onRetry: _loadMyCourses,
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
    String rawImg = '';
    if (course['images'] != null) {
      final imgs = course['images'];
      if (imgs is List && imgs.isNotEmpty) {
        rawImg = imgs[0].toString();
      } else if (imgs is String && imgs.isNotEmpty) {
        rawImg = imgs;
      }
    }
    if (rawImg.isEmpty) {
      rawImg = (course['course_image'] ??
              course['image'] ??
              course['image_url'] ??
              course['thumbnail'] ??
              '')
          .toString();
    }
    final imageUrl = ApiService.toFullUrl(rawImg);
    final bookingId =
        course['booking_id']?.toString() ?? course['id']?.toString() ?? '';
    final courseId = (course['course_id'] ??
            course['course']?['id'] ??
            (type != 'upcoming' ? course['id'] : null) ??
            '')
        .toString();

    String cleanDate(String? raw) {
      if (raw == null || raw.isEmpty) return '';
      if (raw.contains('T')) {
        try {
          final dt = DateTime.parse(raw);
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
            'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
          ];
          return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
        } catch (_) {
          return raw.split('T').first;
        }
      }
      return raw;
    }

    final cleanStart = cleanDate(startDate);
    final cleanEnd = cleanDate(endDate);
    final dateRangeText = (cleanStart.isNotEmpty && cleanEnd.isNotEmpty)
        ? '$cleanStart – $cleanEnd'
        : cleanStart.isNotEmpty
            ? cleanStart
            : cleanEnd;

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
          HapticFeedback.lightImpact();
          if ((type == 'ongoing' || type == 'completed') &&
              courseId.isNotEmpty) {
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
                    child: Hero(
                      tag: '${AppAnimations.heroTagCourse}$courseId',
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 64,
                            height: 64,
                            memCacheWidth: 150,
                            memCacheHeight: 150,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                const _PlaceholderImage(size: 64),
                            errorWidget: (_, __, ___) =>
                                const _PlaceholderImage(size: 64),
                          )
                        : const _PlaceholderImage(size: 64),
                      ),
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
                      color: statusColor.withValues(alpha: 0.12),
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
              // Interactive Progress Bar untuk Kursus Berjalan
              if (type == 'ongoing') ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.outline),
                const SizedBox(height: 10),
                () {
                  final rawProg = course['progress'];
                  final double progressVal = (double.tryParse((rawProg ?? '0').toString()) ?? 0.0).clamp(0.0, 100.0);
                  final int percent = progressVal > 0 ? progressVal.toInt() : 40;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            percent >= 80 ? Icons.verified_rounded : Icons.trending_up_rounded,
                            size: 14,
                            color: percent >= 80 ? AppColors.success : AppColors.secondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Progres Belajar',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$percent% Selesai',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: percent / 100.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                value >= 0.8
                                    ? AppColors.success
                                    : (value >= 0.4 ? AppColors.primary : AppColors.secondary),
                              ),
                              minHeight: 6,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }(),
              ],
              if (dateRangeText.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.outline),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dateRangeText,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (type == 'completed') ...[
                      const Icon(Icons.workspace_premium_outlined,
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
