import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _active = [];
  List<Map<String, dynamic>> _expired = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCertificates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCertificates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.getCertificates();
      debugPrint('====================');
debugPrint('CERTIFICATE RESULT');
debugPrint(result.toString());
debugPrint('====================');
      if (!mounted) return;
      if (result['success']) {
        final raw = result['data'];
        final data = raw['data'] ?? raw;
        final all = <Map<String, dynamic>>[];

        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) all.add(item);
          }
        } else if (data is Map) {
          final list = data['certificates'] ?? data['data'] ?? [];
          if (list is List) {
            for (final item in list) {
              if (item is Map<String, dynamic>) all.add(item);
            }
          }
        }

        setState(() {
          _active = all
              .where((c) =>
                  (c['status'] ?? '').toString().toLowerCase() == 'active' ||
                  (c['status'] ?? '').toString().toLowerCase() == 'aktif')
              .toList();
          _expired = all
              .where((c) =>
                  (c['status'] ?? '').toString().toLowerCase() == 'expired' ||
                  (c['status'] ?? '').toString().toLowerCase() == 'kadaluwarsa')
              .toList();
          _isLoading = false;
        });
      } else {
  setState(() {
    _active = [];
    _expired = [];
    _isLoading = false;
    _error = null;
  });
}
    } catch (e) {
  if (mounted) {
    setState(() {
      _active = [];
      _expired = [];
      _error = null;
      _isLoading = false;
    });
  }
}
  }

  @override
  Widget build(BuildContext context) {
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
            Tab(text: 'Aktif (${_active.length})'),
            Tab(text: 'Kadaluwarsa (${_expired.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_active),
                    _buildList(_expired),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(_error ?? 'Terjadi kesalahan', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _fetchCertificates, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> certs) {
    if (certs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant, shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_outlined,
                  size: 40, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text('Belum ada sertifikat', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Selesaikan kursus untuk mendapatkan\nsertifikat resmi',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCertificates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: certs.length,
        itemBuilder: (context, i) => _buildCertCard(certs[i]),
      ),
    );
  }

  Widget _buildCertCard(Map<String, dynamic> cert) {
    final title = cert['title'] ?? cert['course_name'] ?? cert['name'] ?? '-';
    final lpkName = cert['lpk_name'] ?? cert['lpk']?['name'] ?? '-';
    final number =
        cert['certificate_number'] ?? cert['number'] ?? cert['code'] ?? '-';
    final issuedRaw =
        cert['issued_at'] ?? cert['created_at'] ?? cert['issued_date'] ?? '';
    final issuedDate = _parseDate(issuedRaw);
    final isExpired =
        (cert['status'] ?? '').toString().toLowerCase() == 'expired' ||
            (cert['status'] ?? '').toString().toLowerCase() == 'kadaluwarsa';
    final color = isExpired ? AppColors.textDisabled : AppColors.primary;

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
                color: color,
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
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppShapes.borderRadiusSM,
                      ),
                      child: Icon(Icons.workspace_premium,
                          size: 22,
                          color: isExpired
                              ? AppColors.textTertiary
                              : AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: AppTypography.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          Text(lpkName,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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

                // Detail
                _buildInfoRow(Icons.numbers, 'No. Sertifikat', number),
                const SizedBox(height: 4),
                _buildInfoRow(
                    Icons.calendar_today_outlined, 'Diterbitkan', issuedDate),

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
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
                        onPressed: isExpired ? null : () => _downloadCert(cert),
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
        Text('$label: ',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiary)),
        Expanded(
          child: Text(value,
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  String _parseDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return '${dt.day.toString().padLeft(2, '0')} '
          '${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  void _downloadCert(Map<String, dynamic> cert) {
    final title = cert['title'] ?? cert['name'] ?? 'Sertifikat';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.download_done, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
            child: Text('Mengunduh: $title',
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusMD),
      margin: const EdgeInsets.all(16),
    ));
  }
}
