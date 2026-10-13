
import 'package:flutter/material.dart';

class AvatarItem {
  final String id;
  final String name;
  final String assetPath;
  final IconData fallbackIcon;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.assetPath,
    this.fallbackIcon = Icons.person,
  });
}

enum FrameType {
  simple,
  gradient,
  sparkle,
  glow,
  rainbow,
  cute,
}

class FrameItem {
  final String id;
  final String name;
  final FrameType type;
  final IconData icon;

  const FrameItem({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
  });
}

/// Sembilan avatar karakter untuk aplikasi Skilloka.
/// File ilustrasi PNG berada di assets/avatars/.
const List<AvatarItem> dummyAvatars = [
  AvatarItem(
    id: 'character_01',
    name: 'Alya',
    assetPath: 'assets/avatars/cell_r1_c1.png',
  ),
  AvatarItem(
    id: 'character_02',
    name: 'Raka',
    assetPath: 'assets/avatars/cell_r1_c2.png',
  ),
  AvatarItem(
    id: 'character_03',
    name: 'Naya',
    assetPath: 'assets/avatars/cell_r1_c3.png',
  ),
  AvatarItem(
    id: 'character_04',
    name: 'Dimas',
    assetPath: 'assets/avatars/cell_r2_c1.png',
  ),
  AvatarItem(
    id: 'character_05',
    name: 'Salsa',
    assetPath: 'assets/avatars/cell_r2_c2.png',
  ),
  AvatarItem(
    id: 'character_06',
    name: 'Arga',
    assetPath: 'assets/avatars/cell_r2_c3.png',
  ),
  AvatarItem(
    id: 'character_07',
    name: 'Keira',
    assetPath: 'assets/avatars/cell_r3_c1.png',
  ),
  AvatarItem(
    id: 'character_08',
    name: 'Fajar',
    assetPath: 'assets/avatars/cell_r3_c2.png',
  ),
  AvatarItem(
    id: 'character_09',
    name: 'Zahra',
    assetPath: 'assets/avatars/cell_r3_c3.png',
  ),
];

/// Pilihan frame dengan ID yang sesuai backend.
const List<FrameItem> dummyFrames = [
  FrameItem(
    id: 'none',
    name: 'Tanpa Frame',
    type: FrameType.simple,
    icon: Icons.circle_outlined,
  ),
  FrameItem(
    id: 'soft',
    name: 'Soft',
    type: FrameType.cute,
    icon: Icons.favorite_border,
  ),
  FrameItem(
    id: 'glow',
    name: 'Glow',
    type: FrameType.glow,
    icon: Icons.blur_on,
  ),
  FrameItem(
    id: 'sparkle',
    name: 'Sparkle',
    type: FrameType.sparkle,
    icon: Icons.auto_awesome,
  ),
  FrameItem(
    id: 'gradient',
    name: 'Gradient',
    type: FrameType.gradient,
    icon: Icons.gradient,
  ),
];