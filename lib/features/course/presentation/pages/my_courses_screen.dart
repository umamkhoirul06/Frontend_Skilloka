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
import '../../../../core/error/exceptions.dart';

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
          _ongoing = all.where((e) {
            final s = (e['status'] ?? '').toString().toLowerCase();
            final bs = (e['booking_status'] ?? '').toString().toLowerCase();
            final sb = (e['status_belajar'] ?? '').toString().toLowerCase();
            final ps = (e['payment_status'] ?? '').toString().toLowerCase();
            return s == 'ongoing' ||
                s == 'confirmed' ||
                s == 'approved' ||
                s == 'paid' ||
                s == 'lunas' ||
                s == 'berjalan' ||
                s == 'active' ||
                bs == 'confirmed' ||
                bs == 'approved' ||
                bs == 'paid' ||
                ps == 'success' ||
                ps == 'paid' ||
                sb == 'sedang_belajar';
          }).toList();

          _completed = all.where((e) {
            final s = (e['status'] ?? '').toString().toLowerCase();
            final bs = (e['booking_status'] ?? '').toString().toLowerCase();
            final sb = (e['status_belajar'] ?? '').toString().toLowerCase();
            return s == 'completed' || s == 'selesai' || bs.contains('completed') || sb == 'selesai_belajar';
          }).toList();

          final ongoingIds = _ongoing.map((e) => e['id']?.toString()).toSet();
          final completedIds = _completed.map((e) => e['id']?.toString()).toSet();

          _upcoming = all.where((e) {
            final id = e['id']?.toString();
            if (ongoingIds.contains(id) || completedIds.contains(id)) return false;
            final s = (e['status'] ?? '').toString().toLowerCase();
            final bs = (e['booking_status'] ?? '').toString().toLowerCase();
            final ps = (e['payment_status'] ?? '').toString().toLowerCase();
            if (ps == 'success' || ps == 'paid') return false;
            return s == 'upcoming' ||
                s == 'pending' ||
                s == 'pending_payment' ||
                s == 'menunggu' ||
                bs.contains('upcoming') ||
                bs.contains('pending') ||
                bs.contains('menunggu');
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
        _error = AppExceptionHandler.getFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kursus Saya',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Pantau progres pelatihan & sertifikatmu',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            Tab(text: 'Mendatang (${_upcoming.length})'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData icon = Icons.calendar_today_rounded;
    String title = 'Belum Ada Kursus Terdaftar';
    String message =
        'Temukan pelatihan vokasi resmi Indramayu dan mulai tingkatkan kompetensimu!';
    String actionText = 'Jelajahi Kursus Vokasi';
    VoidCallback onAction = () => context.push(AppRouter.search);

    if (type == 'ongoing') {
      icon = Icons.play_circle_fill_rounded;
      title = 'Tidak Ada Kursus Berjalan';
      message =
          'Kursus aktif akan muncul di sini setelah jadwal pelatihan dimulai oleh LPK.';
      actionText = 'Lihat Katalog Pelatihan';
    } else if (type == 'completed') {
      icon = Icons.workspace_premium_rounded;
      title = 'Belum Ada Kursus Selesai';
      message =
          'Selesaikan seluruh materi pelatihan untuk mengunduh sertifikat resmi kompetensi Anda.';
      actionText = 'Cek Kursus Berjalan';
      onAction = () => _tabController.animateTo(1);
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAction();
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  actionText,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return AppEmptyState.error(
      title: 'Gagal Memuat Data',
      message: _error ??
          'Terjadi kendala saat menghubungkan ke server. Silakan coba lagi.',
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Hero(
                        tag: '${AppAnimations.heroTagCourse}$courseId',
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 70,
                                height: 70,
                                memCacheWidth: 200,
                                memCacheHeight: 200,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const _PlaceholderImage(size: 70),
                                errorWidget: (_, __, ___) =>
                                    const _PlaceholderImage(size: 70),
                              )
                            : const _PlaceholderImage(size: 70),
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
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lpkName,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF10B981),
                                size: 13,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                // Interactive Progress Bar untuk Kursus Berjalan
                if (type == 'ongoing') ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 10),
                  () {
                    final rawProg = course['progress'];
                    final double progressVal =
                        (double.tryParse((rawProg ?? '0').toString()) ?? 0.0)
                            .clamp(0.0, 100.0);
                    final int percent = progressVal.toInt();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Progres Materi',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF334155),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$percent% Selesai',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent / 100.0,
                            backgroundColor: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    );
                  }(),
                ],
                if (dateRangeText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateRangeText,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (type == 'completed') ...[
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Sertifikat Siap',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ] else if (type == 'ongoing') ...[
                        const Text(
                          'Lanjut Belajar ➔',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
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
