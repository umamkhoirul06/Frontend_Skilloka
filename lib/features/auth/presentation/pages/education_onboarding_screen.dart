import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/api_service.dart';

/// Onboarding Pendidikan — PRD 8.3
/// Muncul setelah login pertama jika profil pendidikan belum lengkap
class EducationOnboardingScreen extends StatefulWidget {
  const EducationOnboardingScreen({super.key});

  @override
  State<EducationOnboardingScreen> createState() =>
      _EducationOnboardingScreenState();
}

class _EducationOnboardingScreenState
    extends State<EducationOnboardingScreen> {
  final ApiService _api = ApiService();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Jenjang
  String? _selectedLevel; // SMA | SMK | PERGURUAN_TINGGI

  // Step 2: Jurusan / Program Studi
  final _majorController = TextEditingController();

  // Step 3: Tujuan Pelatihan
  String? _selectedGoal;
  final List<String> _goals = [
    'Meningkatkan keahlian kerja',
    'Mempersiapkan kerja pertama',
    'Studi lanjut',
    'Bekerja di luar negeri',
    'Wirausaha / bisnis sendiri',
    'Pengembangan diri',
  ];

  // Step 4: Lokasi (opsional)
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _majorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedLevel == null || _majorController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final result = await _api.updateEducationProfile(
        educationLevel: _selectedLevel!,
        major: _majorController.text.trim(),
        careerGoal: _selectedGoal,
        preferredLocation: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          context.go(AppRouter.home);
        } else {
          // Jika gagal simpan ke backend, tetap lanjut ke home
          // (data disimpan lokal lewat SharedPreferences jika perlu)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal menyimpan profil pendidikan'),
              backgroundColor: AppColors.warning,
            ),
          );
          // Tetap lanjut ke home meski gagal simpan
          context.go(AppRouter.home);
        }
      }
    } catch (e) {
      if (mounted) {
        context.go(AppRouter.home);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _canProceedStep {
    switch (_currentStep) {
      case 0:
        return _selectedLevel != null;
      case 1:
        return _majorController.text.trim().isNotEmpty;
      case 2:
        return _selectedGoal != null;
      case 3:
        return true; // lokasi opsional
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_canProceedStep) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'Jenjang Pendidikan',
      'Bidang Keahlian',
      'Tujuan Pelatihan',
      'Lokasi Pilihan',
    ];
    final subtitles = [
      'Pilih jenjang pendidikan terakhirmu',
      'Isi jurusan atau program studimu',
      'Apa yang ingin kamu capai?',
      'Di mana kamu ingin belajar? (opsional)',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Langkah ${_currentStep + 1} dari 4',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRouter.home),
                child: Text(
                  'Lewati',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            titles[_currentStep],
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            subtitles[_currentStep],
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(4, (i) {
          final isCompleted = i < _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildLevelStep();
      case 1:
        return _buildMajorStep();
      case 2:
        return _buildGoalStep();
      case 3:
        return _buildLocationStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildLevelStep() {
    final levels = [
      {'value': 'SMA', 'label': 'SMA / MA', 'icon': Icons.school_outlined, 'desc': 'Sekolah Menengah Atas'},
      {'value': 'SMK', 'label': 'SMK / MAK', 'icon': Icons.engineering_outlined, 'desc': 'Sekolah Menengah Kejuruan'},
      {'value': 'PERGURUAN_TINGGI', 'label': 'Perguruan Tinggi', 'icon': Icons.account_balance_outlined, 'desc': 'Diploma, S1, S2'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: levels.map((level) {
        final isSelected = _selectedLevel == level['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedLevel = level['value'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.outline,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    level['icon'] as IconData,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['label'] as String,
                        style: AppTypography.titleMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        level['desc'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMajorStep() {
    String hint = 'Contoh: IPA, IPS, TKJ, Akuntansi';
    if (_selectedLevel == 'PERGURUAN_TINGGI') {
      hint = 'Contoh: Teknik Informatika, Manajemen';
    } else if (_selectedLevel == 'SMK') {
      hint = 'Contoh: TKJ, Multimedia, Akuntansi';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedLevel == 'PERGURUAN_TINGGI'
                ? 'Program Studi'
                : 'Jurusan',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _majorController,
            onChanged: (_) => setState(() {}),
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Data ini digunakan untuk memberikan rekomendasi kursus yang relevan untukmu.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: _goals.map((goal) {
        final isSelected = _selectedGoal == goal;
        return GestureDetector(
          onTap: () => setState(() => _selectedGoal = goal),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.outline,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    goal,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi / Kecamatan Pilihan',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Contoh: Indramayu, Jatibarang, Haurgeulis...',
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lokasi digunakan untuk menampilkan LPK dan kursus terdekat. Kamu masih dapat mencari kursus di lokasi lain kapan saja.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.outline.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.outline),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _canProceedStep && !_isLoading ? _nextStep : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentStep < 3 ? 'Lanjut' : 'Simpan & Mulai',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
