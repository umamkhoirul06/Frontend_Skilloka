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
  bool _rememberMe = true;
  String? _devOtpHint;

  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final ApiService _apiService = ApiService();

  late AnimationController _animController;
  late Animation<double> _bgBloomAnim;
  late Animation<double> _illustrationFade;
  late Animation<Offset> _illustrationSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _footerFade;
  late Animation<Offset> _footerSlide;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _bgBloomAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _illustrationFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.05, 0.45, curve: Curves.easeOut),
      ),
    );
    _illustrationSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.05, 0.50, curve: Curves.easeOutQuart),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.20, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.20, 0.70, curve: Curves.easeOutQuart),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.90, curve: Curves.easeOutQuart),
      ),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
    _footerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
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
        for (final c in _otpControllers) {
          c.clear();
        }
        if (mounted) {
          _otpFocusNodes[0].requestFocus();
        }
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
        _otpFocusNodes[3].unfocus();
        _verifyOTP();
      } else {
        _otpFocusNodes[digits.length].requestFocus();
      }
      return;
    }

    if (digits.isNotEmpty) {
      _otpControllers[index].text = digits;
      if (index < 3) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        _verifyOTP();
      }
    } else {
      _otpControllers[index].clear();
      if (index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showHelpBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Bantuan Masuk Akun',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Skilloka menggunakan sistem login praktis dengan kode OTP (One-Time Password) yang dikirimkan langsung ke nomor WhatsApp atau Telegram Anda tanpa perlu mengingat kata sandi.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pastikan nomor HP yang Anda masukkan aktif dan terdaftar di WhatsApp untuk menerima kode verifikasi resmi.',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Ambient slow-motion background illumination
          Positioned(
            top: -40,
            left: -40,
            right: -40,
            height: 280,
            child: FadeTransition(
              opacity: _bgBloomAnim,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: isDark ? 0.20 : 0.08),
                      const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.06 : 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
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
                  ? _buildOTPView(key: const ValueKey('v_otp'), isDark: isDark)
                  : _buildLoginView(
                      key: const ValueKey('v_login'), isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  /// Screen 2: Login View matching Reference Image 4
  Widget _buildLoginView({Key? key, required bool isDark}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Top Header Illustration matching Image 4
          FadeTransition(
            opacity: _illustrationFade,
            child: SlideTransition(
              position: _illustrationSlide,
              child: Center(
                child: _LoginHeaderIllustration(isDark: isDark),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title matching Image 4: "Login"
          FadeTransition(
            opacity: _titleFade,
            child: SlideTransition(
              position: _titleSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masuk ke akun Skilloka Anda',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Form section matching Image 4
          FadeTransition(
            opacity: _formFade,
            child: SlideTransition(
              position: _formSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Phone Number Input with icon prefix
                  _PhoneInput(
                    controller: _phoneController,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 14),

                  // Remember Me & Forgot Password Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() => _rememberMe = val ?? true);
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ingat saya',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showHelpBottomSheet,
                        child: Text(
                          'Bantuan masuk?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Big Rounded Primary Button matching Image 4: "Log In"
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_isPhoneValid && !_isLoading)
                          ? () => _sendOTP('whatsapp')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withAlpha(90),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider with "Or login with" matching Image 4
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'Or login with',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Two Side-by-Side Alternate Buttons matching Image 4
                  Row(
                    children: [
                      // Alternate 1: Telegram OTP
                      Expanded(
                        child: _SocialChannelBtn(
                          label: 'Telegram',
                          icon: Icons.telegram_rounded,
                          iconColor: const Color(0xFF0088CC),
                          isDark: isDark,
                          enabled: _isPhoneValid && !_isLoading,
                          onTap: () => _sendOTP('telegram'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Alternate 2: Biometrik
                      Expanded(
                        child: _SocialChannelBtn(
                          label: 'Biometrik',
                          icon: Icons.fingerprint_rounded,
                          iconColor: AppColors.primary,
                          isDark: isDark,
                          enabled: !_isLoading,
                          onTap: _loginWithBiometric,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 36),

          // Bottom link matching Image 4: "Don't have an account? Sign up"
          FadeTransition(
            opacity: _footerFade,
            child: SlideTransition(
              position: _footerSlide,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRouter.register),
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Screen 4: Verify OTP View matching Reference Image 4
  Widget _buildOTPView({Key? key, required bool isDark}) {
    final otpComplete = _otpControllers.every((c) => c.text.isNotEmpty);

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),

          // Back arrow button matching Image 4
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: () {
              setState(() {
                _showOTPInput = false;
                _devOtpHint = null;
                for (final c in _otpControllers) {
                  c.clear();
                }
              });
            },
          ),

          // Top Illustration for OTP matching Image 4
          Center(
            child: _OtpHeaderIllustration(isDark: isDark),
          ),

          const SizedBox(height: 20),

          // Title matching Image 4: "Verify OTP"
          Text(
            'Verify OTP',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle with phone number
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              children: [
                const TextSpan(
                    text: 'Kami telah mengirimkan kode 4 digit ke nomor '),
                TextSpan(
                  text: _normalizePhone(_phoneController.text),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const TextSpan(text: '. Masukkan kode di bawah:'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Dev OTP banner if present
          if (_devOtpHint != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryDark.withAlpha(50)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(100)),
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
                      if (_devOtpHint == null || _devOtpHint!.length != 4) {
                        return;
                      }
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
            const SizedBox(height: 20),
          ],

          // 4 Square OTP Boxes matching Image 4
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (i) => _OTPBox(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                isDark: isDark,
                onChanged: (v) => _handleOTPInput(v, i),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Resend Timer Row matching Image 4
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Didn't receive any code? ",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                _ResendBtn(onResend: () => _sendOTP('whatsapp')),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Big Rounded Primary Button matching Image 4: "Verify"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (otpComplete && !_isLoading) ? _verifyOTP : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(90),
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Verify',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Vector Header Illustrations matching Image 4
// ─────────────────────────────────────────────────────────────────────────────

/// Vector Illustration for Screen 2 (Login)
class _LoginHeaderIllustration extends StatelessWidget {
  final bool isDark;
  const _LoginHeaderIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 160,
      margin: const EdgeInsets.only(top: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft ambient halo
          Container(
            width: 200,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2563EB)
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Main Desk / Tablet Screen Card
          Positioned(
            bottom: 22,
            child: Container(
              width: 130,
              height: 105,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar in screen
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Badge: Verified Check
          Positioned(
            top: 24,
            right: 32,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),

          // Floating Potted Plant on desk left
          Positioned(
            bottom: 18,
            left: 20,
            child: Container(
              width: 32,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
            ),
          ),

          // Floating Key / Lock Icon on desk right
          Positioned(
            bottom: 22,
            right: 22,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Color(0xFFD97706),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vector Illustration for Screen 4 (Verify OTP)
class _OtpHeaderIllustration extends StatelessWidget {
  final bool isDark;
  const _OtpHeaderIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 160,
      margin: const EdgeInsets.only(top: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft ambient halo
          Container(
            width: 190,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2563EB)
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Smartphone mockup with verified message
          Positioned(
            bottom: 18,
            child: Container(
              width: 100,
              height: 125,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shield icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 4 Dots code representation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < 2
                              ? const Color(0xFF2563EB)
                              : (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Message Envelope Icon
          Positioned(
            top: 26,
            right: 36,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sms_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),

          // Floating verified checkmark on left
          Positioned(
            bottom: 34,
            left: 36,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Field & Button Components matching Image 4
// ─────────────────────────────────────────────────────────────────────────────

/// Clean Phone Input matching Image 4 (prefix icon + rounded border)
class _PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const _PhoneInput({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.4,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))
        ],
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Phone number (08xx)',
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.phone_outlined,
                size: 19,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Text(
                '+62',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 20,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
              const SizedBox(width: 10),
            ],
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    );
  }
}

/// Side-by-side Alternate Channel Button (matching Google / Facebook buttons in Image 4)
class _SocialChannelBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  const _SocialChannelBtn({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// OTP Box matching Screen 4 in Image 4
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
      width: 60,
      height: 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 4,
        buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) =>
            null,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
      ),
    );
  }
}

/// Resend Button with Countdown
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
    return GestureDetector(
      onTap: canResend
          ? () {
              setState(() => _countdown = 60);
              _startCountdown();
              widget.onResend();
            }
          : null,
      child: Text(
        canResend ? 'Resend' : 'Resend (${_countdown}s)',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: canResend ? AppColors.primary : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
