import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/api_service.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _isPhoneValid = false;
  bool _isLoading = false;
  bool _showOTPInput = false;
  String? _devOtpHint;

  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(4, (_) => FocusNode());
  final ApiService _apiService = ApiService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  void _validatePhone() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    setState(() => _isPhoneValid = digits.length >= 9 && digits.length <= 15);
  }

  String _normalizePhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) {
      digits = '0${digits.substring(2)}';
    } else if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    return digits;
  }

  Future<void> _sendOTP(String channel) async {
    if (!_isPhoneValid || _isLoading) return;
    setState(() {
      _isLoading = true;
      _devOtpHint = null;
    });

    try {
      final phone = _normalizePhone(_phoneController.text);
      final response = await _apiService.requestOtp(phone, channel: channel);

      if (!mounted) return;
      setState(() => _isLoading = false);

      final bool success = response['success'] == true;

      if (success) {
        final outer = response['data'];
        String? devOtp;
        if (outer is Map) {
          final inner = outer['data'];
          if (inner is Map && inner['dev_otp'] != null) {
            devOtp = inner['dev_otp'].toString();
          } else if (outer['dev_otp'] != null) {
            devOtp = outer['dev_otp'].toString();
          }
        }

        setState(() {
          _showOTPInput = true;
          _devOtpHint = devOtp;
        });

        _animController.reset();
        _animController.forward();

        final channelName = channel == 'whatsapp' ? 'WhatsApp' : 'Telegram';
        _showSuccess('Kode OTP berhasil dikirim via $channelName.');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _otpFocusNodes[0].requestFocus();
        });
      } else {
        final msg = (response['message'] ?? '').toString().toLowerCase();
        if (msg.contains('belum terdaftar') ||
            msg.contains('404') ||
            msg.contains('not found')) {
          if (mounted) context.push(AppRouter.register);
        } else {
          _showError(response['message'] ?? 'Gagal mengirim OTP. Coba lagi.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Tidak dapat terhubung ke server.');
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 4 || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final phone = _normalizePhone(_phoneController.text);
      final response = await _apiService.verifyOtp(phone, otp);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['success'] == true) {
        _checkAndNavigate();
      } else {
        _showError(response['message'] ?? 'Kode OTP salah atau kedaluwarsa.');
        for (final c in _otpControllers) { c.clear(); }
        if (mounted) { _otpFocusNodes[0].requestFocus(); }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Tidak dapat terhubung ke server.');
      }
    }
  }

  Future<void> _checkAndNavigate() async {
    if (!mounted) return;
    try {
      final profile = await _apiService.getProfile();
      if (!mounted) return;
      final data = profile['data'] is Map
          ? (profile['data']['data'] ?? profile['data'])
          : null;
      final hasEducation = data != null &&
          (data['education_profile'] != null ||
              data['education_level'] != null ||
              data['major'] != null);
      if (!mounted) return;
      context.go(
          hasEducation ? AppRouter.home : AppRouter.educationOnboarding);
    } catch (_) {
      if (mounted) context.go(AppRouter.home);
    }
  }

  void _handleOTPInput(String value, int index) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (int i = 0; i < digits.length && i < 4; i++) {
        _otpControllers[i].text = digits[i];
      }
      setState(() {});
      if (digits.length >= 4) {
        _verifyOTP();
      } else {
        _otpFocusNodes[digits.length].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty && index < 3) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() {});
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 4) _verifyOTP();
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _loginWithBiometric() async {
    final auth = LocalAuthentication();
    try {
      final supported =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!supported) {
        _showError('Biometrik tidak didukung di perangkat ini.');
        return;
      }
      final ok = await auth.authenticate(
        localizedReason: 'Autentikasi untuk masuk ke Skilloka',
        options: const AuthenticationOptions(
            biometricOnly: true, stickyAuth: true),
      );
      if (ok && mounted) context.go(AppRouter.home);
    } catch (_) {
      _showError('Autentikasi biometrik gagal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  _buildBrand(),
                  const SizedBox(height: 40),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _showOTPInput
                        ? _buildOTPHeader(key: const ValueKey('h_otp'))
                        : _buildPhoneHeader(key: const ValueKey('h_phone')),
                  ),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _showOTPInput
                        ? _buildOTPSection(
                            key: const ValueKey('s_otp'), isDark: isDark)
                        : _buildPhoneSection(
                            key: const ValueKey('s_phone'), isDark: isDark),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Dengan melanjutkan, Anda menyetujui\nSyarat & Ketentuan dan Kebijakan Privasi',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Skill',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const TextSpan(
                text: 'oka',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF59E0B),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneHeader({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Masuk ke Skilloka', style: AppTypography.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Masukkan nomor HP untuk mendapatkan kode OTP',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textSecondaryFor(context)),
        ),
      ],
    );
  }

  Widget _buildOTPHeader({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Masukkan Kode OTP', style: AppTypography.headlineMedium),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context)),
            children: [
              const TextSpan(text: 'Kode 4 digit dikirim ke '),
              TextSpan(
                text: _normalizePhone(_phoneController.text),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection({Key? key, required bool isDark}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhoneInput(controller: _phoneController, isDark: isDark),
        const SizedBox(height: 20),
        _PrimaryBtn(
          label: 'Kirim OTP via WhatsApp',
          icon: Icons.chat_bubble_rounded,
          iconColor: const Color(0xFF25D366),
          isLoading: _isLoading,
          enabled: _isPhoneValid,
          onTap: () => _sendOTP('whatsapp'),
        ),
        const SizedBox(height: 12),
        _SecondaryBtn(
          label: 'Kirim OTP via Telegram',
          icon: Icons.telegram_rounded,
          iconColor: const Color(0xFF0088CC),
          enabled: _isPhoneValid && !_isLoading,
          onTap: () => _sendOTP('telegram'),
        ),
        const SizedBox(height: 28),
        Row(children: [
          Expanded(
              child: Divider(
                  color:
                      AppColors.textTertiaryFor(context).withAlpha(60))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('atau',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiaryFor(context))),
          ),
          Expanded(
              child: Divider(
                  color:
                      AppColors.textTertiaryFor(context).withAlpha(60))),
        ]),
        const SizedBox(height: 20),
        _SecondaryBtn(
          label: 'Masuk dengan Biometrik',
          icon: Icons.fingerprint_rounded,
          iconColor: AppColors.primary,
          enabled: !_isLoading,
          onTap: _loginWithBiometric,
        ),
      ],
    );
  }

  Widget _buildOTPSection({Key? key, required bool isDark}) {
    final otpComplete =
        _otpControllers.every((c) => c.text.isNotEmpty);
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_devOtpHint != null) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withAlpha(50)
                  : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primary.withAlpha(100)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bug_report_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimaryFor(context)),
                      children: [
                        const TextSpan(text: 'Dev OTP: '),
                        TextSpan(
                          text: _devOtpHint,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.primary,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_devOtpHint == null ||
                        _devOtpHint!.length != 4) { return; }
                    for (int i = 0; i < 4; i++) {
                      _otpControllers[i].text = _devOtpHint![i];
                    }
                    setState(() {});
                    _verifyOTP();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Isi Otomatis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
              4,
              (i) => _OTPBox(
                    controller: _otpControllers[i],
                    focusNode: _otpFocusNodes[i],
                    isDark: isDark,
                    onChanged: (v) => _handleOTPInput(v, i),
                  )),
        ),
        const SizedBox(height: 28),
        _PrimaryBtn(
          label: 'Verifikasi & Masuk',
          icon: Icons.verified_user_rounded,
          iconColor: Colors.white,
          isLoading: _isLoading,
          enabled: otpComplete,
          onTap: _verifyOTP,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => setState(() {
                _showOTPInput = false;
                _devOtpHint = null;
                for (final c in _otpControllers) { c.clear(); }
              }),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Ganti nomor'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryFor(context)),
            ),
            _ResendBtn(onResend: () => _sendOTP('whatsapp')),
          ],
        ),
      ],
    );
  }
}

// â”€â”€â”€ OTP Box â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _OTPBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _OTPBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 4,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        style: AppTypography.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryFor(context),
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? AppColors.outlineDark : AppColors.outline,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2.5),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Phone Input ─────────────────────────────────────────────────────────────
class _PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  const _PhoneInput({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))
      ],
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.textPrimaryFor(context),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      decoration: InputDecoration(
        labelText: 'Nomor Telepon',
        hintText: '08xxxxxxxxxx',
        prefixIcon: Container(
          width: 78,
          margin: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.outlineDark : AppColors.outline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  width: 20,
                  height: 14,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Expanded(child: Container(color: const Color(0xFFED1C24))),
                      Expanded(child: Container(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '+62',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.outlineDark : AppColors.outline,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

// â”€â”€â”€ Primary Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onTap;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.isLoading = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withAlpha(80),
          disabledForegroundColor: Colors.white60,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 10),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

// â”€â”€â”€ Secondary Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SecondaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool enabled;
  final VoidCallback? onTap;

  const _SecondaryBtn({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryFor(context),
          side: BorderSide(
              color: isDark ? AppColors.outlineDark : AppColors.outline,
              width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: enabled
                    ? iconColor
                    : AppColors.textDisabledFor(context)),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? AppColors.textPrimaryFor(context)
                        : AppColors.textDisabledFor(context))),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Resend OTP Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ResendBtn extends StatefulWidget {
  final VoidCallback onResend;
  const _ResendBtn({required this.onResend});

  @override
  State<_ResendBtn> createState() => _ResendBtnState();
}

class _ResendBtnState extends State<_ResendBtn> {
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _countdown <= 0;
    return TextButton(
      onPressed: canResend
          ? () {
              setState(() => _countdown = 60);
              _startCountdown();
              widget.onResend();
            }
          : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(
        canResend ? 'Kirim ulang' : 'Kirim ulang ($_countdown)',
        style:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );

  }
}

