import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  final List<OnboardingSlideData> _slides = const [
    OnboardingSlideData(
      badge: 'LPK TERVERIFIKASI',
      badgeIcon: Icons.verified_rounded,
      title: 'Cari LPK & Pelatihan Terbaik',
      description:
          'Temukan Lembaga Pelatihan Kerja resmi dan terakreditasi di Indramayu untuk tingkatkan keterampilan Anda.',
      imageAsset: 'assets/images/onboarding_1.jpg',
      primaryColor: Color(0xFF2563EB), // Royal Blue
      accentColor: Color(0xFF3B82F6),
    ),
    OnboardingSlideData(
      badge: 'JADWAL FLEKSIBEL',
      badgeIcon: Icons.calendar_month_rounded,
      title: 'Booking Cepat & Mudah',
      description:
          'Pilih tanggal dan sesi kursus yang sesuai, lalu daftar langsung hanya dalam beberapa ketukan dari genggaman.',
      imageAsset: 'assets/images/onboarding_2.jpg',
      primaryColor: Color(0xFFD97706), // Warm Amber
      accentColor: Color(0xFFF59E0B),
    ),
    OnboardingSlideData(
      badge: 'STANDAR INDUSTRI',
      badgeIcon: Icons.workspace_premium_rounded,
      title: 'Sertifikasi Siap Kerja',
      description:
          'Dapatkan sertifikat resmi berstandar industri dan buka peluang karir kerja maupun wirausaha mandiri.',
      imageAsset: 'assets/images/onboarding_3.jpg',
      primaryColor: Color(0xFF1D4ED8), // Deep Blue
      accentColor: Color(0xFF2563EB),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentItem = _slides[_currentPage];
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo Skilloka & Lewati (Skip) Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.school,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Skill',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const TextSpan(
                              text: 'oka',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF59E0B),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _navigateToLogin,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: isDark
                          ? Colors.white.withAlpha(20)
                          : const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Lewati',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View with Responsive Editorial Illustration
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _OnboardingSlideItem(
                    data: _slides[index],
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Bottom Navigation Section
            LayoutBuilder(
              builder: (context, constraints) {
                final bottomWidth = constraints.maxWidth == double.infinity
                    ? MediaQuery.of(context).size.width
                    : constraints.maxWidth;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: SizedBox(
                    width: bottomWidth,
                    height: 52,
                    child: isLastPage
                        ? ElevatedButton(
                            onPressed: _navigateToLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentItem.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor:
                                  currentItem.primaryColor.withAlpha(100),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Mulai Sekarang',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              // Indicators
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(_slides.length, (index) {
                                  final isSelected = _currentPage == index;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    margin: const EdgeInsets.only(right: 6),
                                    width: isSelected ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? currentItem.primaryColor
                                          : (isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),

                              // Next Pill Button — intrinsic size only
                              IntrinsicWidth(
                                child: ElevatedButton(
                                  onPressed: _nextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentItem.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Next',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideItem extends StatelessWidget {
  final OnboardingSlideData data;
  final bool isDark;

  const _OnboardingSlideItem({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        // Dynamically clamp image diameter between 110 and 240 based on available screen height
        final imageSize = (availableHeight * 0.40).clamp(110.0, 240.0);

        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular Editorial Illustration Hero
                  Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 65 : 20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        data.imageAsset,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: data.primaryColor.withAlpha(30),
                            ),
                            child: Center(
                              child: Icon(
                                data.badgeIcon,
                                size: imageSize * 0.35,
                                color: data.primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: availableHeight > 450 ? 22 : 12),

                  // Category Pill Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: data.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: data.primaryColor.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.badgeIcon, size: 13, color: data.primaryColor),
                        const SizedBox(width: 5),
                        Text(
                          data.badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: data.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: availableHeight > 450 ? 14 : 8),

                  // Title
                  Text(
                    data.title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: availableHeight > 450 ? 24 : 19,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: availableHeight > 450 ? 10 : 6),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      data.description,
                      style: TextStyle(
                        fontSize: availableHeight > 450 ? 13.5 : 12.0,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class OnboardingSlideData {
  final String badge;
  final IconData badgeIcon;
  final String title;
  final String description;
  final String imageAsset;
  final Color primaryColor;
  final Color accentColor;

  const OnboardingSlideData({
    required this.badge,
    required this.badgeIcon,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.primaryColor,
    required this.accentColor,
  });
}
