/// Splash Screen with animated logo
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/security/security_checker.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _taglineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _taglineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Inisialisasi Dependencies
      if (!di.sl.isRegistered<SecurityChecker>()) {
        await di.init();
      }

      final syncService = di.sl<SyncService>();
      final securityChecker = di.sl<SecurityChecker>();

      // 2. Cek Keamanan Perangkat
      final isSecure = await securityChecker.isDeviceSecure();

      if (!isSecure && mounted) {
        _showSecurityAlert();
        return;
      }

      // 3. Jalankan Sync Data dan tunggu animasi minimal 2.5 detik
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 2500)),
        syncService.startInitialSync(),
      ]);

      // ==========================================
      // LOGIKA AUTO-LOGIN BARU YANG DITERAPKAN
      // ==========================================
      final apiService = ApiService();
      final token = await apiService.getToken();

      if (!mounted) return;

      if (token == null || token.isEmpty) {
        // Belum login atau token hilang -> arahkan ke halaman Login
        context.go(AppRouter.login);
        return;
      }

      // Ada token -> validasi ke server
      try {
        final result = await apiService.getProfile();
        if (!mounted) return;

        if (result['success'] == true) {
          // Token masih valid -> langsung Home
          context.go(AppRouter.home);
        } else {
          // Token expired/invalid -> hapus dan ke Login
          await apiService.removeToken();
          context.go(
              AppRouter.login); // Pastikan AppRouter.login sudah didefinisikan
        }
      } catch (e) {
        // Koneksi gagal (misal tidak ada internet) -> coba tetap masuk kalau ada token
        // (biar bisa pakai app offline mode)
        if (!mounted) return;
        context.go(AppRouter.home);
      }
    } catch (e) {
      // Fallback jika ada error pada proses inisialisasi awal
      if (mounted) {
        context.go(AppRouter.onboarding);
      }
    }
  }

  void _showSecurityAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Peringatan Keamanan'),
        content: const Text(
          'Perangkat Anda terdeteksi telah di-root atau jailbreak. '
          'Untuk keamanan data Anda, aplikasi tidak dapat dijalankan '
          'pada perangkat ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Desain dipertahankan sama persis dengan yang lama
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Animated Logo
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(scale: _logoAnimation, child: child),
                  );
                },
                child: const _Logo(),
              ),
              const SizedBox(height: 24),
              // Tagline
              AnimatedBuilder(
                animation: _taglineAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _taglineAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(_taglineAnimation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'Kompetensi Tanpa Batas',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Loading indicator
              FadeTransition(
                opacity: _taglineAnimation,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // App Name
        Text(
          'Skilloka',
          style: AppTypography.displaySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
