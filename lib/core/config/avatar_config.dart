import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarItem {
  final String id;
  final String name;
  final String assetPath;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.assetPath,
  });
}

class FrameItem {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;

  const FrameItem({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.borderColor,
    this.borderWidth = 3.0,
    this.shadows = const [],
  });
}

class AvatarConfig {
  static const List<AvatarItem> avatars = [
    AvatarItem(id: 'avatar_01', name: 'Avatar 1', assetPath: 'assets/avatars/avatar_01.png'),
    AvatarItem(id: 'avatar_02', name: 'Avatar 2', assetPath: 'assets/avatars/avatar_02.png'),
    AvatarItem(id: 'avatar_03', name: 'Avatar 3', assetPath: 'assets/avatars/avatar_03.png'),
    AvatarItem(id: 'avatar_04', name: 'Avatar 4', assetPath: 'assets/avatars/avatar_04.png'),
    AvatarItem(id: 'avatar_05', name: 'Avatar 5', assetPath: 'assets/avatars/avatar_05.png'),
    AvatarItem(id: 'avatar_06', name: 'Avatar 6', assetPath: 'assets/avatars/avatar_06.png'),
  ];

  static List<FrameItem> get frames => [
    const FrameItem(
      id: 'none',
      name: 'Basic',
      gradientColors: [Colors.transparent, Colors.transparent],
      borderColor: Colors.grey,
      borderWidth: 2.0,
    ),
    FrameItem(
      id: 'blue',
      name: 'Skilloka Blue',
      gradientColors: [AppColors.primary, AppColors.primaryLight],
      borderColor: AppColors.primary,
      borderWidth: 3.5,
      shadows: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    const FrameItem(
      id: 'purple',
      name: 'Royal Purple',
      gradientColors: [Color(0xFF8E24AA), Color(0xFFCE93D8)],
      borderColor: Color(0xFF8E24AA),
      borderWidth: 3.5,
      shadows: [
        BoxShadow(
          color: Color(0x408E24AA),
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ],
    ),
    const FrameItem(
      id: 'gold',
      name: 'Pro Gold',
      gradientColors: [Color(0xFFFFD700), Color(0xFFFFA000)],
      borderColor: Color(0xFFFFD700),
      borderWidth: 3.5,
      shadows: [
        BoxShadow(
          color: Color(0x55FFD700),
          blurRadius: 12,
          offset: Offset(0, 4),
        )
      ],
    ),
    const FrameItem(
      id: 'gradient',
      name: 'Modern Gradient',
      gradientColors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
      borderColor: Color(0xFF00F2FE),
      borderWidth: 3.5,
      shadows: [
        BoxShadow(
          color: Color(0x4000F2FE),
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ],
    ),
    const FrameItem(
      id: 'neon',
      name: 'Neon Glow',
      gradientColors: [Color(0xFF00FFCC), Color(0xFF0099FF)],
      borderColor: Color(0xFF00FFCC),
      borderWidth: 4.0,
      shadows: [
        BoxShadow(
          color: Color(0x8000FFCC),
          blurRadius: 16,
          spreadRadius: 1,
        )
      ],
    ),
  ];

  static AvatarItem getAvatarById(String? id) {
    return avatars.firstWhere(
      (element) => element.id == id,
      orElse: () => avatars.first,
    );
  }

  static FrameItem getFrameById(String? id) {
    return frames.firstWhere(
      (element) => element.id == id,
      orElse: () => frames.first,
    );
  }
}