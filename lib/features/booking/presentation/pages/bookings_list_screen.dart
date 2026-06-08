import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../data/models/booking_model.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _bookingsFuture = _fetchBookings();
  }

  Future<List<BookingModel>> _fetchBookings() async {
    try {
      final apiService = ApiService();
      final result = await apiService.getBookings();
      if (result['success'] == true) {
        final List data = result['data']['data'] ?? result['data'] ?? [];
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
    setState(() => _bookingsFuture = _fetchBookings());
    await _bookingsFuture;
  }

  List<BookingModel> _getFiltered(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _bookings.where((b) => b.isPending).toList();
      case 2:
        return _bookings.where((b) => b.isConfirmed || b.isCompleted).toList();
      case 3:
        return _bookings.where((b) => b.isCancelled).toList();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: FutureBuilder<List<BookingModel>>(
            future: _bookingsFuture,
            builder: (context, snap) {
              final data = snap.data ?? [];
              final pendingCount = data.where((b) => b.isPending).length;
              final aktifCount =
                  data.where((b) => b.isConfirmed || b.isCompleted).length;
              final riwayatCount = data.where((b) => b.isCancelled).length;
              return TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                onTap: (_) => setState(() {}),
                tabs: [
                  const Tab(text: 'Semua'),
                  Tab(
                      text:
                          'Menunggu${pendingCount > 0 ? ' ($pendingCount)' : ''}'),
                  Tab(text: 'Aktif${aktifCount > 0 ? ' ($aktifCount)' : ''}'),
                  Tab(
                      text:
                          'Riwayat${riwayatCount > 0 ? ' ($riwayatCount)' : ''}'),
                ],
              );
            },
          ),
        ),
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final filtered = _getFiltered(_tabController.index);
              if (filtered.isEmpty) return _buildEmpty();
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

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(error,
              style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _refresh, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Belum ada pesanan', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text('Daftarkan diri ke kursus favoritmu!',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
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

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
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
          // ✅ FIX: Semua card bisa diklik
          onTap: () => context.push(AppRouter.pendingBookingPath(booking.id)),
          borderRadius: AppShapes.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: kode + badge status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${booking.code.length > 8 ? booking.code.substring(0, 8) : booking.code}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: AppShapes.chipRadius,
                      ),
                      child: Text(
                        booking.statusLabel,
                        style:
                            AppTypography.badge.copyWith(color: _statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Nama kursus — ✅ FIX: dari schedule.courseTitle
                Text(
                  booking.schedule?.courseTitle ?? 'Kursus',
                  style: AppTypography.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // LPK — ✅ FIX: dari schedule.lpkName
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.schedule?.lpkName ?? 'LPK Mitra',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (booking.schedule?.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppShapes.chipRadius,
                        ),
                        child: Text(
                          booking.schedule!.categoryName!,
                          style: AppTypography.badge
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Jadwal
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      booking.schedule?.startDate != null
                          ? '${booking.schedule!.startDate}'
                              '${booking.schedule!.endDate != null ? ' – ${booking.schedule!.endDate}' : ''}'
                          : 'Belum ditentukan',
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary, fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Harga + hint klik
                Row(
                  children: [
                    Text(
                      _formatRupiah(booking.amount),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text('Lihat detail',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.primary, fontSize: 11)),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.primary),
                  ],
                ),

                // Tombol untuk pending
                if (booking.isPending) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Cek Status & Bayar'),
                      onPressed: () => context
                          .push(AppRouter.pendingBookingPath(booking.id)),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
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
