/// Onboarding Screen with Skilloka Web Design (Blue, Amber, Navy)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      badge: 'LPK TERVERIFIKASI',
      badgeIcon: Icons.verified_rounded,
      title: 'Cari LPK & Pelatihan Terbaik',
      description:
          'Temukan Lembaga Pelatihan Kerja resmi dan terakreditasi di Indramayu untuk tingkatkan keterampilan Anda.',
      icon: Icons.school_rounded,
      primaryColor: Color(0xFF2563EB), // Web Brand Blue
      secondaryColor: Color(0xFF3B82F6),
      tag1: 'Resmi Disnaker',
      tag2: 'Instruktur Ahli',
    ),
    OnboardingPageData(
      badge: 'JADWAL FLEKSIBEL',
      badgeIcon: Icons.calendar_month_rounded,
      title: 'Booking Cepat & Mudah',
      description:
          'Pilih tanggal dan sesi kursus yang sesuai, lalu daftar langsung hanya dalam beberapa ketukan dari genggaman.',
      icon: Icons.touch_app_rounded,
      primaryColor: Color(0xFFF59E0B), // Web Amber Gold
      secondaryColor: Color(0xFFD97706),
      tag1: 'Pilihan Sesi Pagi & Sore',
      tag2: 'Konfirmasi Instan',
    ),
    OnboardingPageData(
      badge: 'STANDAR INDUSTRI',
      badgeIcon: Icons.workspace_premium_rounded,
      title: 'Sertifikasi Siap Kerja',
      description:
          'Dapatkan sertifikat resmi berstandar industri dan buka peluang karir kerja maupun wirausaha mandiri.',
      icon: Icons.military_tech_rounded,
      primaryColor: Color(0xFF1D4ED8), // Deep Royal Blue
      secondaryColor: Color(0xFF2563EB),
      tag1: 'Sertifikat Resmi',
      tag2: 'Peluang Kerja Luas',
    ),
  ];

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppAnimations.medium,
        curve: AppAnimations.pageTransition,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    context.go(AppRouter.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentItem = _pages[_currentPage];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Brand and Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Skill',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const TextSpan(
                          text: 'oka',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B), // Web Amber Gold
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _navigateToLogin,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Lewati',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? Colors.white70 : const Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View with Rich Visuals
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _OnboardingPageView(
                    data: _pages[index],
                    pageController: _pageController,
                    index: index,
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Bottom Controls Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isSelected = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? currentItem.primaryColor
                              : (isDark
                                  ? Colors.white24
                                  : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: currentItem.primaryColor
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentItem.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor:
                            currentItem.primaryColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'Mulai Sekarang'
                                : 'Lanjutkan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _pages.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingPageData data;
  final PageController pageController;
  final int index;
  final bool isDark;

  const _OnboardingPageView({
    required this.data,
    required this.pageController,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double parallaxOffset = 0;
        if (pageController.position.haveDimensions) {
          final pageOffset = pageController.page ?? 0;
          parallaxOffset = (index - pageOffset) * 80;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual Illustration Box with Parallax
              Transform.translate(
                offset: Offset(parallaxOffset * 0.4, 0),
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Glow
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              data.primaryColor.withValues(alpha: 0.25),
                              data.primaryColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),

                      // Outer Dashed / Ring
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: data.primaryColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                      ),

                      // Central Icon Circle
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              data.primaryColor,
                              data.secondaryColor,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: data.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            data.icon,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Floating Tag 1
                      Positioned(
                        top: 25,
                        left: 10,
                        child: _FloatingTag(
                          icon: Icons.check_circle_rounded,
                          label: data.tag1,
                          color: data.primaryColor,
                          isDark: isDark,
                        ),
                      ),

                      // Floating Tag 2
                      Positioned(
                        bottom: 30,
                        right: 10,
                        child: _FloatingTag(
                          icon: Icons.star_rounded,
                          label: data.tag2,
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Category / Feature Badge
              Transform.translate(
                offset: Offset(parallaxOffset * 0.2, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: data.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: data.primaryColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(data.badgeIcon, size: 14, color: data.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        data.badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: data.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title with Parallax
              Transform.translate(
                offset: Offset(parallaxOffset * 0.25, 0),
                child: Text(
                  data.title,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Transform.translate(
                offset: Offset(parallaxOffset * 0.15, 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    data.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _FloatingTag({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String badge;
  final IconData badgeIcon;
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final String tag1;
  final String tag2;

  const OnboardingPageData({
    required this.badge,
    required this.badgeIcon,
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tag1,
    required this.tag2,
  });
}
