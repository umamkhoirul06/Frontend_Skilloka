import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/widgets/atoms/input_field.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/di/injection_container.dart';

class BookingScreen extends StatefulWidget {
  final String courseId;
  const BookingScreen({super.key, required this.courseId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedBatchIndex = 0;
  bool _agreedToTerms = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _courseData;
  List<dynamic> _batches = [];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // 🔥 Getter untuk membersihkan format ID dari router bugs
  String get _safeCourseId {
    return widget.courseId.replaceAll(':courseId', '').replaceAll(':', '');
  }

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourseData() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/courses/$_safeCourseId');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _courseData = data;
          if (data['schedules'] != null &&
              (data['schedules'] as List).isNotEmpty) {
            _batches = data['schedules'];
          } else {
            _batches = [
              {
                'id': null,
                'date': 'Sesuai Kesepakatan',
                'time': 'Menyesuaikan Jam LPK',
                'slots': 1,
              },
            ];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Fetching Course: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitBooking() async {
    // 1. Validasi Syarat & Ketentuan
    if (!_agreedToTerms) {
      _showError('Anda harus menyetujui Syarat & Ketentuan.');
      return;
    }

    if (_isSubmitting) return;

    // 2. 🔥 VALIDASI WAJIB ISI (Form Data Pribadi)
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      _showError('Semua data pribadi (Nama, Telepon, Email) wajib diisi!');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = sl<ApiClient>();

      final selectedBatch = _batches[_selectedBatchIndex];
      final scheduleId = selectedBatch['id'];

      // 3. Siapkan Payload untuk API
      final payload = {
        'course_id': _safeCourseId,
        if (scheduleId != null) 'schedule_id': scheduleId.toString(),
        'name': name,
        'phone': phone,
        'email': email,
        'status': 'pending', // Status alur approval baru
      };

      final response = await apiClient.post('/bookings', data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Ambil booking_id dari respons Laravel
        final responseData = response.data['data'];
        final bookingId = responseData['booking_id']?.toString() ??
            responseData['id'].toString();

        if (mounted) {
          // 🔥 FIX: Pakai string path bersih langsung tanpa membawa teks ':bookingId'
          context.push('/pending-booking/$bookingId');
        }
      } else {
        _showError('Gagal membuat booking. Coba lagi.');
      }
    } catch (e) {
      debugPrint("Error Submit Booking: $e");
      // Tangani jika token bermasalah (401 Unauthorized)
      if (e.toString().contains('401')) {
        _showError('Sesi habis. Silakan login kembali.');
        ApiService().removeToken();
        context.go(AppRouter.login);
      } else {
        // 🔥 UBAH BAGIAN INI: Tampilkan pesan error aslinya!
        // Jika pakai Dio, kita coba ambil pesan dari response Laravel
        String errorMessage = e.toString();
        if (e is Exception && e.toString().contains('DioException')) {
          errorMessage = 'Gagal memproses data di server. Cek log/konsol.';
        }
        _showError('Error Server: $errorMessage');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_courseData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Gagal memuat data kursus.')),
      );
    }

    final course = _courseData!;
    final String title = course['title'] ?? 'Kursus';
    final String lpkName = course['lpk']?['name'] ?? 'LPK Tidak Diketahui';
    final double basePrice =
        double.tryParse(course['price']?.toString() ?? '0') ?? 0;
    const double adminFee = 5000;
    final double totalPrice = basePrice + adminFee;

    String rawImg = '';
    if (course['images'] != null && (course['images'] as List).isNotEmpty) {
      rawImg = course['images'][0].toString();
    }
    final imageUrl = ApiService.toFullUrl(rawImg);

    return Scaffold(
      appBar: AppBar(title: const Text('Pendaftaran Kursus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Kursus
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppShapes.borderRadiusMD,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppShapes.borderRadiusSM,
                    child: Image.network(
                      imageUrl.isNotEmpty
                          ? imageUrl
                          : 'https://via.placeholder.com/80',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTypography.titleSmall, maxLines: 2),
                        const SizedBox(height: 4),
                        Text(lpkName,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          _formatRupiah(basePrice),
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pilih Jadwal
            Text('Pilih Jadwal', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            ...List.generate(_batches.length, (index) {
              final batch = _batches[index];
              final isSelected = _selectedBatchIndex == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedBatchIndex = index),
                  borderRadius: AppShapes.borderRadiusMD,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.surfaceVariant,
                      borderRadius: AppShapes.borderRadiusMD,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(batch['date'] ?? 'Tanggal',
                                  style: AppTypography.labelLarge),
                              Text(batch['time'] ?? 'Waktu',
                                  style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Data Pribadi (Dengan label peringatan wajib isi)
            Text('Data Pribadi (Wajib Diisi)',
                style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            AppInputField(
              label: 'Nama Lengkap',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            AppInputField(
              label: 'Nomor Telepon',
              controller: _phoneController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppInputField(
              label: 'Email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            // Syarat & Ketentuan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text.rich(
                      TextSpan(
                        text: 'Saya menyetujui ',
                        style: AppTypography.bodySmall,
                        children: [
                          TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.primary),
                          ),
                          const TextSpan(text: ' dan '),
                          TextSpan(
                            text: 'Kebijakan Privasi',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Ringkasan Harga
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppShapes.borderRadiusMD,
              ),
              child: Column(
                children: [
                  _buildPriceRow('Biaya Kursus', basePrice),
                  const SizedBox(height: 8),
                  _buildPriceRow('Biaya Admin', adminFee),
                  const Divider(height: 24),
                  _buildPriceRow('Total', totalPrice, isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tombol Submit
            AnimatedPrimaryButton(
              text: _isSubmitting ? 'Memproses...' : 'Daftar Sekarang',
              // Tombol bisa ditekan kapan saja untuk memicu validasi
              isEnabled: !_isSubmitting,
              onPressed: _submitBooking,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.labelLarge
              : AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
        ),
        Text(
          _formatRupiah(price),
          style: isTotal
              ? AppTypography.titleMedium.copyWith(color: AppColors.primary)
              : AppTypography.labelMedium,
        ),
      ],
    );
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
