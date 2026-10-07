/// App Router configuration using GoRouter
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/auth/presentation/pages/education_onboarding_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/course/presentation/pages/course_detail_screen.dart';
import '../../features/course/presentation/pages/lpk_detail_screen.dart';
import '../../features/course/presentation/pages/my_courses_screen.dart';
import '../../features/course/presentation/pages/course_learning_screen.dart';
import '../../features/course/presentation/pages/search_screen.dart';
import '../../features/course/presentation/pages/chatbot_screen.dart';
import '../../features/course/presentation/pages/review_screen.dart';
import '../../features/booking/presentation/pages/booking_screen.dart';
import '../../features/booking/presentation/pages/pending_booking_screen.dart';
import '../../features/booking/presentation/pages/bookings_list_screen.dart';
import '../../features/booking/presentation/pages/booking_success_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/edit_profile_screen.dart';
import '../../features/profile/presentation/pages/certificates_screen.dart';
import '../../features/profile/presentation/pages/favorites_screen.dart';
import '../../features/profile/presentation/pages/notifications_screen.dart';
import '../../features/profile/presentation/pages/help_screen.dart';
import '../../features/profile/presentation/pages/about_screen.dart';
import '../../features/component_gallery/presentation/pages/component_gallery_screen.dart';
import '../../features/profile/presentation/pages/settings_screen.dart';
import '../../core/widgets/chatbot_avatar_3d.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String educationOnboarding = '/education-onboarding';
  static const String home = '/home';
  static const String search = '/search';
  static const String myCourses = '/my-courses';
  static const String chatbot = '/chatbot';
  static const String courseContent = '/my-course/:courseId';
  static const String courseReview = '/review/:courseId';
  static const String courseDetail = '/course/:id';
  static const String lpkDetail = '/lpk/:id';

  // ✅ FIX: booking hanya pakai courseId (tidak dobel)
  static const String booking = '/booking/:courseId';

  // ✅ FIX: pendingBooking sudah didefinisikan dengan benar
  static const String pendingBooking = '/pending-booking/:bookingId';

  // ✅ FIX: bookingSuccess pakai bookingId
  static const String bookingSuccess = '/booking-success/:bookingId';

  static const String bookings = '/bookings';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String certificates = '/profile/certificates';
  static const String favorites = '/profile/favorites';
  static const String notifications = '/profile/notifications';
  static const String settings = '/profile/settings';
  static const String help = '/profile/help';
  static const String about = '/profile/about';
  static const String componentGallery = '/components';

  // ✅ Helper untuk navigasi yang aman (mengganti :param dengan nilai asli)
  static String bookingPath(String courseId) => '/booking/$courseId';
  static String pendingBookingPath(String bookingId) =>
      '/pending-booking/$bookingId';
  static String bookingSuccessPath(String bookingId) =>
      '/booking-success/$bookingId';
  static String courseDetailPath(String id) => '/course/$id';
  static String lpkDetailPath(String id) => '/lpk/$id';
  static String courseContentPath(String courseId) => '/my-course/$courseId';
  static String courseReviewPath(String courseId) => '/review/$courseId';

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),

      // Onboarding (intro app)
      GoRoute(
        path: onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
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

      // Education Onboarding (setelah login pertama)
      GoRoute(
        path: educationOnboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EducationOnboardingScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // Auth
      GoRoute(
        path: login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: register,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
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
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: myCourses,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MyCourseScreen(),
            ),
          ),
          GoRoute(
            path: bookings,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const BookingsListScreen(),
            ),
          ),
          GoRoute(
            path: profile,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // Search
      GoRoute(
        path: search,
        pageBuilder: (context, state) {
          final q = state.uri.queryParameters['q'];
          final cat = state.uri.queryParameters['category'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: SearchScreen(initialQuery: q, initialCategory: cat),
            transitionsBuilder: _slideRightTransition,
          );
        },
      ),

      // Chatbot
      GoRoute(
        path: chatbot,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChatbotScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
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

      // Course Learning (Materi, Absensi, Sertifikat)
      GoRoute(
        path: courseContent,
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CourseLearningScreen(courseId: courseId),
            transitionsBuilder: _slideRightTransition,
          );
        },
      ),

      // Course Review
      GoRoute(
        path: courseReview,
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ReviewScreen(
              courseId: courseId,
              courseTitle: extra?['title'] ?? 'Kursus',
              lpkName: extra?['lpkName'],
            ),
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

      // ✅ FIX: Booking — path langsung pakai constant (tidak dobel /:courseId)
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

      // ✅ FIX: Pending Booking — path sudah include /:bookingId di constant
      GoRoute(
        path: pendingBooking,
        pageBuilder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PendingBookingScreen(bookingId: bookingId),
            transitionsBuilder: _slideRightTransition,
          );
        },
      ),

      // ✅ FIX: Booking Success — pakai bookingId, path sudah include /:bookingId
      GoRoute(
        path: bookingSuccess,
        pageBuilder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BookingSuccessScreen(bookingId: bookingId),
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
      GoRoute(
        path: settings,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(), // ✅ FIX: pakai SettingsScreen yang benar
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
      body: Stack(
        children: [
          child,
          Positioned(
            right: 0,
            bottom: 6,
            child: SafeArea(
              child: FloatingChatBotWidget(
                onTap: () => context.push(AppRouter.chatbot),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}

/// Bottom Navigation Bar — 4 tab sesuai PRD 8.2
class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/my-courses')) return 1;
    if (location.startsWith('/bookings')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.myCourses);
        break;
      case 2:
        context.go(AppRouter.bookings);
        break;
      case 3:
        context.go(AppRouter.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Kursus Saya',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
