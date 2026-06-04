import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/widgets/atoms/input_field.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _isPhoneValid = false;
  bool _isLoading = false;
  bool _showOTPInput = false;

  // UBAH KE 4 DIGIT (Sesuai Dummy API Backend)
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _validatePhone() {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _isPhoneValid = phone.length >= 10 && phone.length <= 13;
    });
  }

  Future<void> _sendOTP([String channel = 'whatsapp']) async {
    if (!_isPhoneValid) return;

    setState(() => _isLoading = true);

    try {
      String phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (phone.startsWith('8')) {
        phone = '0$phone';
      } else if (phone.startsWith('62')) {
        phone = '0${phone.substring(2)}';
      }
      
      final response = await _apiService.requestOtp(phone, channel: channel);
      final success = response['success'] ?? false;

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (success) {
            _showOTPInput = true;
          }
        });
        if (success) {
          _otpFocusNodes[0].requestFocus();
          // Debugging helper: Tampilkan OTP di layar selama masa development
          final resData = response['data'] ?? {};
          final innerData = resData['data'] ?? {};
          if (innerData['dev_otp'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('OTP Dev: ${innerData['dev_otp']} \n(${resData['message'] ?? 'Berhasil'})'),
                duration: const Duration(seconds: 10),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        } else {
          final msg = (response['message'] ?? '').toString().toLowerCase();
          if (msg.contains('belum terdaftar') || msg.contains('404') || msg.contains('not found')) {
            context.push(AppRouter.register);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Gagal mengirim OTP.')),
            );
          }
        }
      }
    } catch (e) {
      // INI KUNCI OPTIMASINYA: Matikan loading kalau ada error!
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 4) return;

    setState(() => _isLoading = true);

    try {
      String phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (phone.startsWith('8')) {
        phone = '0$phone';
      } else if (phone.startsWith('62')) {
        phone = '0${phone.substring(2)}';
      }
      
      final response = await _apiService.verifyOtp(phone, otp);
      final success = response['success'] ?? false;

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          context.go(AppRouter.home);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'OTP Salah')),
          );
        }
      }
    } catch (e) {
      // Matikan loading kalau server error
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _handleOTPInput(String value, int index) {
    // UBAH LOGIKA PINDAH KOTAK KE 4 DIGIT (index < 3)
    if (value.isNotEmpty && index < 3) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    // Auto verify when complete
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 4) {
      _verifyOTP();
    }
  }


  void _loginWithBiometric() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometrik tidak didukung di perangkat ini')),
          );
        }
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Silakan autentikasi untuk masuk',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate && mounted) {
        context.go(AppRouter.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error biometrik: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  _showOTPInput ? 'Verifikasi OTP' : 'Masuk ke Skilloka',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _showOTPInput
                      ? 'Masukkan kode 4 digit yang dikirim ke nomor Anda'
                      : 'Masukkan nomor telepon untuk melanjutkan',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedCrossFade(
                  duration: AppAnimations.medium,
                  crossFadeState: _showOTPInput
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: _buildPhoneInput(),
                  secondChild: _buildOTPInput(),
                ),
                const SizedBox(height: 24),
                AnimatedPrimaryButton(
                  text: _showOTPInput ? 'Verifikasi' : 'Kirim via WhatsApp',
                  isLoading: _isLoading,
                  isEnabled: _showOTPInput
                      ? _otpControllers.every((c) => c.text.isNotEmpty)
                      : _isPhoneValid,
                  onPressed: _showOTPInput ? _verifyOTP : () => _sendOTP('whatsapp'),
                ),
                if (_showOTPInput) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _showOTPInput = false);
                      },
                      child: const Text('Ganti nomor telepon'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: _ResendOTPButton(onResend: _sendOTP)),
                ],
                if (!_showOTPInput) ...[
                  const SizedBox(height: 16),
                  _SocialLoginButton(
                    icon: Icons.telegram,
                    label: 'Kirim via Telegram',
                    onPressed: (_isPhoneValid && !_isLoading) ? () => _sendOTP('telegram') : null,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'atau masuk dengan',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SocialLoginButton(
                    icon: Icons.fingerprint,
                    label: 'Masuk dengan Biometrik',
                    onPressed: _isLoading ? null : _loginWithBiometric,
                    isPrimary: true,
                  ),
                ],
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Dengan melanjutkan, Anda menyetujui\nSyarat & Ketentuan dan Kebijakan Privasi',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return PhoneInputField(
      controller: _phoneController,
      validator: (value) {
        final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';
        if (phone.isEmpty) return 'Nomor telepon wajib diisi';
        if (phone.length < 10) return 'Nomor telepon tidak valid';
        return null;
      },
    );
  }

  Widget _buildOTPInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      // UBAH GENERATE LOOP KE 4 KOTAK
      children: List.generate(4, (index) {
        return SizedBox(
          width: 56, // Sedikit dilebarkan biar lebih proporsional untuk 4 kotak
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: AppTypography.headlineMedium,
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: AppShapes.borderRadiusMD,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppShapes.borderRadiusMD,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _handleOTPInput(value, index),
          ),
        );
      }),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: isPrimary ? AppColors.primary : AppColors.outline,
          ),
          foregroundColor:
              isPrimary ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ResendOTPButton extends StatefulWidget {
  final VoidCallback onResend;

  const _ResendOTPButton({required this.onResend});

  @override
  State<_ResendOTPButton> createState() => _ResendOTPButtonState();
}

class _ResendOTPButtonState extends State<_ResendOTPButton> {
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _canResend
          ? () {
              setState(() {
                _countdown = 60;
                _canResend = false;
              });
              _startCountdown();
              widget.onResend();
            }
          : null,
      child: Text(
        _canResend ? 'Kirim ulang kode' : 'Kirim ulang dalam $_countdown detik',
      ),
    );
  }
}
