/// Modern interactive Empty State and Error State component with floating animations
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_typography.dart';
import '../../animations/app_animations.dart';

enum EmptyStateType {
  general,
  search,
  courses,
  completed,
  favorite,
  booking,
  notification,
  error,
}

class AppEmptyState extends StatefulWidget {
  final EmptyStateType type;
  final String title;
  final String? message;
  final IconData? customIcon;
  final Color? iconColor;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final List<String>? suggestionChips;
  final ValueChanged<String>? onSuggestionTap;
  final EdgeInsetsGeometry padding;

  const AppEmptyState({
    super.key,
    this.type = EmptyStateType.general,
    required this.title,
    this.message,
    this.customIcon,
    this.iconColor,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.suggestionChips,
    this.onSuggestionTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
  });

  // Factory constructors for common cases
  factory AppEmptyState.search({
    Key? key,
    String title = 'Tidak ada hasil ditemukan',
    String? message = 'Coba kata kunci lain atau pilih rekomendasi kategori berikut.',
    List<String>? suggestions,
    ValueChanged<String>? onSuggestionTap,
    VoidCallback? onReset,
  }) {
    return AppEmptyState(
      key: key,
      type: EmptyStateType.search,
      title: title,
      message: message,
      actionLabel: onReset != null ? 'Reset Pencarian' : null,
      actionIcon: Icons.refresh_rounded,
      onAction: onReset,
      suggestionChips: suggestions,
      onSuggestionTap: onSuggestionTap,
    );
  }

  factory AppEmptyState.courses({
    Key? key,
    required String title,
    String? message,
    String actionLabel = 'Eksplor Kursus',
    VoidCallback? onExplore,
  }) {
    return AppEmptyState(
      key: key,
      type: EmptyStateType.courses,
      title: title,
      message: message,
      actionLabel: actionLabel,
      actionIcon: Icons.explore_outlined,
      onAction: onExplore,
    );
  }

  factory AppEmptyState.completed({
    Key? key,
    String title = 'Belum ada kursus selesai',
    String? message = 'Selesaikan modul kursusmu untuk membuka sertifikat kompetensi resmi.',
    VoidCallback? onExplore,
  }) {
    return AppEmptyState(
      key: key,
      type: EmptyStateType.completed,
      title: title,
      message: message,
      actionLabel: onExplore != null ? 'Lihat Kursus Berjalan' : null,
      actionIcon: Icons.play_lesson_outlined,
      onAction: onExplore,
    );
  }

  factory AppEmptyState.favorite({
    Key? key,
    String title = 'Belum ada favorit tersimpan',
    String? message = 'Tandai kursus atau LPK idamanmu dengan ikon hati agar mudah ditemukan.',
    VoidCallback? onExplore,
  }) {
    return AppEmptyState(
      key: key,
      type: EmptyStateType.favorite,
      title: title,
      message: message,
      actionLabel: onExplore != null ? 'Temukan Kursus Menarik' : null,
      actionIcon: Icons.search_rounded,
      onAction: onExplore,
    );
  }

  factory AppEmptyState.error({
    Key? key,
    String title = 'Gagal Memuat Data',
    String? message = 'Terjadi kendala saat menghubungkan ke server. Silakan coba beberapa saat lagi.',
    VoidCallback? onRetry,
  }) {
    return AppEmptyState(
      key: key,
      type: EmptyStateType.error,
      title: title,
      message: message,
      actionLabel: onRetry != null ? 'Coba Lagi' : null,
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
    );
  }

  @override
  State<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends State<AppEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  IconData _getDefaultIcon() {
    if (widget.customIcon != null) return widget.customIcon!;
    switch (widget.type) {
      case EmptyStateType.search:
        return Icons.search_off_rounded;
      case EmptyStateType.courses:
        return Icons.school_outlined;
      case EmptyStateType.completed:
        return Icons.workspace_premium_outlined;
      case EmptyStateType.favorite:
        return Icons.favorite_border_rounded;
      case EmptyStateType.booking:
        return Icons.receipt_long_outlined;
      case EmptyStateType.notification:
        return Icons.notifications_none_rounded;
      case EmptyStateType.error:
        return Icons.cloud_off_rounded;
      case EmptyStateType.general:
        return Icons.inbox_outlined;
    }
  }

  Color _getPrimaryColor() {
    if (widget.iconColor != null) return widget.iconColor!;
    switch (widget.type) {
      case EmptyStateType.search:
        return AppColors.primary;
      case EmptyStateType.courses:
        return AppColors.primary;
      case EmptyStateType.completed:
        return AppColors.secondary;
      case EmptyStateType.favorite:
        return AppColors.error;
      case EmptyStateType.booking:
        return AppColors.primary;
      case EmptyStateType.notification:
        return AppColors.secondary;
      case EmptyStateType.error:
        return AppColors.danger;
      case EmptyStateType.general:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getPrimaryColor();
    final icon = _getDefaultIcon();

    return Center(
      child: SingleChildScrollView(
        padding: widget.padding,
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating Animated Illustration Hero
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Outer Glow Halo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: isDark ? 0.08 : 0.06),
                    ),
                  ),
                  // Middle Ring
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: isDark ? 0.14 : 0.12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Center Icon Badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: isDark ? 0.3 : 0.2),
                          color.withValues(alpha: isDark ? 0.15 : 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: color,
                    ),
                  ),
                  // Mini Sparkle Indicator
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryFor(context),
                letterSpacing: -0.2,
              ),
            ),

            // Subtitle / Message
            if (widget.message != null && widget.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    height: 1.45,
                  ),
                ),
              ),
            ],

            // Suggestion Chips (if available, e.g. for search empty states)
            if (widget.suggestionChips != null &&
                widget.suggestionChips!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Kategori Populer:',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: widget.suggestionChips!.map((cat) {
                  return ActionChip(
                    label: Text(cat),
                    backgroundColor: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                    labelStyle: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    shape: const StadiumBorder(),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.onSuggestionTap?.call(cat);
                    },
                  );
                }).toList(),
              ),
            ],

            // Action Buttons
            if (widget.onAction != null && widget.actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onAction?.call();
                },
                icon: Icon(
                  widget.actionIcon ?? Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(widget.actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: color.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppShapes.buttonRadius,
                  ),
                ),
              ),
            ],

            // Secondary Action (optional)
            if (widget.onSecondaryAction != null &&
                widget.secondaryActionLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onSecondaryAction?.call();
                },
                child: Text(
                  widget.secondaryActionLabel!,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

