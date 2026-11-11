import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/molecules/empty_state.dart';
import '../../../../core/widgets/atoms/skilloka_loader.dart';

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
  Set<String> _completedModuleIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      }
    });
    _loadData();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('completed_modules_${widget.courseId}') ?? [];
      if (mounted) {
        setState(() {
          _completedModuleIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleModuleCompletion(String moduleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      HapticFeedback.mediumImpact();
      setState(() {
        if (_completedModuleIds.contains(moduleId)) {
          _completedModuleIds.remove(moduleId);
        } else {
          _completedModuleIds.add(moduleId);
        }
      });
      await prefs.setStringList(
        'completed_modules_${widget.courseId}',
        _completedModuleIds.toList(),
      );
    } catch (_) {}
  }

  Widget _buildProgressCard() {
    final total = _contents.length;
    final completed = _completedModuleIds.length;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (percent == 100 ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    percent == 100
                        ? Icons.emoji_events_rounded
                        : Icons.local_fire_department_rounded,
                    color: percent == 100 ? AppColors.success : AppColors.secondary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      percent == 100
                          ? 'Semua Modul Tuntas! 🎉'
                          : (percent > 0 ? 'Progres Belajar Aktif' : 'Mulai Langkah Belajar'),
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completed dari $total materi diselesaikan',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: percent == 100 ? AppColors.success : AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    value >= 1.0
                        ? AppColors.success
                        : (value >= 0.5 ? AppColors.primary : AppColors.secondary),
                  ),
                  minHeight: 8,
                );
              },
            ),
          ),
        ],
      ),
    );
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
          ? const SkillokaLoading.inline(
              message: 'Menyiapkan modul pembelajaran & silabus...',
            )
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
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: _buildEmpty(
              icon: Icons.library_books_outlined,
              title: 'Belum ada materi',
              subtitle: 'Instruktur belum menambahkan materi untuk kursus ini. Tarik ke bawah untuk memuat ulang.',
            ),
          ),
        ),
      );
    }
    final bool hasUnlocked = _contents.any((c) => c['is_locked'] != true);
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _contents.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) {
            return _buildProgressCard();
          }
          if (i == 1) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (hasUnlocked ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (hasUnlocked ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasUnlocked
                        ? Icons.verified_user_outlined
                        : Icons.lock_outline,
                    size: 18,
                    color: hasUnlocked ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasUnlocked
                          ? 'Langganan Aktif • Akses penuh materi & modul digital'
                          : 'Materi terbuka bagi peserta terdaftar dengan paket langganan aktif',
                      style: AppTypography.bodySmall.copyWith(
                        color: hasUnlocked
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final item = _contents[i - 2];
          final title = item['title']?.toString() ?? 'Materi ${i - 1}';
          final type = item['type']?.toString() ?? 'document';
          final isLocked = item['is_locked'] == true;
          final moduleId = item['id']?.toString() ?? 'mod_${i - 2}';
          final isCompleted = _completedModuleIds.contains(moduleId);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.5)
                    : AppColors.outline,
                width: isCompleted ? 1.2 : 1.0,
              ),
            ),
            color: AppColors.surface,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isLocked
                      ? AppColors.surfaceVariant
                      : (isCompleted
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLocked
                      ? Icons.lock_outline
                      : (isCompleted
                          ? Icons.check_circle_rounded
                          : _contentIcon(type)),
                  size: 20,
                  color: isLocked
                      ? AppColors.textTertiary
                      : (isCompleted ? AppColors.success : AppColors.primary),
                ),
              ),
              title: Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: isLocked ? AppColors.textTertiary : AppColors.textPrimary,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                _contentTypeLabel(type),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: isLocked
                  ? const Icon(Icons.lock_outline,
                      color: AppColors.textTertiary, size: 20)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isCompleted
                                ? AppColors.success
                                : AppColors.textTertiary,
                            size: 22,
                          ),
                          onPressed: () => _toggleModuleCompletion(moduleId),
                          tooltip: isCompleted
                              ? 'Tandai belum selesai'
                              : 'Tandai selesai',
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
              onTap: () {
                HapticFeedback.lightImpact();
                if (isLocked) {
                  _showLockedDialog();
                } else {
                  _showMaterialDetail(item);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _showLockedDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppColors.warning, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Materi Khusus Langganan',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Akses materi digital, video pembelajaran, dan presensi absensi terbuka otomatis untuk peserta dengan paket Langganan Aktif Skilloka.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMaterialDetail(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'Materi Pembelajaran';
    final desc = item['content']?.toString() ??
        item['body']?.toString() ??
        item['description']?.toString() ??
        'Silakan pelajari materi berikut sesuai panduan dan arahan instruktur LPK.';
    final type = (item['type']?.toString() ?? 'document').toLowerCase();
    final rawUrl = item['url']?.toString() ??
        item['content_url']?.toString() ??
        item['file_url']?.toString() ??
        item['file_path']?.toString();
    final url = (rawUrl != null && rawUrl.isNotEmpty) ? ApiService.toFullUrl(rawUrl) : null;
    final isPdf = type == 'document' ||
        type == 'pdf' ||
        (url != null && url.toLowerCase().contains('.pdf'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_contentIcon(type), color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _contentTypeLabel(type),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.outline),

                  // Content Body
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // Title
                        Text(
                          title,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Video Player Card (If video)
                        if (type == 'video') ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Video Pembelajaran & Peragaan Praktik',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Durasi video ± 25 Menit • Kualitas HD',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (url != null && url.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final uri = Uri.parse(url);
                                      try {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } catch (_) {}
                                    },
                                    icon: const Icon(Icons.play_circle_filled, size: 18),
                                    label: const Text('Tonton Video Sekarang'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Document PDF Banner (If PDF / URL exists)
                        if (isPdf && url != null && url.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Modul PDF Resmi Tersedia', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('Dapat dibaca langsung atau diunduh', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(url);
                                    try {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } catch (_) {}
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('Buka PDF'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Structured Content Reader
                        _buildFormattedContent(desc),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Bottom Action
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.outline)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Builder(
                        builder: (context) {
                          final modId = item['id']?.toString() ?? '';
                          final isDone = _completedModuleIds.contains(modId);
                          return FilledButton.icon(
                            onPressed: () {
                              if (modId.isNotEmpty && !isDone) {
                                _toggleModuleCompletion(modId);
                              }
                              Navigator.pop(context);
                            },
                            icon: Icon(isDone
                                ? Icons.check_circle_rounded
                                : Icons.check_circle_outline_rounded),
                            label: Text(isDone
                                ? 'Selesai Dibaca ✓'
                                : 'Tandai Selesai & Lanjut'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  isDone ? AppColors.success : AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Parser sederhana untuk menampilkan materi terstruktur dengan tampilan modern
  Widget _buildFormattedContent(String rawText) {
    final lines = rawText.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            line.replaceFirst('## ', ''),
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            line.replaceFirst('### ', ''),
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle, size: 6, color: AppColors.primary),
              ),
              Expanded(
                child: Text(
                  line.replaceFirst('- ', ''),
                  style: AppTypography.bodyMedium.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendances.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available_outlined, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Presensi Sesi Belum Dimulai',
                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pendaftaran pelatihan Anda telah terkonfirmasi resmi. Presensi kehadiran akan dicatat oleh instruktur LPK saat jadwal sesi kelas tatap muka atau praktik dimulai.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.successContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pendaftaran Lunas • Akses Langganan Aktif',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Tarik ke bawah untuk memuat ulang data presensi',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    // Count present/absent
    final presentCount = _attendances.where((a) {
      final s = (a['status'] ?? '').toString().toLowerCase();
      return s == 'present' || s == 'hadir' || a['is_present'] == true;
    }).length;
    final totalCount = _attendances.length;
    final percentage = totalCount > 0
        ? (presentCount / totalCount * 100).toStringAsFixed(0)
        : '0';

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            final sessionName = a['session_name']?.toString() ?? 'Sesi Pelatihan';
            final date = a['session_date']?.toString() ?? a['date']?.toString() ?? '-';
            final statusRaw = (a['status'] ?? '').toString().toLowerCase();
            final notes = a['notes']?.toString();

            Color statusColor;
            Color statusBg;
            String statusLabel;
            IconData statusIcon;

            if (statusRaw == 'present' || statusRaw == 'hadir' || a['is_present'] == true) {
              statusColor = AppColors.success;
              statusBg = AppColors.successContainer;
              statusLabel = 'Hadir';
              statusIcon = Icons.check_circle;
            } else if (statusRaw == 'sick' || statusRaw == 'sakit') {
              statusColor = AppColors.warning;
              statusBg = AppColors.warning.withValues(alpha: 0.12);
              statusLabel = 'Sakit';
              statusIcon = Icons.healing_outlined;
            } else if (statusRaw == 'excused' || statusRaw == 'izin') {
              statusColor = AppColors.primary;
              statusBg = AppColors.primaryContainer;
              statusLabel = 'Izin';
              statusIcon = Icons.info_outline;
            } else {
              statusColor = AppColors.error;
              statusBg = AppColors.error.withValues(alpha: 0.12);
              statusLabel = 'Alpa';
              statusIcon = Icons.cancel_outlined;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, size: 20, color: statusColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sessionName, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(date, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (notes != null && notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Catatan Instruktur: $notes',
                        style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCertificateTab() {
    if (_certificate == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_outlined, size: 40, color: AppColors.warning),
              ),
              const SizedBox(height: 20),
              Text(
                'Sertifikat Belum Diterbitkan',
                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sertifikat resmi kompetensi (BNSP & Disnaker) akan diterbitkan oleh Admin LPK setelah Anda menyelesaikan seluruh rangkaian sesi pelatihan dan evaluasi kelulusan.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  children: [
                    _buildStepRow(1, 'Pendaftaran & Pembayaran Pelatihan', true),
                    const SizedBox(height: 12),
                    _buildStepRow(2, 'Mengikuti Seluruh Sesi Materi & Presensi', false, isCurrent: true),
                    const SizedBox(height: 12),
                    _buildStepRow(3, 'Evaluasi Akhir & Penerbitan Sertifikat LPK', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final certUrl = _certificate!['file_url']?.toString() ??
        _certificate!['url']?.toString();
    final certNo = _certificate!['certificate_number']?.toString() ??
        _certificate!['number']?.toString() ?? '-';
    final issuedAt = _certificate!['issued_at']?.toString() ??
        _certificate!['created_at']?.toString() ?? '-';

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium,
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
                  onPressed: () async {
                    final uri = Uri.parse(certUrl);
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {}
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
      ),
    );
  }

  Widget _buildStepRow(int step, String title, bool isDone, {bool isCurrent = false}) {
    Color bg;
    Widget icon;

    if (isDone) {
      bg = AppColors.successContainer;
      icon = const Icon(Icons.check, size: 14, color: AppColors.success);
    } else if (isCurrent) {
      bg = AppColors.primaryContainer;
      icon = Text('$step', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary));
    } else {
      bg = AppColors.surfaceVariant;
      icon = Text('$step', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textTertiary));
    }

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: icon,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return AppEmptyState(
      customIcon: icon,
      title: title,
      message: subtitle,
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
