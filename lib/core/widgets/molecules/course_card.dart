/// Course Card with parallax, rolling price, and rating animations
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../animations/app_animations.dart';

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
  bool _isBookmarked = false;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap?.call();
              },
              onHighlightChanged: _handleHighlightChanged,
              borderRadius: BorderRadius.circular(18),
              splashColor: AppColors.primary.withValues(alpha: 0.08),
              highlightColor: AppColors.primary.withValues(alpha: 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar bersih dengan floating bookmark (Oakory style)
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildHeroImage(),
                    ),
                  ),

                  // Area Informasi Kursus Minimalis & Rapi
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Kategori & Nama LPK (Single clean line)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.category ?? 'Kursus'} • ${widget.lpkName}',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF10B981),
                                size: 13,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Judul Kursus (Maksimal 2 baris terstruktur rapi)
                        SizedBox(
                          height: 34,
                          child: Text(
                            widget.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Harga Utama (Diberi FittedBox agar tidak pernah wrap digit nol ke baris baru)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RollingPrice(
                            price: widget.price,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Rating Bintang Minimalis (Oakory style: ★ 4.8 (89))
                        _buildMinimalRating(isDark),
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

  Widget _buildMinimalRating(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          color: Color(0xFFF59E0B), // Warm amber star
          size: 14,
        ),
        const SizedBox(width: 3),
        Text(
          widget.rating > 0 ? widget.rating.toStringAsFixed(1) : 'Baru',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          ),
        ),
        if (widget.reviewCount > 0) ...[
          const SizedBox(width: 2),
          Text(
            '(${widget.reviewCount})',
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholder() {
    IconData icon = Icons.school_rounded;
    final cat = (widget.category ?? '').toLowerCase();
    final tit = widget.title.toLowerCase();

    if (cat.contains('teknologi') ||
        cat.contains('digital') ||
        cat.contains('it') ||
        cat.contains('komputer') ||
        tit.contains('web') ||
        tit.contains('coding') ||
        tit.contains('flutter')) {
      icon = Icons.terminal_rounded;
    } else if (cat.contains('desain') || tit.contains('grafis')) {
      icon = Icons.palette_rounded;
    } else if (cat.contains('otomotif') ||
        cat.contains('manufaktur') ||
        cat.contains('mesin') ||
        cat.contains('las') ||
        tit.contains('bubut') ||
        tit.contains('cnc')) {
      icon = Icons.precision_manufacturing_rounded;
    } else if (cat.contains('bahasa') ||
        tit.contains('jepang') ||
        tit.contains('inggris')) {
      icon = Icons.language_rounded;
    } else if (cat.contains('hotel') ||
        cat.contains('kuliner') ||
        cat.contains('barista')) {
      icon = Icons.restaurant_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 38,
              color: AppColors.primary.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.category ?? 'Kursus',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final String rawUrl = widget.imageUrl.trim();
    final String resolvedUrl = ApiService.toFullUrl(rawUrl);

    return Hero(
      tag: '${AppAnimations.heroTagCourse}${widget.id}',
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gambar Utama Kursus
            resolvedUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: resolvedUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    memCacheHeight: 300,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      debugPrint('CourseCard failed to load image ($url): $error');
                      return _buildPlaceholder();
                    },
                  )
                : _buildPlaceholder(),

            // Top-left minimal tag / kategori (Oakory style)
            if (widget.category != null && widget.category!.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    widget.category!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Top-right circular bookmark button (Oakory style)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isBookmarked = !_isBookmarked);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 15,
                      color: _isBookmarked
                          ? AppColors.primary
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    if (widget.rating <= 0 && widget.reviewCount <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 10),
            const SizedBox(width: 3),
            Text(
              'Baru',
              style: AppTypography.badge.copyWith(
                color: const Color(0xFFD97706),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppColors.secondary, size: 15),
        const SizedBox(width: 3),
        Text(
          widget.rating.toStringAsFixed(1),
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryFor(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '(${widget.reviewCount})',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    final cat = (widget.category ?? '').toLowerCase();
    if (cat.contains('teknologi') || cat.contains('digital') || cat.contains('it') || cat.contains('komputer')) {
      return AppColors.categoryIT;
    } else if (cat.contains('otomotif') || cat.contains('manufaktur') || cat.contains('mesin')) {
      return AppColors.categoryOtomotif;
    } else if (cat.contains('las') || cat.contains('welding')) {
      return AppColors.categoryLas;
    } else if (cat.contains('bisnis') || cat.contains('manajemen')) {
      return const Color(0xFF0D9488); // Modern Teal
    } else if (cat.contains('bahasa')) {
      return AppColors.categoryBahasa;
    } else if (cat.contains('hotel') || cat.contains('wisata') || cat.contains('pariwisata')) {
      return const Color(0xFFE11D48); // Rose
    } else if (cat.contains('boga') || cat.contains('kuliner')) {
      return AppColors.categoryTataBoga;
    } else if (cat.contains('busana') || cat.contains('fashion')) {
      return AppColors.categoryTataBusana;
    }
    return AppColors.primary;
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
    if (price <= 0) return 'Gratis';
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _priceAnimation,
      builder: (context, child) {
        return Text(
          _formatPrice(_priceAnimation.value),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: widget.style ??
              AppTypography.priceTag.copyWith(color: AppColors.primary),
        );
      },
    );
  }
}
