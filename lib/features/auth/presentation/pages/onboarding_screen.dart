/// Onboarding Screen with parallax pages
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      title: 'Cari LPK Terbaik',
      description:
          'Temukan Lembaga Pelatihan Kerja terverifikasi di sekitar Anda dengan mudah',
      icon: Icons.search,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Booking Mudah',
      description: 'Daftar kursus favorit Anda hanya dengan beberapa ketukan',
      icon: Icons.touch_app,
      color: AppColors.secondary,
    ),
    OnboardingPage(
      title: 'Sertifikat Resmi',
      description: 'Dapatkan sertifikat yang diakui Dinas Ketenagakerjaan',
      icon: Icons.workspace_premium,
      color: AppColors.success,
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'Lewati',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _OnboardingPageWidget(
                    page: _pages[index],
                    pageController: _pageController,
                    index: index,
                  );
                },
              ),
            ),
            // Page Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: AppAnimations.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _pages[_currentPage].color
                          : AppColors.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Next Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: AnimatedPrimaryButton(
                text: _currentPage == _pages.length - 1
                    ? 'Mulai Sekarang'
                    : 'Selanjutnya',
                gradient: LinearGradient(
                  colors: [
                    _pages[_currentPage].color,
                    _pages[_currentPage].color.withValues(alpha: 0.8),
                  ],
                ),
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final PageController pageController;
  final int index;

  const _OnboardingPageWidget({
    required this.page,
    required this.pageController,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double parallaxOffset = 0;
        if (pageController.position.haveDimensions) {
          final pageOffset = pageController.page ?? 0;
          parallaxOffset = (index - pageOffset) * 100;
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with parallax
            Transform.translate(
              offset: Offset(parallaxOffset * 0.5, 0),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: page.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: page.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(page.icon, size: 48, color: page.color),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Title with parallax
            Transform.translate(
              offset: Offset(parallaxOffset * 0.3, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  page.title,
                  style: AppTypography.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Transform.translate(
              offset: Offset(parallaxOffset * 0.2, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  page.description,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
