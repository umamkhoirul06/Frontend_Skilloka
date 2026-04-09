import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<_Certificate> _allCerts = [
    _Certificate(
      id: '1',
      title: 'Las Listrik Dasar',
      lpkName: 'LPK Mitra Karya',
      issuedDate: DateTime(2024, 6, 20),
      status: 'active',
      category: 'Las',
      number: 'SKL/2024/001/MINT',
      color: AppColors.categoryLas,
    ),
    _Certificate(
      id: '2',
      title: 'Komputer Dasar & Office',
      lpkName: 'LPK Digital Nusantara',
      issuedDate: DateTime(2024, 1, 10),
      status: 'active',
      category: 'IT',
      number: 'SKL/2024/045/DIGI',
      color: AppColors.categoryIT,
    ),
    _Certificate(
      id: '3',
      title: 'Servis Sepeda Motor',
      lpkName: 'LPK Auto Teknologi',
      issuedDate: DateTime(2023, 9, 5),
      status: 'expired',
      category: 'Otomotif',
      number: 'SKL/2023/112/AUTO',
      color: AppColors.categoryOtomotif,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _allCerts.where((c) => c.status == 'active').toList();
    final expired = _allCerts.where((c) => c.status == 'expired').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sertifikat Saya'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: 'Aktif (${active.length})'),
            Tab(text: 'Kadaluwarsa (${expired.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CertList(certs: active, onDownload: _downloadCert),
          _CertList(certs: expired, onDownload: _downloadCert),
        ],
      ),
    );
  }

  void _downloadCert(_Certificate cert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mengunduh: ${cert.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusMD),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _CertList extends StatelessWidget {
  final List<_Certificate> certs;
  final ValueChanged<_Certificate> onDownload;

  const _CertList({required this.certs, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    if (certs.isEmpty) {
      return _buildEmpty();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certs.length,
      itemBuilder: (context, i) => _CertCard(
        cert: certs[i],
        onDownload: () => onDownload(certs[i]),
        onShare: () {},
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              size: 40,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Belum ada sertifikat', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Selesaikan kursus untuk mendapatkan\nsertifikat resmi',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final _Certificate cert;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const _CertCard({
    required this.cert,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = cert.status == 'expired';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppShapes.cardRadius,
        boxShadow: AppShapes.shadowSM,
      ),
      child: Stack(
        children: [
          // Accent bar kiri
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: isExpired ? AppColors.textDisabled : cert.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? AppColors.surfaceVariant
                            : cert.color.withValues(alpha: 0.1),
                        borderRadius: AppShapes.borderRadiusSM,
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        size: 22,
                        color: isExpired ? AppColors.textTertiary : cert.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cert.title,
                            style: AppTypography.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            cert.lpkName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? AppColors.surfaceVariant
                            : AppColors.successContainer,
                        borderRadius: AppShapes.chipRadius,
                      ),
                      child: Text(
                        isExpired ? 'Kadaluwarsa' : 'Aktif',
                        style: AppTypography.badge.copyWith(
                          color: isExpired
                              ? AppColors.textTertiary
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Details
                _buildInfoRow(Icons.numbers, 'No. Sertifikat', cert.number),
                const SizedBox(height: 4),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Diterbitkan',
                  '${cert.issuedDate.day.toString().padLeft(2, '0')} '
                      '${_monthName(cert.issuedDate.month)} '
                      '${cert.issuedDate.year}',
                ),

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Bagikan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.outline),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isExpired ? null : onDownload,
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('Unduh PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[month];
  }
}

class _Certificate {
  final String id;
  final String title;
  final String lpkName;
  final DateTime issuedDate;
  final String status;
  final String category;
  final String number;
  final Color color;

  const _Certificate({
    required this.id,
    required this.title,
    required this.lpkName,
    required this.issuedDate,
    required this.status,
    required this.category,
    required this.number,
    required this.color,
  });
}
