/// Review Card - "Kata Alumni" style with quote icon
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_typography.dart';

class ReviewCard extends StatefulWidget {
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final String reviewText;
  final double rating;
  final String courseName;
  final DateTime? completedAt;
  final bool showExpandButton;
  final int maxLines;

  const ReviewCard({
    super.key,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.reviewText,
    required this.rating,
    required this.courseName,
    this.completedAt,
    this.showExpandButton = true,
    this.maxLines = 3,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppShapes.cardRadius,
        boxShadow: AppShapes.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with quote icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quote Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppShapes.borderRadiusSM,
                ),
                child: const Center(
                  child: Text(
                    '"',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Kata Alumni label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kata Alumni',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.courseName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Rating Stars
              _buildRatingStars(),
            ],
          ),
          const SizedBox(height: 12),
          // Review Text
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              widget.reviewText,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              widget.reviewText,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          // Read more button
          if (widget.showExpandButton && widget.reviewText.length > 150)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _isExpanded ? 'Tampilkan lebih sedikit' : 'Baca selengkapnya',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Reviewer Info
          Row(
            children: [
              // Photo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                  border: Border.all(color: AppColors.outline, width: 1),
                ),
                child: widget.reviewerPhotoUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.reviewerPhotoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              _buildInitials(),
                        ),
                      )
                    : _buildInitials(),
              ),
              const SizedBox(width: 12),
              // Name and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reviewerName,
                      style: AppTypography.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.completedAt != null)
                      Text(
                        'Lulus ${_formatDate(widget.completedAt!)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    final initials = widget.reviewerName
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return Center(
      child: Text(
        initials,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < widget.rating ? Icons.star : Icons.star_border,
          color: index < widget.rating
              ? AppColors.warning
              : AppColors.textDisabled,
          size: 14,
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Booking Status Card with progress steps
class BookingStatusCard extends StatelessWidget {
  final String bookingId;
  final String courseName;
  final String lpkName;
  final DateTime bookingDate;
  final BookingStatus status;
  final VoidCallback? onTap;

  const BookingStatusCard({
    super.key,
    required this.bookingId,
    required this.courseName,
    required this.lpkName,
    required this.bookingDate,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppShapes.cardRadius,
          boxShadow: AppShapes.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseName,
                        style: AppTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lpkName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Steps
            _buildProgressSteps(),
            const SizedBox(height: 12),
            // Booking Info
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(bookingDate),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '#$bookingId',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case BookingStatus.pending:
        backgroundColor = AppColors.warningContainer;
        textColor = AppColors.warning;
        text = 'Menunggu';
        break;
      case BookingStatus.confirmed:
        backgroundColor = AppColors.infoContainer;
        textColor = AppColors.info;
        text = 'Dikonfirmasi';
        break;
      case BookingStatus.inProgress:
        backgroundColor = AppColors.primaryContainer;
        textColor = AppColors.primary;
        text = 'Berlangsung';
        break;
      case BookingStatus.completed:
        backgroundColor = AppColors.successContainer;
        textColor = AppColors.success;
        text = 'Selesai';
        break;
      case BookingStatus.cancelled:
        backgroundColor = AppColors.errorContainer;
        textColor = AppColors.error;
        text = 'Dibatalkan';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppShapes.chipRadius,
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      BookingStatus.pending,
      BookingStatus.confirmed,
      BookingStatus.inProgress,
      BookingStatus.completed,
    ];

    final currentIndex = steps.indexOf(status);
    final isCancelled = status == BookingStatus.cancelled;

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          final isActive = !isCancelled && stepIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isActive ? AppColors.success : AppColors.outline,
            ),
          );
        } else {
          // Step circle
          final stepIndex = index ~/ 2;
          final isActive = !isCancelled && stepIndex <= currentIndex;
          final isCurrentStep = !isCancelled && stepIndex == currentIndex;

          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? (isCurrentStep ? AppColors.primary : AppColors.success)
                  : AppColors.surfaceVariant,
              border: Border.all(
                color: isActive
                    ? (isCurrentStep ? AppColors.primary : AppColors.success)
                    : AppColors.outline,
                width: 2,
              ),
            ),
            child: isActive && !isCurrentStep
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : isCurrentStep
                ? Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  )
                : null,
          );
        }
      }),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }
