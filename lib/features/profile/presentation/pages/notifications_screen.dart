import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Notifikasi settings toggles
  bool _promoNotif = true;
  bool _bookingNotif = true;
  bool _paymentNotif = true;
  bool _courseUpdateNotif = false;

  bool _systemNotif = true;

  // Inbox notifikasi
  final List<_NotifItem> _inbox = [
    _NotifItem(
      id: '1',
      title: 'Booking Dikonfirmasi',
      body: 'Booking kursus Las Listrik Anda telah dikonfirmasi oleh LPK Mitra Karya. Kelas dimulai 15 Februari 2025.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.check_circle_outline,
      color: AppColors.success,
      isRead: false,
      type: 'booking',
    ),
    _NotifItem(
      id: '2',
      title: 'Pembayaran Berhasil',
      body: 'Pembayaran Rp 1.500.000 untuk kursus Las Listrik berhasil diproses.',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      icon: Icons.payment,
      color: AppColors.primary,
      isRead: false,
      type: 'payment',
    ),
    _NotifItem(
      id: '3',
      title: 'Promo Spesial!',
      body: 'Diskon 30% untuk semua kursus IT bulan ini. Gunakan kode: SKILLOKA30',
      time: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.local_offer_outlined,
      color: AppColors.secondary,
      isRead: true,
      type: 'promo',
    ),
    _NotifItem(
      id: '4',
      title: 'Kursus Selesai!',
      body: 'Selamat! Anda telah menyelesaikan kursus Komputer Dasar. Sertifikat Anda sudah tersedia.',
      time: DateTime.now().subtract(const Duration(days: 3)),
      icon: Icons.workspace_premium_outlined,
      color: AppColors.warning,
      isRead: true,
      type: 'course',
    ),

  ];

  int get _unreadCount => _inbox.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notifikasi'),
              if (_unreadCount > 0)
                Text(
                  '$_unreadCount belum dibaca',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (_unreadCount > 0)
              TextButton(
                onPressed: _markAllRead,
                child: const Text('Baca Semua'),
              ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Inbox'),
              Tab(text: 'Pengaturan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInbox(),
            _buildSettings(),
          ],
        ),
      ),
    );
  }

  void _markAllRead() {
    setState(() {
      for (final n in _inbox) {
        n.isRead = true;
      }
    });
  }

  Widget _buildInbox() {
    if (_inbox.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text('Tidak ada notifikasi', style: AppTypography.titleSmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _inbox.length,
      itemBuilder: (context, i) {
        final notif = _inbox[i];
        return _buildNotifTile(notif);
      },
    );
  }

  Widget _buildNotifTile(_NotifItem notif) {
    final timeStr = _formatTime(notif.time);
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _inbox.removeWhere((n) => n.id == notif.id));
      },
      child: InkWell(
        onTap: () {
          setState(() => notif.isRead = true);
        },
        child: Container(
          color: notif.isRead ? null : AppColors.primaryContainer.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notif.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(notif.icon, color: notif.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(
            title: 'Transaksi',
            items: [
              _SettingToggle(
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
                title: 'Status Booking',
                subtitle: 'Konfirmasi & perubahan status booking',
                value: _bookingNotif,
                onChanged: (v) => setState(() => _bookingNotif = v),
              ),
              _SettingToggle(
                icon: Icons.payment,
                color: AppColors.success,
                title: 'Pembayaran',
                subtitle: 'Konfirmasi dan notifikasi pembayaran',
                value: _paymentNotif,
                onChanged: (v) => setState(() => _paymentNotif = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            title: 'Konten & Kursus',
            items: [
              _SettingToggle(
                icon: Icons.school_outlined,
                color: AppColors.categoryIT,
                title: 'Update Kursus',
                subtitle: 'Kursus baru & perubahan jadwal',
                value: _courseUpdateNotif,
                onChanged: (v) => setState(() => _courseUpdateNotif = v),
              ),

            ],
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            title: 'Promosi & Sistem',
            items: [
              _SettingToggle(
                icon: Icons.local_offer_outlined,
                color: AppColors.secondary,
                title: 'Promo & Diskon',
                subtitle: 'Penawaran spesial dan promo terbaru',
                value: _promoNotif,
                onChanged: (v) => setState(() => _promoNotif = v),
              ),
              _SettingToggle(
                icon: Icons.info_outline,
                color: AppColors.textTertiary,
                title: 'Sistem',
                subtitle: 'Pembaruan aplikasi dan keamanan',
                value: _systemNotif,
                onChanged: (v) => setState(() => _systemNotif = v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoContainer,
              borderRadius: AppShapes.borderRadiusMD,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Beberapa notifikasi penting seperti keamanan akun tidak dapat dimatikan.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<_SettingToggle> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppShapes.cardRadius,
        boxShadow: AppShapes.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...items.map(
            (item) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: AppShapes.borderRadiusSM,
                        ),
                        child: Icon(item.icon, color: item.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: AppTypography.labelLarge),
                            Text(
                              item.subtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: item.value,
                        onChanged: item.onChanged,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryContainer,
                      ),
                    ],
                  ),
                ),
                if (items.last != item)
                  const Divider(height: 1, indent: 64),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }
}

class _NotifItem {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final IconData icon;
  final Color color;
  bool isRead;
  final String type;

  _NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    required this.isRead,
    required this.type,
  });
}

class _SettingToggle {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
