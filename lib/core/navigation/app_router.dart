/// App Router configuration using GoRouter
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/course/presentation/pages/course_detail_screen.dart';
import '../../features/course/presentation/pages/lpk_detail_screen.dart';
import '../../features/booking/presentation/pages/booking_screen.dart';
import '../../features/booking/presentation/pages/bookings_list_screen.dart';
import '../../features/booking/presentation/pages/payment_screen.dart';
import '../../features/booking/presentation/pages/booking_success_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/edit_profile_screen.dart';
import '../../features/profile/presentation/pages/certificates_screen.dart';
import '../../features/profile/presentation/pages/favorites_screen.dart';
import '../../features/profile/presentation/pages/notifications_screen.dart';
import '../../features/profile/presentation/pages/help_screen.dart';
import '../../features/profile/presentation/pages/about_screen.dart';
import '../../features/component_gallery/presentation/pages/component_gallery_screen.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String search = '/search';
  static const String courseDetail = '/course/:id';
  static const String lpkDetail = '/lpk/:id';
  static const String booking = '/booking/:courseId';
  static const String payment = '/payment/:bookingId';
  static const String bookingSuccess = '/booking-success/:bookingId';
  static const String bookings = '/bookings';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String certificates = '/profile/certificates';
  static const String favorites = '/profile/favorites';
  static const String notifications = '/profile/notifications';
  static const String help = '/profile/help';
  static const String about = '/profile/about';
  static const String componentGallery = '/components';

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),

      // Onboarding
      GoRoute(
        path: onboarding,
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const OnboardingScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),

      // Auth
      GoRoute(
        path: login,
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const LoginScreen(),
              transitionsBuilder: _slideUpTransition,
            ),
      ),

      // Main Shell (Bottom Navigation)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: home,
            pageBuilder:
                (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
          ),
          GoRoute(
            path: bookings,
            pageBuilder:
                (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const BookingsListScreen(),
                ),
          ),
          GoRoute(
            path: profile,
            pageBuilder:
                (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ProfileScreen(),
                ),
          ),
        ],
      ),

      // Course Detail
      GoRoute(
        path: courseDetail,
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CourseDetailScreen(courseId: courseId),
            transitionsBuilder: _slideRightTransition,
          );
        },
      ),

      // LPK Detail
      GoRoute(
        path: lpkDetail,
        pageBuilder: (context, state) {
          final lpkId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: LPKDetailScreen(lpkId: lpkId),
            transitionsBuilder: _slideRightTransition,
          );
        },
      ),

      // Booking Flow
      GoRoute(
        path: booking,
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BookingScreen(courseId: courseId),
            transitionsBuilder: _slideUpTransition,
          );
        },
      ),

      GoRoute(
        path: payment,
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['bookingId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PaymentScreen(courseId: courseId),
            transitionsBuilder: _slideRightTransition,
          );
        },
      ),

      GoRoute(
        path: bookingSuccess,
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['bookingId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BookingSuccessScreen(courseId: courseId),
            transitionsBuilder: _fadeScaleTransition,
          );
        },
      ),

      // Profile Sub-pages
      GoRoute(
        path: editProfile,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: certificates,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CertificatesScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: favorites,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FavoritesScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: notifications,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: help,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HelpScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: about,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AboutScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),

      // Component Gallery (Development)
      GoRoute(
        path: componentGallery,
        builder: (context, state) => const ComponentGalleryScreen(),
      ),
    ],
  );

  // Transition Builders
  static Widget _slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );
  }

  static Widget _slideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );
  }

  static Widget _fadeScaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

/// Main Shell with Bottom Navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}

/// Bottom Navigation Bar
class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/bookings')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.bookings);
        break;
      case 2:
        context.go(AppRouter.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onItemTapped(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Pesanan',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}

