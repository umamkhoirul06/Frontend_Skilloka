/// LPK Card with verified badge and map thumbnail
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_typography.dart';
import '../../animations/app_animations.dart';
import '../skeleton/skeleton_loader.dart';

class LPKCard extends StatefulWidget {
  final String id;
  final String name;
  final String? logoUrl;
  final String address;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String? mapThumbnailUrl;
  final VoidCallback? onTap;

  const LPKCard({
    super.key,
    required this.id,
    required this.name,
    this.logoUrl,
    required this.address,
    required this.rating,
    required this.reviewCount,
    this.isVerified = false,
    this.mapThumbnailUrl,
    this.onTap,
  });

  @override
  State<LPKCard> createState() => _LPKCardState();
}

class _LPKCardState extends State<LPKCard> with SingleTickerProviderStateMixin {
  late AnimationController _badgeController;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      vsync: this,
      duration: AppAnimations.slower,
    );
    _badgeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _badgeController, curve: AppAnimations.overshoot),
    );

    if (widget.isVerified) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _badgeController.forward();
      });
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: '${AppAnimations.heroTagLPK}${widget.id}',
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppShapes.cardRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppShapes.cardRadius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppShapes.cardRadius,
            splashColor: AppColors.primary.withValues(alpha: 0.1),
            highlightColor: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with verified badge overlay
                  _buildLogoWithBadge(),
                  const SizedBox(height: 12),
                  // Name
                  Text(
                    widget.name,
                    style: AppTypography.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Verified Badge
                  if (widget.isVerified) _buildVerifiedBadge(),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.rating.toStringAsFixed(1)} (${widget.reviewCount})',
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Address with map icon
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textTertiary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.address,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoWithBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Logo
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppShapes.borderRadiusMD,
            border: Border.all(color: AppColors.outline, width: 1),
          ),
          child: widget.logoUrl != null
              ? ClipRRect(
                  borderRadius: AppShapes.borderRadiusMD,
                  child: CachedNetworkImage(
                    imageUrl: widget.logoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const SkeletonLoader(width: 60, height: 60),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.business,
                      color: AppColors.textTertiary,
                      size: 28,
                    ),
                  ),
                )
              : const Icon(
                  Icons.business,
                  color: AppColors.textTertiary,
                  size: 28,
                ),
        ),
        // Verified badge overlay
        if (widget.isVerified)
          Positioned(
            right: -4,
            bottom: -4,
            child: ScaleTransition(
              scale: _badgeAnimation,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVerifiedBadge() {
    return ScaleTransition(
      scale: _badgeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.successContainer,
          borderRadius: AppShapes.chipRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedCheckmark(animate: true),
            const SizedBox(width: 4),
            Text(
              'Terverifikasi Dinas',
              style: AppTypography.badge.copyWith(color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Checkmark for verified badges
class AnimatedCheckmark extends StatefulWidget {
  final bool animate;
  final double size;
  final Color color;

  const AnimatedCheckmark({
    super.key,
    this.animate = true,
    this.size = 12,
    this.color = AppColors.success,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.checkmarkDraw,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CheckmarkPainter(
            progress: _animation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Checkmark path
    final start = Offset(size.width * 0.2, size.height * 0.5);
    final mid = Offset(size.width * 0.45, size.height * 0.75);
    final end = Offset(size.width * 0.85, size.height * 0.25);

    if (progress <= 0.5) {
      // First half of animation - draw first line
      final t = progress * 2;
      final currentPoint = Offset.lerp(start, mid, t)!;
      path.moveTo(start.dx, start.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      // Second half - draw both lines
      path.moveTo(start.dx, start.dy);
      path.lineTo(mid.dx, mid.dy);

      final t = (progress - 0.5) * 2;
      final currentPoint = Offset.lerp(mid, end, t)!;
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
