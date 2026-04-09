/// Location Chip with GPS pulse animation
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_typography.dart';
import '../../animations/app_animations.dart';

class LocationChip extends StatefulWidget {
  final String location;
  final VoidCallback? onTap;
  final bool showPulse;
  final bool isLoading;

  const LocationChip({
    super.key,
    required this.location,
    this.onTap,
    this.showPulse = true,
    this.isLoading = false,
  });

  @override
  State<LocationChip> createState() => _LocationChipState();
}

class _LocationChipState extends State<LocationChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LocationChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.showPulse && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: AppShapes.chipRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated GPS Icon
            widget.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: widget.showPulse ? _pulseAnimation.value : 1.0,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ),
                  ),
            const SizedBox(width: 6),
            // Location Text
            Flexible(
              child: Text(
                widget.location,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Category Icon with color coding
class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final bool showLabel;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 48,
    this.showLabel = true,
    this.isSelected = false,
    this.onTap,
  });

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'las':
      case 'welding':
        return AppColors.categoryLas;
      case 'it':
      case 'komputer':
      case 'computer':
        return AppColors.categoryIT;
      case 'otomotif':
      case 'automotive':
        return AppColors.categoryOtomotif;
      case 'tata busana':
      case 'fashion':
        return AppColors.categoryTataBusana;
      case 'tata boga':
      case 'culinary':
        return AppColors.categoryTataBoga;
      case 'bahasa':
      case 'language':
        return AppColors.categoryBahasa;
      default:
        return AppColors.primary;
    }
  }

  IconData get categoryIconData {
    switch (category.toLowerCase()) {
      case 'las':
      case 'welding':
        return Icons.construction;
      case 'it':
      case 'komputer':
      case 'computer':
        return Icons.computer;
      case 'otomotif':
      case 'automotive':
        return Icons.directions_car;
      case 'tata busana':
      case 'fashion':
        return Icons.checkroom;
      case 'tata boga':
      case 'culinary':
        return Icons.restaurant;
      case 'bahasa':
      case 'language':
        return Icons.translate;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppAnimations.fast,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isSelected
                    ? categoryColor
                    : categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(size / 3),
                border: isSelected
                    ? null
                    : Border.all(
                        color: categoryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
              ),
              child: Icon(
                categoryIconData,
                color: isSelected ? Colors.white : categoryColor,
                size: size * 0.5,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 8),
              Text(
                category,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? categoryColor : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Category Filter Chips (Horizontal Scrollable)
class CategoryFilterChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onSelected;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // All category chip
          _buildChip(
            context,
            label: 'Semua',
            isSelected: selectedCategory == null,
            onTap: () => onSelected?.call(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                context,
                label: category,
                isSelected: selectedCategory == category,
                onTap: () => onSelected?.call(category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: AppShapes.chipRadius,
          border: isSelected
              ? null
              : Border.all(color: AppColors.outline, width: 1),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
