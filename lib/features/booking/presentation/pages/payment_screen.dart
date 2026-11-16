import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/luhn_validator.dart';

class PaymentScreen extends StatefulWidget {
  final String courseId;
  final String? bookingId;
  final String? amount;

  const PaymentScreen({
    super.key,
    required this.courseId,
    this.bookingId,
    this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isProcessingCard = false;
  String? _qrCodeUrl;
  String _errorMessage = '';

  // Controllers untuk Pembayaran Kartu dengan Algoritma Luhn
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isCardLuhnValid = false;
  String _cardBrand = 'Unknown';
  bool _hasTouchedCard = false;

  String? get _safeBookingId {
    final id = widget.bookingId;
    if (id == null || id.isEmpty) return null;
    return id.replaceAll(':', '');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cardNumberController.addListener(_onCardNumberChanged);
    _fetchQrCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  /// Evaluasi Algoritma Luhn setiap kali digit nomor kartu berubah
  void _onCardNumberChanged() {
    final raw = _cardNumberController.text;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final brand = LuhnValidator.getCardBrand(digits);
    final isValid = LuhnValidator.isValid(digits);

    setState(() {
      _cardBrand = brand;
      _isCardLuhnValid = isValid;
      _hasTouchedCard = digits.length >= 4;
    });
  }

  Future<void> _fetchQrCode() async {
    if (_safeBookingId == null) {
      setState(() {
        _errorMessage = 'ID Booking tidak ditemukan.';
        _isLoading = false;
      });
      return;
    }

    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/bookings/$_safeBookingId');
      final data = response.data['data'];

      setState(() {
        _qrCodeUrl = data['qr_code_url'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat QR Code pembayaran.';
        _isLoading = false;
      });
    }
  }

  void _processCardPayment() async {
    final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');

    // 1. Validasi Algoritma Luhn (Mod 10 Checksum)
    if (!LuhnValidator.isValid(digits)) {
      _showSnackbar('Nomor kartu tidak valid menurut Algoritma Luhn (Checksum Gagal).', isError: true);
      return;
    }

    // 2. Validasi Tanggal Kedaluwarsa
    if (!LuhnValidator.isExpiryValid(_expiryController.text)) {
      _showSnackbar('Format atau masa berlaku kartu (MM/YY) tidak valid.', isError: true);
      return;
    }

    // 3. Validasi CVV
    if (!LuhnValidator.isCvvValid(_cvvController.text, _cardBrand)) {
      _showSnackbar('Kode keamanan CVV harus 3-4 digit angka.', isError: true);
      return;
    }

    if (_cardHolderController.text.trim().isEmpty) {
      _showSnackbar('Nama pemegang kartu harus diisi.', isError: true);
      return;
    }

    setState(() => _isProcessingCard = true);
    HapticFeedback.mediumImpact();

    // Simulasi otorisasi kartu dengan gateway (Midtrans / Bank Partner)
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isProcessingCard = false);

    _showSnackbar('Pembayaran kartu berhasil diverifikasi oleh Algoritma Luhn!', isError: false);

    // Langsung arahkan ke halaman Sukses & Cetak Struk
    if (_safeBookingId != null) {
      context.push(AppRouter.bookingSuccessPath(_safeBookingId!));
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Pelatihan'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'QRIS / Transfer'),
            Tab(icon: Icon(Icons.credit_card_rounded), text: 'Kartu (Luhn Check)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQrisTab(),
                    _buildCreditCardTab(),
                  ],
                ),
    );
  }

  /// Tab 1: QRIS / Transfer Manual
  Widget _buildQrisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTotalCard(),
          const SizedBox(height: 28),
          Text(
            'Silakan Scan QR Code berikut\nuntuk melakukan pembayaran',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 20),
          if (_qrCodeUrl != null && _qrCodeUrl!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Image.network(
                _qrCodeUrl!,
                width: 230,
                height: 230,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100, color: Colors.grey),
              ),
            )
          else
            const Text(
              'QR Code belum tersedia.',
              style: TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 24),
          Text(
            'Setelah melakukan pembayaran, Admin LPK akan memverifikasi dan memperbarui status Anda menjadi LUNAS.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_safeBookingId != null) {
                  context.push(AppRouter.bookingSuccessPath(_safeBookingId!));
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusMD),
              ),
              child: const Text(
                'Saya Sudah Bayar (Konfirmasi)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Pembayaran Kartu dengan Algoritma Luhn
  Widget _buildCreditCardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalCard(),
          const SizedBox(height: 24),

          // 💳 Visual Interactive Credit Card Preview
          _buildVisualCardPreview(),
          const SizedBox(height: 20),

          // Badge Status Algoritma Luhn
          if (_hasTouchedCard)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isCardLuhnValid
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCardLuhnValid
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCardLuhnValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _isCardLuhnValid ? const Color(0xFF10B981) : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isCardLuhnValid
                          ? 'Algoritma Luhn: Valid ($_cardBrand Checksum ✓)'
                          : 'Algoritma Luhn: Nomor Kartu Tidak Valid (Mod 10 Fail)',
                      style: AppTypography.labelSmall.copyWith(
                        color: _isCardLuhnValid ? const Color(0xFF047857) : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Input Nomor Kartu
          Text('Nomor Kartu Debit/Kredit', style: AppTypography.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            maxLength: 19,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberInputFormatter(),
            ],
            decoration: InputDecoration(
              hintText: '4000 1234 5678 9010',
              counterText: '',
              prefixIcon: const Icon(Icons.credit_card_rounded),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _cardBrand,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Nama Pemegang Kartu
          Text('Nama Pemegang Kartu', style: AppTypography.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: _cardHolderController,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'CONTOH: AHMAD KHOIRUL',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Baris Expired & CVV
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kedaluwarsa (MM/YY)', style: AppTypography.labelMedium),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _CardExpiryInputFormatter(),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '12/28',
                        counterText: '',
                        prefixIcon: const Icon(Icons.calendar_month_rounded),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CVV / CVC', style: AppTypography.labelMedium),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '123',
                        counterText: '',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Tombol Proses Pembayaran dengan Kartu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingCard ? null : _processCardPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusMD),
              ),
              child: _isProcessingCard
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Verifikasi & Bayar (${_isCardLuhnValid ? "Luhn OK" : "Periksa Kartu"})',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Total Tagihan
  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppShapes.borderRadiusMD,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Pembayaran', style: AppTypography.labelMedium),
              const SizedBox(height: 4),
              Text(
                'Rp ${widget.amount ?? '0'}',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
          ),
        ],
      ),
    );
  }

  /// Visual Credit Card Widget
  Widget _buildVisualCardPreview() {
    final rawNumber = _cardNumberController.text.trim();
    final displayNumber = rawNumber.isEmpty ? '•••• •••• •••• ••••' : rawNumber;
    final holder = _cardHolderController.text.trim().isEmpty
        ? 'NAMA PEMEGANG'
        : _cardHolderController.text.toUpperCase();
    final expiry = _expiryController.text.trim().isEmpty ? 'MM/YY' : _expiryController.text;

    return Container(
      width: double.infinity,
      height: 195,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isCardLuhnValid
              ? const [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0284C7)]
              : const [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.nfc_rounded, color: Colors.white70, size: 24),
                  SizedBox(width: 8),
                  Icon(Icons.sim_card_rounded, color: Color(0xFFFBBF24), size: 26),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _cardBrand.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Text(
            displayNumber,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CARD HOLDER', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(
                    holder,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPIRES', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(
                    expiry,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formatter otomatis spasi per 4 digit kartu
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter otomatis MM/YY
class _CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
