import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/navigation/app_router.dart';

/// Course Learning Screen - akses materi, absensi, sertifikat PRD 8.8
class CourseLearningScreen extends StatefulWidget {
  final String courseId;
  const CourseLearningScreen({super.key, required this.courseId});

  @override
  State<CourseLearningScreen> createState() => _CourseLearningScreenState();
}

class _CourseLearningScreenState extends State<CourseLearningScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _contents = [];
  List<Map<String, dynamic>> _attendances = [];
  Map<String, dynamic>? _certificate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _api.getCourseContent(widget.courseId),
        _api.getCourseAttendance(widget.courseId),
        _api.getCourseCertificate(widget.courseId),
      ]);

      if (!mounted) return;

      // Content
      final contentResult = futures[0];
      if (contentResult['success'] == true) {
        final data = contentResult['data'];
        List<dynamic> rawList = data is List ? data : (data['data'] ?? []);
        _contents = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      // Attendance
      final attendResult = futures[1];
      if (attendResult['success'] == true) {
        final data = attendResult['data'];
        List<dynamic> rawList = data is List ? data : (data['data'] ?? []);
        _attendances = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      // Certificate
      final certResult = futures[2];
      if (certResult['success'] == true) {
        _certificate = certResult['data'] is Map
            ? Map<String, dynamic>.from(certResult['data'] as Map)
            : null;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Detail Kursus', style: AppTypography.titleLarge),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.labelMedium
              .copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Materi'),
            Tab(text: 'Absensi'),
            Tab(text: 'Sertifikat'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContentTab(),
                _buildAttendanceTab(),
                _buildCertificateTab(),
              ],
            ),
    );
  }

  Widget _buildContentTab() {
    if (_contents.isEmpty) {
      return _buildEmpty(
        icon: Icons.library_books_outlined,
        title: 'Belum ada materi',
        subtitle: 'Instruktur belum menambahkan materi untuk kursus ini.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _contents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = _contents[i];
        final title = item['title']?.toString() ?? 'Materi ${i + 1}';
        final type = item['type']?.toString() ?? 'document';
        final isLocked = item['is_locked'] == true;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.outline),
          ),
          color: AppColors.surface,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLocked
                    ? AppColors.surfaceVariant
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isLocked
                    ? Icons.lock_outline
                    : _contentIcon(type),
                size: 20,
                color: isLocked ? AppColors.textTertiary : AppColors.primary,
              ),
            ),
            title: Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: isLocked ? AppColors.textTertiary : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _contentTypeLabel(type),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: isLocked
                ? null
                : const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
            onTap: isLocked ? null : () {},
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendances.isEmpty) {
      return _buildEmpty(
        icon: Icons.fact_check_outlined,
        title: 'Belum ada data absensi',
        subtitle: 'Absensi akan tercatat oleh instruktur setiap sesi pelatihan.',
      );
    }

    // Count present/absent
    final presentCount = _attendances.where((a) =>
        (a['status'] ?? '').toString().toLowerCase() == 'present' ||
        (a['is_present'] == true)).length;
    final totalCount = _attendances.length;
    final percentage = totalCount > 0
        ? (presentCount / totalCount * 100).toStringAsFixed(0)
        : '0';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kehadiran', style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    )),
                    const SizedBox(height: 4),
                    Text(
                      '$presentCount / $totalCount sesi',
                      style: AppTypography.titleLarge,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: totalCount > 0 ? presentCount / totalCount : 0,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(
                        double.parse(percentage) >= 80
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      strokeWidth: 6,
                    ),
                    Text(
                      '$percentage%',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._attendances.map((a) {
          final date = a['session_date']?.toString() ?? a['date']?.toString() ?? '-';
          final isPresent = (a['status'] ?? '').toString().toLowerCase() ==
                  'present' ||
              a['is_present'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                Icon(
                  isPresent ? Icons.check_circle : Icons.cancel_outlined,
                  size: 20,
                  color: isPresent ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 12),
                Text(date, style: AppTypography.bodyMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isPresent ? AppColors.success : AppColors.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPresent ? 'Hadir' : 'Tidak Hadir',
                    style: AppTypography.labelSmall.copyWith(
                      color: isPresent ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCertificateTab() {
    if (_certificate == null) {
      return _buildEmpty(
        icon: Icons.workspace_premium_outlined,
        title: 'Sertifikat belum tersedia',
        subtitle:
            'Sertifikat akan diterbitkan oleh instruktur setelah kursus selesai dan kehadiran memenuhi syarat.',
      );
    }

    final certUrl = _certificate!['file_url']?.toString() ??
        _certificate!['url']?.toString();
    final certNo = _certificate!['certificate_number']?.toString() ??
        _certificate!['number']?.toString() ?? '-';
    final issuedAt = _certificate!['issued_at']?.toString() ??
        _certificate!['created_at']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.workspace_premium,
                    size: 64, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Sertifikat Pelatihan',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No. $certNo',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Diterbitkan: $issuedAt',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (certUrl != null && certUrl.isNotEmpty) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  // Download / view certificate
                },
                icon: const Icon(Icons.download),
                label: const Text('Unduh Sertifikat'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                AppRouter.courseReviewPath(widget.courseId),
              ),
              icon: const Icon(Icons.star_outline_rounded),
              label: const Text('Beri Ulasan Kursus'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(title,
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  IconData _contentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'pdf':
      case 'document':
        return Icons.picture_as_pdf_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'link':
        return Icons.link;
      default:
        return Icons.description_outlined;
    }
  }

  String _contentTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return 'Video';
      case 'pdf':
        return 'PDF';
      case 'document':
        return 'Dokumen';
      case 'quiz':
        return 'Kuis';
      case 'link':
        return 'Tautan';
      default:
        return 'Materi';
    }
  }
}
