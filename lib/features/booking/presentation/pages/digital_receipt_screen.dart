import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';

/// Struk Pembayaran Digital Skilloka
/// Memiliki 2 Template:
/// 1. Printer Kecil (Thermal Receipt POS 58mm / 80mm)
/// 2. Printer Besar (Invoice Resmi A4 Standard Format)
class DigitalReceiptScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? initialData;

  const DigitalReceiptScreen({
    super.key,
    required this.bookingId,
    this.initialData,
  });

  @override
  State<DigitalReceiptScreen> createState() => _DigitalReceiptScreenState();
}

class _DigitalReceiptScreenState extends State<DigitalReceiptScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  String _bookingCode = '-';
  String _courseTitle = 'Pelatihan Vokasi';
  String _lpkName = 'LPK Mitra Skilloka';
  String _userName = 'Peserta Skilloka';
  String _userPhone = '-';
  double _price = 0;
  double _adminFee = 5000;
  double _totalAmount = 0;
  String _paymentMethod = 'QRIS / Midtrans';
  String _paidAt = '';
  final String _scheduleDate = 'Menyesuaikan Jadwal LPK';

  String get _safeBookingId =>
      widget.bookingId.replaceAll(':id', '').replaceAll(':', '');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _paidAt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.now());
    if (widget.initialData != null) {
      _applyData(widget.initialData!);
      _isLoading = false;
    } else {
      _fetchReceiptData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyData(Map<String, dynamic> data) {
    final course = data['course'] ?? data['schedule'] ?? {};
    final user = data['user'] ?? {};

    final courseTitle = (course['title'] ?? course['course_title'] ?? 'Kursus Pelatihan').toString();
    final lpkName = (course['lpk']?['name'] ?? course['lpk_name'] ?? 'LPK Mitra').toString();
    final bookingCode = (data['code'] ?? data['booking_id'] ?? widget.bookingId).toString();
    final userName = (user['name'] ?? data['name'] ?? 'Siswa').toString();
    final userPhone = (user['phone'] ?? data['phone'] ?? '-').toString();

    final rawPrice = double.tryParse((data['course_price'] ?? course['price'] ?? '0').toString()) ?? 0.0;
    final rawTotal = double.tryParse((data['total_price'] ?? data['amount'] ?? rawPrice).toString()) ?? rawPrice;
    final double adminFee = rawTotal > rawPrice ? (rawTotal - rawPrice) : 5000.0;

    final payMethod = (data['payment_method'] ?? 'QRIS Midtrans').toString().toUpperCase();
    final createdAt = data['created_at'] != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now())
        : _paidAt;

    setState(() {
      _courseTitle = courseTitle;
      _lpkName = lpkName;
      _bookingCode = bookingCode;
      _userName = userName;
      _userPhone = userPhone;
      _price = rawPrice > 0 ? rawPrice : (rawTotal - adminFee);
      _adminFee = adminFee;
      _totalAmount = rawTotal > 0 ? rawTotal : (_price + _adminFee);
      _paymentMethod = payMethod;
      _paidAt = createdAt;
      _isLoading = false;
    });
  }

  Future<void> _fetchReceiptData() async {
    try {
      final apiClient = sl<ApiClient>();
      final res = await apiClient.get('/bookings/$_safeBookingId');
      if (res.statusCode == 200) {
        final data = res.data['data'] as Map<String, dynamic>;
        _applyData(data);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(double amount) {
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}';
  }

  void _printReceipt() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.print_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tabController.index == 0
                    ? 'Menyiapkan cetak ke Printer Kasir Thermal (58/80mm)...'
                    : 'Menyiapkan cetak Invoice Standar A4...',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareReceipt() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Struk pembayaran berhasil disalin ke papan klip.')),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Struk Pembayaran Digital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan Struk',
            onPressed: _shareReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Cetak Struk',
            onPressed: _printReceipt,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 15),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Struk Thermal (POS)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_rounded, size: 15),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Faktur A4 Resmi',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSmallThermalTemplate(context),
                _buildLargeA4InvoiceTemplate(context),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(top: BorderSide(color: AppColors.outline.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareReceipt,
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Bagikan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _printReceipt,
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Cetak Struk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TEMPLATE 1: PRINTER KECIL (THERMAL RECEIPT 58mm / 80mm)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSmallThermalTemplate(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: 340, // Lebar proporsional simulasi kertas thermal roll 80mm
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Efek robekan gerigi kertas atas
              _buildThermalPaperTearEdge(top: true),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  children: [
                    // Header Toko / Skilloka
                    const Text(
                      'SKILLOKA INDONESIA',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Pusat Pelatihan Vokasi Indramayu\nWebsite: skilloka.my.id',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDashedLine(),
                    const SizedBox(height: 8),

                    // Metadata Transaksi
                    _buildThermalRow('NO BUKTI', '#${_bookingCode.toUpperCase()}'),
                    _buildThermalRow('TANGGAL', _paidAt),
                    _buildThermalRow('KASIR/SISTEM', 'ONLINE / MIDTRANS'),
                    _buildThermalRow('SISWA', _userName.toUpperCase()),
                    _buildThermalRow('NO HP', _userPhone),
                    const SizedBox(height: 8),
                    _buildDashedLine(),
                    const SizedBox(height: 10),

                    // Rincian Item Kursus
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _courseTitle,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mitra: $_lpkName',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildThermalRow('1 x Kursus Reguler', _formatRupiah(_price)),
                    _buildThermalRow('Biaya Platform / Admin', _formatRupiah(_adminFee)),
                    const SizedBox(height: 8),
                    _buildDashedLine(),
                    const SizedBox(height: 8),

                    // Total & Status
                    _buildThermalRow(
                      'TOTAL BAYAR',
                      _formatRupiah(_totalAmount),
                      isBold: true,
                      fontSize: 15,
                    ),
                    _buildThermalRow('METODE', _paymentMethod),
                    const SizedBox(height: 10),

                    // Badge LUNAS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '*** L U N A S ***',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 2,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code Verifikasi POS
                    QrImageView(
                      data: 'SKILLOKA-VERIFIED:$_bookingCode:$_totalAmount',
                      version: QrVersions.auto,
                      size: 110,
                      gapless: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KODE REF: $_bookingCode',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 12),
                    _buildDashedLine(),
                    const SizedBox(height: 8),

                    // Footer Struk Kasir
                    const Text(
                      'Simpan struk ini sebagai bukti pembayaran sah.\nTunjukkan ke admin LPK saat hari pelatihan.\n-- LAYANAN KONSUMEN: 0812-3456-7890 --',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),

              // Efek robekan gerigi kertas bawah
              _buildThermalPaperTearEdge(top: false),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TEMPLATE 2: PRINTER BESAR (INVOICE RESMI A4 STANDARD FORMAT)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLargeA4InvoiceTemplate(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kop Surat Resmi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SKILLOKA INDONESIA',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Platform Kursus & Pelatihan Vokasi Resmi\nIndramayu, Jawa Barat • support@skilloka.my.id',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'FAKTUR RESMI',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#INV-${_bookingCode.toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0), thickness: 1.2),
              const SizedBox(height: 12),

              // Bagian Info Tagihan & Transaksi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DITUJUKAN KEPADA:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'No. HP: $_userPhone',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Status: Terverifikasi',
                            style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RINCIAN TRANSAKSI:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tgl: $_paidAt',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Metode: $_paymentMethod',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jadwal: $_scheduleDate',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tabel Item Pembayaran (Responsive & Non-Breaking)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  children: [
                    // Header Tabel
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              'NO',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Color(0xFF475569)),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              'DESKRIPSI KURSUS',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Color(0xFF475569)),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'MITRA LPK',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Color(0xFF475569)),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'TOTAL',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFCBD5E1)),
                    // Isi Baris
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 22,
                            child: Text('1', style: TextStyle(fontSize: 11, color: Color(0xFF0F172A))),
                          ),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _courseTitle,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Paket Pelatihan + Sertifikat Resmi',
                                  style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _lpkName,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 3,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                _formatRupiah(_price),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Rincian Kalkulasi Biaya (Full Width Table)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildInvoiceSummaryRow('Subtotal Biaya Kursus:', _formatRupiah(_price)),
                    _buildInvoiceSummaryRow('Biaya Administrasi & Gateway:', _formatRupiah(_adminFee)),
                    _buildInvoiceSummaryRow('Pajak PPN (0%):', 'Rp 0'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(color: Color(0xFFCBD5E1)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL PEMBAYARAN:',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF0F172A)),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatRupiah(_totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Strip Validasi Resmi (QR Code + Segel LUNAS)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    QrImageView(
                      data: 'https://skilloka.my.id/verify-invoice/$_bookingCode',
                      version: QrVersions.auto,
                      size: 60,
                      gapless: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 18),
                              const SizedBox(width: 6),
                              const Text(
                                'STATUS: LUNAS',
                                style: TextStyle(
                                  color: Color(0xFF047857),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'KODE REF: #INV-${_bookingCode.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          const Text(
                            'Diverifikasi secara digital oleh Skilloka Indonesia.',
                            style: TextStyle(fontSize: 9, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tanda Tangan Resmi & Catatan
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text(
                      'Catatan:\nDokumen ini merupakan bukti pembayaran resmi yang diterbitkan secara otomatis oleh sistem Skilloka Indonesia dan sah tanpa tanda tangan basah.',
                      style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B), height: 1.35),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Pengelola Skilloka Indonesia,',
                        style: TextStyle(fontSize: 10, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: 120,
                        height: 1,
                        color: const Color(0xFF334155),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Finance & Operations Dept.',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper row struk thermal
  Widget _buildThermalRow(String label, String value, {bool isBold = false, double fontSize = 11.5}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Helper baris summary invoice A4
  Widget _buildInvoiceSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // Garis strip-putus kasir
  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 3.0;
        final count = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.black38)),
            );
          }),
        );
      },
    );
  }

  // Gerigi robekan kertas thermal
  Widget _buildThermalPaperTearEdge({required bool top}) {
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const triangleWidth = 10.0;
          final count = (width / triangleWidth).floor();

          return Row(
            children: List.generate(count, (index) {
              return CustomPaint(
                size: const Size(triangleWidth, 8),
                painter: _ZigzagPainter(top: top),
              );
            }),
          );
        },
      ),
    );
  }
}

class _ZigzagPainter extends CustomPainter {
  final bool top;
  _ZigzagPainter({required this.top});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    final path = Path();
    if (top) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.close();
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
