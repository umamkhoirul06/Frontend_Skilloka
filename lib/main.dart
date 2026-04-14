/// Main Application Entry Point
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/navigation/app_router.dart';
import 'core/localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize dependencies
  await di.init();

  runApp(
    BlocProvider(
      create: (context) => ThemeCubit(),
      child: const SkillokApp(),
    ),
  );
}

class SkillokApp extends StatefulWidget {
  const SkillokApp({super.key});

  @override
  State<SkillokApp> createState() => _SkillokAppState();
}

class _SkillokAppState extends State<SkillokApp> {
  Locale _locale = const Locale('id');

  // ignore: unused_element
  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'Skilloka',
          debugShowCheckedModeBanner: false,

          // Theme Configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,

      // Router Configuration
      routerConfig: AppRouter.router,

      // Localization
      locale: _locale,
      supportedLocales: const [
        Locale('id'), // Indonesian
        Locale('en'), // English
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Builder for global configurations
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling beyond 1.2x for accessibility
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(
                context,
              ).textScaler.scale(1.0).clamp(0.8, 1.2).toDouble(),
            ),
          ),
          child: child!,
        );
      },
    );
    });
  }
}
