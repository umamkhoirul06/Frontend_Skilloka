import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';

/// Review Screen — PRD 8.11
/// Tampil setelah kursus selesai, user bisa beri rating & ulasan
class ReviewScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String? lpkName;

  const ReviewScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.lpkName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _commentController = TextEditingController();

  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _submitted = false;
  List<Map<String, dynamic>> _existingReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      final result = await _api.getCourseReviews(widget.courseId);
      if (result['success'] == true && mounted) {
        final data = result['data'];
        List<dynamic> rawList = [];
        if (data is List) rawList = data;
        else if (data is Map) rawList = data['data'] ?? [];
        setState(() {
          _existingReviews = rawList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bintang terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _api.createReview(
        courseId: widget.courseId,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal mengirim ulasan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Koneksi bermasalah: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Ulasan Kursus', style: AppTypography.titleLarge),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_submitted) ...[
                    _buildSubmitForm(),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildSuccessState(),
                    const SizedBox(height: 32),
                  ],
                  if (_existingReviews.isNotEmpty) ...[
                    Text('Ulasan Lainnya',
                        style: AppTypography.titleMedium),
                    const SizedBox(height: 12),
                    ..._existingReviews
                        .map((r) => _ReviewCard(review: r))
                        .toList(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSubmitForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.courseTitle,
                        style: AppTypography.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (widget.lpkName != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.lpkName!,
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Rating stars
        Text('Rating Kursus', style: AppTypography.labelLarge),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final starIndex = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = starIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  starIndex <= _selectedRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 40,
                  color: starIndex <= _selectedRating
                      ? AppColors.warning
                      : AppColors.outline,
                ),
              ),
            );
          }),
        ),
        if (_selectedRating > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              _ratingLabel(_selectedRating),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Comment
        Text('Ulasan (Opsional)', style: AppTypography.labelLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLines: 5,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Ceritakan pengalamanmu mengikuti kursus ini...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),

        // Submit
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _isSubmitting || _selectedRating == 0 ? null : _submitReview,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Kirim Ulasan',
                    style: AppTypography.labelLarge
                        .copyWith(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 56, color: AppColors.success),
          const SizedBox(height: 16),
          Text('Ulasan Terkirim!',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.success,
              )),
          const SizedBox(height: 8),
          Text(
            'Terima kasih atas ulasan kamu. Ini sangat membantu pengguna lain.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return '';
    }
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final name = review['user']?['name']?.toString() ??
        review['user_name']?.toString() ??
        'Anonim';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment']?.toString() ??
        review['review']?.toString() ?? '';
    final date = review['created_at']?.toString() ?? '';
    final avatarUrl = review['user']?['avatar']?.toString() ??
        review['avatar_url']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage:
                    avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.titleSmall),
                    if (date.isNotEmpty)
                      Text(
                        _formatDate(date),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: i < rating
                        ? AppColors.warning
                        : AppColors.outline,
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
