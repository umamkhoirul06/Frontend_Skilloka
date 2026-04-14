import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeModeKey);
    if (isDark != null) {
      emit(isDark ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> toggleTheme(BuildContext context) async {
    // If current state is system, we use MediaQuery to know the actual brightness
    ThemeMode currentMode = state;
    if (currentMode == ThemeMode.system) {
      final brightness = MediaQuery.of(context).platformBrightness;
      currentMode = brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }
    
    final isDark = currentMode == ThemeMode.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    emit(newMode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, !isDark);
  }
}
