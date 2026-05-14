/// Bookings List Screen - Halaman Daftar Pesanan Saya
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/api_service.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<BookingModel>> _bookingsFuture;
  List<BookingModel> _bookings = [];

  final List<String> _tabs = ['Semua', 'Menunggu', 'Aktif', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _bookingsFuture = _fetchBookings();
  }

  Future<List<BookingModel>> _fetchBookings() async {
    try {
      final apiService = ApiService();
      final result = await apiService.getBookings();
      if (result['success']) {
        final List data = result['data']['data'] ?? [];
        _bookings = data.map((e) => BookingModel.fromJson(e)).toList();
        return _bookings;
      } else {
        throw result['message'] ?? 'Gagal memuat pesanan';
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _bookingsFuture = _fetchBookings();
    });
    await _bookingsFuture;
  }

  List<BookingModel> _getFilteredBookings(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _bookings.where((b) => b.isPending).toList();
      case 2:
        return _bookings.where((b) => b.isConfirmed).toList();
      case 3:
        return _bookings.where((b) => b.isCompleted).toList();
      default:
        return _bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          onTap: (_) => setState(() {}),
        ),
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _BookingListSkeleton();
          }

          if (snapshot.hasError) {
            return _buildError(context, snapshot.error.toString());
          }

          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final filtered = _getFilteredBookings(_tabController.index);
              if (filtered.isEmpty) {
                return _buildEmpty(context);
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _BookingCard(booking: filtered[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(error, style: AppTypography.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text('Belum ada pesanan', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Daftarkan diri ke kursus favoritmu!',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go(AppRouter.home),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Cari Kursus'),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppShapes.cardRadius,
        boxShadow: AppShapes.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppShapes.cardRadius,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to booking detail
          },
          borderRadius: AppShapes.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Kode booking + status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.code,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: AppShapes.chipRadius,
                      ),
                      child: Text(
                        booking.statusLabel,
                        style: AppTypography.badge.copyWith(
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Nama kursus
                Text(
                  booking.schedule?.courseTitle ?? 'Kursus',
                  style: AppTypography.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Nama LPK + Kategori
                Row(
                  children: [
                    const Icon(
                      Icons.business_outlined,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.schedule?.lpkName ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (booking.schedule?.categoryName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppShapes.chipRadius,
                        ),
                        child: Text(
                          booking.schedule!.categoryName!,
                          style: AppTypography.badge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Jadwal & Harga
                Row(
                  children: [
                    if (booking.schedule?.startDate != null) ...[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${booking.schedule!.startDate} – ${booking.schedule!.endDate ?? ''}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'Rp ${booking.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                // Tombol aksi untuk status pending
                if (booking.isPending) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Batalkan'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Bayar Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingListSkeleton extends StatelessWidget {
  const _BookingListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, _) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppShapes.cardRadius,
          boxShadow: AppShapes.shadowSM,
        ),
      ),
    );
  }
}
