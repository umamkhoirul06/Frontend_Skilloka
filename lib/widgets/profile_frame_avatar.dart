
import 'package:flutter/material.dart';
import '../models/avatar_frame_data.dart';

class ProfileFrameAvatar extends StatelessWidget {
  final double size;
  final String? imagePath;
  final Widget? imageWidget;
  final AvatarItem? selectedAvatar;
  final FrameType frameType;
  final bool isCustomPhoto;

  const ProfileFrameAvatar({
    Key? key,
    this.size = 110.0,
    this.imagePath,
    this.imageWidget,
    this.selectedAvatar,
    required this.frameType,
    this.isCustomPhoto = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frameColor = _frameColor;
    final isNoFrame = frameType == FrameType.simple;
    final outerSize = size + 12;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Center(
        child: Container(
          width: size + (isNoFrame ? 0 : 10),
          height: size + (isNoFrame ? 0 : 10),
          padding: EdgeInsets.all(isNoFrame ? 0 : 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: frameType == FrameType.gradient
                ? const LinearGradient(
                    colors: [
                      Color(0xFFF2C9DE),
                      Color(0xFFCFC8FA),
                      Color(0xFFBDE8E3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: frameType == FrameType.gradient
                ? null
                : Colors.white,
            border: !isNoFrame && frameType != FrameType.gradient
                ? Border.all(
                    color: frameColor,
                    width: frameType == FrameType.cute ? 3 : 2,
                  )
                : null,
            boxShadow: frameType == FrameType.glow
                ? [
                    BoxShadow(
                      color: const Color(0xFFD6C9FA).withOpacity(0.55),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: _buildAvatarContent(),
                ),
              ),
              if (frameType == FrameType.sparkle) ...[
                const Positioned(
                  top: -2,
                  right: 5,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 17,
                    color: Color(0xFFE9BD70),
                  ),
                ),
                const Positioned(
                  bottom: 2,
                  left: 0,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: Color(0xFFD4B8F3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color get _frameColor {
    switch (frameType) {
      case FrameType.simple:
        return Colors.transparent;
      case FrameType.cute:
        return const Color(0xFFF0C6DD);
      case FrameType.glow:
        return const Color(0xFFD6C9FA);
      case FrameType.sparkle:
        return const Color(0xFFF0D6A5);
      case FrameType.gradient:
        return const Color(0xFFCFC8FA);
      default:
        return const Color(0xFFE3DDF2);
    }
  }

  Widget _buildAvatarContent() {
    if (isCustomPhoto && imageWidget != null) {
      return imageWidget!;
    }

    if (isCustomPhoto && imagePath != null) {
      return Image.network(
        imagePath!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return _personFallback();
        },
      );
    }

    if (selectedAvatar != null) {
      return Image.asset(
        selectedAvatar!.assetPath,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return _personFallback(
            icon: selectedAvatar!.fallbackIcon,
          );
        },
      );
    }

    return _personFallback();
  }

  Widget _personFallback({IconData icon = Icons.person}) {
    return Container(
      color: const Color(0xFFF6F1FA),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size * 0.5,
        color: const Color(0xFFB5A4D3),
      ),
    );
  }
}