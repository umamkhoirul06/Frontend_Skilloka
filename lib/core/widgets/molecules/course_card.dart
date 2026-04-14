/// Course Card with parallax, rolling price, and rating animations
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_typography.dart';
import '../../animations/app_animations.dart';
import '../skeleton/skeleton_loader.dart';

class CourseCard extends StatefulWidget {
  final String id;
  final String title;
  final String lpkName;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double distanceKm; // Tetap dibiarkan agar tidak error di file parent
  final int price;
  final String? category;
  final bool isVerified;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.id,
    required this.title,
    required this.lpkName,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.price,
    this.category,
    this.isVerified = false,
    this.onTap,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.instant,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppAnimations.cardPressScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.buttonPress),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHighlightChanged(bool isHighlighted) {
    setState(() => _isPressed = isHighlighted);
    if (isHighlighted) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder:
          (context, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
      child: Hero(
        tag: '${AppAnimations.heroTagCourse}${widget.id}',
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppShapes.cardRadius,
            boxShadow:
                _isPressed
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppShapes.cardRadius,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _handleHighlightChanged,
              borderRadius: AppShapes.cardRadius,
              splashColor: AppColors.primary.withValues(alpha: 0.1),
              highlightColor: AppColors.primary.withValues(alpha: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar menggunakan Expanded agar dinamis
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildHeroImage(),
                    ),
                  ),
                  // Padding diatur menjadi 8 agar lebih ringkas
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        if (widget.category != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor().withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: AppShapes.chipRadius,
                            ),
                            child: Text(
                              widget.category!,
                              style: AppTypography.badge.copyWith(
                                color: _getCategoryColor(),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        // Title
                        Text(
                          widget.title,
                          style: AppTypography.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // LPK Name
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.lpkName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.isVerified)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                child: const Icon(
                                  Icons.verified,
                                  color: AppColors.success,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // --- FIX: Rating Saja (Ikon Lokasi & Jarak Dihapus) ---
                        Row(
                          children: [
                            _buildRatingStars(),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${widget.rating.toStringAsFixed(1)} (${widget.reviewCount})',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // -----------------------------------------------------
                        const SizedBox(height: 4),
                        // Price with rolling animation
                        RollingPrice(price: widget.price),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppShapes.radiusLG),
        topRight: Radius.circular(AppShapes.radiusLG),
      ),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => const SkeletonLoader(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
        errorWidget:
            (context, url, error) => Container(
              color: AppColors.surfaceVariant,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 32,
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;

        if (widget.rating >= starValue) {
          icon = Icons.star;
          color = AppColors.warning;
        } else if (widget.rating >= starValue - 0.5) {
          icon = Icons.star_half;
          color = AppColors.warning;
        } else {
          icon = Icons.star_border;
          color = AppColors.textDisabled;
        }

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 200 + (index * 100)),
          curve: AppAnimations.overshoot,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Icon(icon, color: color, size: 12),
        );
      }),
    );
  }

  Color _getCategoryColor() {
    switch (widget.category?.toLowerCase()) {
      case 'las':
        return AppColors.categoryLas;
      case 'it':
        return AppColors.categoryIT;
      case 'otomotif':
        return AppColors.categoryOtomotif;
      case 'tata busana':
        return AppColors.categoryTataBusana;
      case 'tata boga':
        return AppColors.categoryTataBoga;
      case 'bahasa':
        return AppColors.categoryBahasa;
      default:
        return AppColors.primary;
    }
  }
}

/// Rolling Price Animation
class RollingPrice extends StatefulWidget {
  final int price;
  final TextStyle? style;

  const RollingPrice({super.key, required this.price, this.style});

  @override
  State<RollingPrice> createState() => _RollingPriceState();
}

class _RollingPriceState extends State<RollingPrice>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _priceAnimation;
  int _previousPrice = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.numberRoll,
    );
    _priceAnimation = IntTween(
      begin: 0,
      end: widget.price,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(RollingPrice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.price != widget.price) {
      _previousPrice = oldWidget.price;
      _priceAnimation = IntTween(
        begin: _previousPrice,
        end: widget.price,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _priceAnimation,
      builder: (context, child) {
        return Text(
          _formatPrice(_priceAnimation.value),
          style:
              widget.style ??
              AppTypography.priceTag.copyWith(color: AppColors.primary),
        );
      },
    );
  }
}
