import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/widgets/atoms/input_field.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../course/data/models/course_model.dart';

/// Halaman Pendaftaran Kursus & LPK — PRD 8.7 & Prinsip 2.2
/// Stepper: 1. Jadwal → 2. Data Pribadi (Auto-fill) → 3. Layanan → 4. Pembayaran (Midtrans)
class BookingScreen extends StatefulWidget {
  final String courseId;
  const BookingScreen({super.key, required this.courseId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Stepper state (0: Jadwal, 1: Data Diri, 2: Layanan, 3: Pembayaran)
  int _currentStep = 0;
  static const int _totalSteps = 4;

  int _selectedBatchIndex = 0;
  bool _withSubscription = true;
  static const double _subscriptionFee = 50000;
  static const double _adminFee = 5000;
  bool _agreedToTerms = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _profileAutoFilled = false;

  Map<String, dynamic>? _courseData;
  List<dynamic> _batches = [];

  // Controllers Data Pribadi
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  final ApiService _apiService = ApiService();

  // Getter untuk membersihkan format ID dari router bugs
  String get _safeCourseId {
    return widget.courseId.replaceAll(':courseId', '').replaceAll(':', '');
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Memuat data kursus dan auto-fill profil user secara simultan
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Kursus
      final apiClient = sl<ApiClient>();
      final courseResponse = await apiClient.get('/courses/$_safeCourseId');

      if (courseResponse.statusCode == 200) {
        final data = courseResponse.data['data'];
        _courseData = data;
        if (data['schedules'] != null &&
            (data['schedules'] as List).isNotEmpty) {
          _batches = data['schedules'];
        } else {
          _batches = [
            {
              'id': null,
              'date': 'Sesuai Kesepakatan LPK',
              'time': 'Menyesuaikan Jam Operasional',
              'slots': 1,
            },
          ];
        }
      }

      // 2. Auto-fill Data Pribadi dari Profil Pengguna yang Sedang Login
      final profileResult = await _apiService.getProfile();
      if (profileResult['success'] == true) {
        final raw = profileResult['data'];
        final profile = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
        if (profile is Map) {
          final name = (profile['name'] ?? '').toString();
          final rawPhone = (profile['phone'] ?? '').toString();
          final email = (profile['email'] ?? '').toString();
          final address = (profile['address'] ?? profile['domicile'] ?? '').toString();

          // Normalisasi nomor telepon
          final phone = rawPhone.startsWith('+62')
              ? rawPhone
              : rawPhone.startsWith('62')
                  ? '+$rawPhone'
                  : rawPhone;

          if (name.isNotEmpty && _nameController.text.isEmpty) {
            _nameController.text = name;
          }
          if (phone.isNotEmpty && _phoneController.text.isEmpty) {
            _phoneController.text = phone;
          }
          if (email.isNotEmpty && _emailController.text.isEmpty) {
            _emailController.text = email;
          }
          if (address.isNotEmpty && _addressController.text.isEmpty) {
            _addressController.text = address;
          }

          if (name.isNotEmpty || phone.isNotEmpty || email.isNotEmpty) {
            _profileAutoFilled = true;
          }
        }
      }
    } catch (e) {
      debugPrint("Error Load Initial Data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── NAVIGASI STEPPER ──────────────────────────────────────────────────────
  void _nextStep() {
    if (_currentStep == 0) {
      // Validasi Jadwal
      if (_batches.isEmpty) {
        _showError('Jadwal belum tersedia untuk kursus ini.');
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Validasi Data Pribadi
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();

      if (name.isEmpty) {
        _showError('Nama lengkap wajib diisi!');
        return;
      }
      if (phone.isEmpty) {
        _showError('Nomor telepon/WhatsApp wajib diisi!');
        return;
      }
      if (email.isEmpty || !email.contains('@')) {
        _showError('Alamat email valid wajib diisi!');
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Step Layanan selesai, lanjut ke Review & Pembayaran
      setState(() => _currentStep = 3);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  // ─── SUBMIT & MIDTRANS PAYMENT ─────────────────────────────────────────────
  Future<void> _submitBookingAndPay() async {
    // 1. Validasi Syarat & Ketentuan
    if (!_agreedToTerms) {
      _showError('Anda harus menyetujui Syarat & Ketentuan dan Kebijakan Privasi.');
      return;
    }

    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      _showError('Harap lengkapi semua data pribadi di langkah sebelumnya.');
      setState(() => _currentStep = 1);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = sl<ApiClient>();

      final selectedBatch = _batches[_selectedBatchIndex];
      final scheduleId = selectedBatch['id'];

      final rawPrice = _courseData?['price'];
      final basePrice = rawPrice != null ? (double.tryParse(rawPrice.toString()) ?? 0.0) : 0.0;
      final totalPrice = basePrice + _adminFee + (_withSubscription ? _subscriptionFee : 0.0);

      // 2. Siapkan Payload lengkap untuk API backend & Admin LPK (PRD Section 9 & 26)
      final payload = {
        'course_id': _safeCourseId,
        if (scheduleId != null) 'schedule_id': scheduleId.toString(),
        'name': name,
        'phone': phone,
        'email': email,
        if (address.isNotEmpty) 'address': address,
        'service_type': _withSubscription ? 'subscription' : 'regular',
        'include_subscription': _withSubscription,
        if (_withSubscription) 'subscription_fee': _subscriptionFee,
        'total_price': totalPrice,
        'amount': totalPrice,
        'payment_method': 'midtrans',
        'status': 'pending',
      };

      final response = await apiClient.post('/bookings', data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data['data'] ?? response.data;
        final bookingId = responseData['booking_id']?.toString() ??
            responseData['id']?.toString() ??
            '';

        if (bookingId.isEmpty) {
          throw Exception('Gagal mendapatkan nomor referensi booking dari server.');
        }

        // 3. Inisiasi Pembayaran Midtrans Snap
        String? snapUrl;
        try {
          final payResult = await _apiService.createBookingPayment(
            bookingId: bookingId,
            paymentMethod: 'midtrans',
          );

          if (payResult['success'] == true) {
            final payData = payResult['data'] is Map ? payResult['data'] : {};
            final snapToken = payData['snap_token']?.toString() ??
                payData['data']?['snap_token']?.toString();
            final redirectUrl = payData['redirect_url']?.toString() ??
                payData['data']?['redirect_url']?.toString();

            if (redirectUrl != null && redirectUrl.isNotEmpty) {
              snapUrl = redirectUrl;
            } else if (snapToken != null && snapToken.isNotEmpty) {
              snapUrl = AppConfig.getMidtransSnapUrl(snapToken);
            }
          }
        } catch (payErr) {
          debugPrint("Gagal inisiasi Midtrans createBookingPayment: $payErr");
        }

        // Fallback langsung ke /payment/create-transaction jika belum dapat URL
        if (snapUrl == null || snapUrl.isEmpty) {
          try {
            final payRes = await apiClient.post('/payment/create-transaction', data: {
              'order_id': bookingId,
            });
            if (payRes.statusCode == 200) {
              final pData = payRes.data is Map ? payRes.data : {};
              final sToken = pData['snap_token']?.toString();
              final rUrl = pData['redirect_url']?.toString();
              if (rUrl != null && rUrl.isNotEmpty) {
                snapUrl = rUrl;
              } else if (sToken != null && sToken.isNotEmpty) {
                snapUrl = AppConfig.getMidtransSnapUrl(sToken);
              }
            }
          } catch (e) {
            debugPrint("Fallback create-transaction error: $e");
          }
        }

        // 4. Buka Midtrans Snap Checkout jika URL tersedia
        if (snapUrl != null && snapUrl.isNotEmpty) {
          try {
            final uri = Uri.parse(snapUrl);
            await launchUrl(
              uri,
              mode: LaunchMode.inAppBrowserView, // In-app browser / Chrome Custom Tabs
            );
          } catch (_) {
            // Fallback external browser
            await launchUrl(
              Uri.parse(snapUrl),
              mode: LaunchMode.externalApplication,
            );
          }
        }

        if (mounted) {
          // Bawa user ke halaman PendingBookingScreen untuk memantau status pembayaran
          context.push(AppRouter.pendingBookingPath(bookingId));
        }
      } else {
        _showError('Gagal memproses pendaftaran. Silakan periksa kembali data Anda.');
      }
    } catch (e) {
      debugPrint("Error Submit Booking: $e");
      String errorMessage = 'Terjadi kesalahan sistem. Coba lagi beberapa saat.';
      if (e.toString().contains('401')) {
        errorMessage = 'Sesi habis. Silakan login kembali.';
        _apiService.removeToken();
        if (mounted) context.go(AppRouter.login);
      } else {
        errorMessage = 'Gagal membuat pendaftaran: $e';
      }
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── BUILD SCREEN ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Pendaftaran Kursus LPK'),
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Menyiapkan formulir pendaftaran...'),
            ],
          ),
        ),
      );
    }

    if (_courseData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Pendaftaran Kursus')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Gagal memuat informasi kursus.', style: AppTypography.titleMedium),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadInitialData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final course = _courseData!;
    final String title = course['title'] ?? 'Kursus Pelatihan';
    final String lpkName = course['lpk']?['name'] ?? 'LPK Mitra';
    final double basePrice = double.tryParse(course['price']?.toString() ?? '0') ?? 0;
    final double currentSubscriptionFee = _withSubscription ? _subscriptionFee : 0;
    final double totalPrice = basePrice + _adminFee + currentSubscriptionFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pendaftaran Pelatihan LPK'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── STEPPER HEADER PROGRESS ──────────────────────────────────
            _buildStepperHeader(),

            // ─── STEPPER BODY KONTEN ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ringkasan Header Kursus (Ringkas & Konsisten)
                    _buildCourseHeaderCard(course, title, lpkName, basePrice),
                    const SizedBox(height: 16),

                    // Tampilan berdasarkan Step aktif
                    if (_currentStep == 0)
                      _buildStep1Schedule()
                    else if (_currentStep == 1)
                      _buildStep2PersonalInfo()
                    else if (_currentStep == 2)
                      _buildStep3ServicePlan()
                    else if (_currentStep == 3)
                      _buildStep4PaymentSummary(basePrice, totalPrice),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ─── BOTTOM NAVIGATION BAR (STICKY CTA) ───────────────────────
            _buildBottomActionBar(totalPrice),
          ],
        ),
      ),
    );
  }

  // ─── STEPPER HEADER WIDGET ─────────────────────────────────────────────────
  Widget _buildStepperHeader() {
    final steps = [
      {'title': 'Jadwal', 'icon': Icons.calendar_month_outlined},
      {'title': 'Data Diri', 'icon': Icons.person_outline},
      {'title': 'Layanan', 'icon': Icons.workspace_premium_outlined},
      {'title': 'Bayar', 'icon': Icons.payment_outlined},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.6))),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          final color = isActive
              ? AppColors.primary
              : isCompleted
                  ? AppColors.success
                  : AppColors.textTertiary;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Boleh lompat ke step sebelumnya yang sudah dilewati
                      if (index < _currentStep) {
                        setState(() => _currentStep = index);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? AppColors.primary
                                : isCompleted
                                    ? AppColors.successContainer
                                    : AppColors.surfaceVariant,
                            border: Border.all(
                              color: color.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 16, color: AppColors.success)
                                : Icon(
                                    steps[index]['icon'] as IconData,
                                    size: 16,
                                    color: isActive ? Colors.white : AppColors.textSecondary,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          steps[index]['title'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 16,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isCompleted ? AppColors.success : AppColors.outline,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── CARD RINGKASAN KURSUS ─────────────────────────────────────────────────
  Widget _buildCourseHeaderCard(
    Map<String, dynamic> course,
    String title,
    String lpkName,
    double basePrice,
  ) {
    String rawImg = '';
    if (course['images'] != null) {
      final imgs = course['images'];
      if (imgs is List && imgs.isNotEmpty) {
        rawImg = imgs[0].toString();
      } else if (imgs is String && imgs.isNotEmpty) {
        rawImg = imgs;
      }
    }
    if (rawImg.isEmpty) {
      rawImg = (course['image_url'] ?? course['image'] ?? course['thumbnail'] ?? '').toString();
    }
    final imageUrl = ApiService.toFullUrl(rawImg);
    final String categoryName = course['category']?['name'] ?? 'Vokasi';
    final fallbackUrl = CourseModel.getFallbackImage(title: title, category: categoryName);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShapes.borderRadiusMD,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppShapes.borderRadiusSM,
            child: CachedNetworkImage(
              imageUrl: imageUrl.isNotEmpty ? imageUrl : fallbackUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppColors.primaryContainer,
                child: const Icon(Icons.school, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    categoryName,
                    style: AppTypography.badge.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  lpkName,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRupiah(basePrice),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 1: PILIH JADWAL ──────────────────────────────────────────────────
  Widget _buildStep1Schedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Langkah 1: Pilih Jadwal Pelatihan', style: AppTypography.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih waktu pelaksanaan pelatihan yang diselenggarakan oleh ${ _courseData?['lpk']?['name'] ?? 'LPK' }.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        ...List.generate(_batches.length, (index) {
          final batch = _batches[index];
          final isSelected = _selectedBatchIndex == index;
          final date = batch['date'] ?? 'Jadwal Fleksibel';
          final time = batch['time'] ?? 'Waktu menyesuaikan LPK';
          final slots = batch['slots'] ?? batch['quota'];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _selectedBatchIndex = index),
              borderRadius: AppShapes.borderRadiusMD,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.5) : AppColors.surface,
                  borderRadius: AppShapes.borderRadiusMD,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date,
                            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(time, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (slots != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sisa $slots slot',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── STEP 2: DATA PRIBADI PESERTA (AUTO-FILL) ──────────────────────────────
  Widget _buildStep2PersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Langkah 2: Data Pribadi Peserta', style: AppTypography.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Data ini akan dicatat pada absensi kelas LPK dan dicetak pada sertifikat resmi.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),

        // Banner Auto-Fill Profil
        if (_profileAutoFilled)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.successContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data pribadi otomatis terisi dari akun profil Anda. Anda dapat mengubahnya jika diperlukan.',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF166534),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        AppInputField(
          label: 'Nama Lengkap Peserta (Wajib)',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          hint: 'Contoh: Ahmad Fauzi',
        ),
        const SizedBox(height: 12),

        AppInputField(
          label: 'Nomor WhatsApp / Telepon Aktif (Wajib)',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          hint: 'Contoh: 081234567890',
        ),
        const SizedBox(height: 12),

        AppInputField(
          label: 'Alamat Email (Wajib)',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          hint: 'Contoh: ahmad@gmail.com',
        ),
        const SizedBox(height: 12),

        AppInputField(
          label: 'Alamat / Domisili Asal (Opsional)',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
          hint: 'Contoh: Kec. Jatibarang, Kab. Indramayu',
        ),
      ],
    );
  }

  // ─── STEP 3: PILIHAN LAYANAN & LANGGANAN (PRD 2.2) ─────────────────────────
  Widget _buildStep3ServicePlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Langkah 3: Pilihan Layanan Pelatihan', style: AppTypography.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Sesuai PRD Skilloka, fitur berlangganan melekat pada pendaftaran kursus untuk membuka modul materi & absensi digital.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Opsi 1: Booking + Langganan Skilloka Premium
        InkWell(
          onTap: () => setState(() => _withSubscription = true),
          borderRadius: AppShapes.borderRadiusMD,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _withSubscription ? AppColors.primaryContainer.withValues(alpha: 0.6) : AppColors.surface,
              borderRadius: AppShapes.borderRadiusMD,
              border: Border.all(
                color: _withSubscription ? AppColors.primary : AppColors.outline,
                width: _withSubscription ? 2 : 1,
              ),
              boxShadow: _withSubscription ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _withSubscription ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _withSubscription ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Booking + Langganan', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Rekomendasi',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '✓ Pelatihan Tatap Muka LPK Terdaftar\n'
                        '✓ Akses Penuh Modul Materi Digital & Silabus\n'
                        '✓ Pencatatan Absensi & Kehadiran Online\n'
                        '✓ Akses E-Sertifikat Digital Terverifikasi',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+${_formatRupiah(_subscriptionFee)} (Akses Fitur Langganan)',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Opsi 2: Booking Reguler
        InkWell(
          onTap: () => setState(() => _withSubscription = false),
          borderRadius: AppShapes.borderRadiusMD,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: !_withSubscription ? AppColors.primaryContainer.withValues(alpha: 0.6) : AppColors.surface,
              borderRadius: AppShapes.borderRadiusMD,
              border: Border.all(
                color: !_withSubscription ? AppColors.primary : AppColors.outline,
                width: !_withSubscription ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  !_withSubscription ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: !_withSubscription ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Reguler', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Hanya kelas tatap muka langsung di LPK (tanpa modul materi digital, presensi absensi online, dan fitur langganan).',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── STEP 4: RINCIAN TAGIHAN & PEMBAYARAN MIDTRANS ─────────────────────────
  Widget _buildStep4PaymentSummary(double basePrice, double totalPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Langkah 4: Konfirmasi & Pembayaran', style: AppTypography.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Periksa kembali ringkasan pendaftaran Anda sebelum melanjutkan ke pembayaran via Midtrans.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Ringkasan Peserta
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppShapes.borderRadiusMD,
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informasi Peserta', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDetailRow('Nama', _nameController.text),
              _buildDetailRow('Telepon/WA', _phoneController.text),
              _buildDetailRow('Email', _emailController.text),
              if (_addressController.text.isNotEmpty)
                _buildDetailRow('Domisili', _addressController.text),
              _buildDetailRow(
                'Layanan',
                _withSubscription ? 'Booking + Langganan Premium' : 'Booking Reguler',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rincian Biaya
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppShapes.borderRadiusMD,
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              _buildPriceRow('Biaya Kursus', basePrice),
              const SizedBox(height: 8),
              _buildPriceRow('Biaya Admin Sistem', _adminFee),
              if (_withSubscription) ...[
                const SizedBox(height: 8),
                _buildPriceRow('Fitur Langganan (Materi & Absensi)', _subscriptionFee),
              ],
              const Divider(height: 24),
              _buildPriceRow('Total Pembayaran', totalPrice, isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Informasi Midtrans
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pembayaran diproses secara aman & terverifikasi resmi melalui Payment Gateway Midtrans (QRIS, GoPay, Transfer VA Bank).',
                  style: AppTypography.bodySmall.copyWith(color: const Color(0xFF166534)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Persetujuan Syarat & Ketentuan
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreedToTerms,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text.rich(
                  TextSpan(
                    text: 'Saya menyatakan data di atas benar serta menyetujui ',
                    style: AppTypography.bodySmall,
                    children: [
                      TextSpan(
                        text: 'Syarat & Ketentuan',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' dan '),
                      TextSpan(
                        text: 'Kebijakan Privasi',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' Skilloka.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── BOTTOM ACTION BAR (STICKY BUTTON) ────────────────────────────────────
  Widget _buildBottomActionBar(double totalPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline.withValues(alpha: 0.6))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Harga Info
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Biaya', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text(
                _formatRupiah(totalPrice),
                style: AppTypography.priceTag.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Tombol Navigasi / Bayar
          Expanded(
            child: _currentStep < _totalSteps - 1
                ? AnimatedPrimaryButton(
                    text: 'Selanjutnya',
                    onPressed: _nextStep,
                  )
                : AnimatedPrimaryButton(
                    text: _isSubmitting ? 'Menyiapkan Midtrans...' : 'Bayar via Midtrans',
                    isEnabled: !_isSubmitting,
                    onPressed: _submitBookingAndPay,
                  ),
          ),
        ],
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ),
          const Text(': ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
              ? AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)
              : AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          _formatRupiah(price),
          style: isTotal
              ? AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)
              : AppTypography.labelMedium,
        ),
      ],
    );
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
