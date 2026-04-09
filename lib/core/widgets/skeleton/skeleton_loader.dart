/// Skeleton Loader with shimmer effect
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant,
      highlightColor: isDark ? AppColors.outlineDark : AppColors.outline,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppShapes.borderRadiusSM,
        ),
      ),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final int lines;
  final double spacing;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.lines = 1,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        // Make the last line shorter for natural look
        final lineWidth = index == lines - 1 && lines > 1
            ? (width == double.infinity ? 200.0 : width * 0.7)
            : width;

        return Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? spacing : 0),
          child: SkeletonLoader(width: lineWidth, height: height),
        );
      }),
    );
  }
}

/// Skeleton for avatar/circle
class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}

/// Skeleton for Course Card
class SkeletonCourseCard extends StatelessWidget {
  const SkeletonCourseCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant,
      highlightColor: isDark ? AppColors.outlineDark : AppColors.outline,
      period: const Duration(milliseconds: 1200),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: AppShapes.cardRadius,
          boxShadow: AppShapes.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppShapes.radiusLG),
                  topRight: Radius.circular(AppShapes.radiusLG),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppShapes.borderRadiusSM,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppShapes.borderRadiusSM,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rating & Distance
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppShapes.borderRadiusSM,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 50,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppShapes.borderRadiusSM,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Container(
                    width: 100,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppShapes.borderRadiusSM,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for LPK Card
class SkeletonLPKCard extends StatelessWidget {
  const SkeletonLPKCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant,
      highlightColor: isDark ? AppColors.outlineDark : AppColors.outline,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: AppShapes.cardRadius,
          boxShadow: AppShapes.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppShapes.borderRadiusMD,
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppShapes.borderRadiusSM,
              ),
            ),
            const SizedBox(height: 8),
            // Badge
            Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppShapes.chipRadius,
              ),
            ),
            const SizedBox(height: 8),
            // Address
            Container(
              width: 150,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppShapes.borderRadiusSM,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Hero Banner
class SkeletonBanner extends StatelessWidget {
  final double height;

  const SkeletonBanner({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant,
      highlightColor: isDark ? AppColors.outlineDark : AppColors.outline,
      period: const Duration(milliseconds: 1200),
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppShapes.cardRadius,
        ),
      ),
    );
  }
}

/// Skeleton for List Tile
class SkeletonListTile extends StatelessWidget {
  final bool showAvatar;
  final bool showSubtitle;

  const SkeletonListTile({
    super.key,
    this.showAvatar = true,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant,
      highlightColor: isDark ? AppColors.outlineDark : AppColors.outline,
      period: const Duration(milliseconds: 1200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (showAvatar) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppShapes.borderRadiusSM,
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppShapes.borderRadiusSM,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of skeleton course cards
class SkeletonCourseGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const SkeletonCourseGrid({
    super.key,
    this.itemCount = 4,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonCourseCard(),
    );
  }
}

/// Horizontal list of skeleton LPK cards
class SkeletonLPKList extends StatelessWidget {
  final int itemCount;

  const SkeletonLPKList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => const SkeletonLPKCard(),
      ),
    );
  }
}
