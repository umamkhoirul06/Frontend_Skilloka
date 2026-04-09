/// Login Screen with phone, OTP, social, and biometric options
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
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

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

  Future<void> _sendOTP() async {
    if (!_isPhoneValid) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showOTPInput = true;
      });
      _otpFocusNodes[0].requestFocus();
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    // Simulate verification
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      context.go(AppRouter.home);
    }
  }

  void _handleOTPInput(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    // Auto verify when complete
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      _verifyOTP();
    }
  }

  void _loginWithGoogle() {
    // TODO: Implement Google Sign-In
    context.go(AppRouter.home);
  }

  void _loginWithBiometric() async {
    // TODO: Implement biometric authentication
    context.go(AppRouter.home);
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
                // Header
                Text(
                  _showOTPInput ? 'Verifikasi OTP' : 'Masuk ke Skilloka',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _showOTPInput
                      ? 'Masukkan kode 6 digit yang dikirim ke nomor Anda'
                      : 'Masukkan nomor telepon untuk melanjutkan',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Phone or OTP input
                AnimatedCrossFade(
                  duration: AppAnimations.medium,
                  crossFadeState: _showOTPInput
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: _buildPhoneInput(),
                  secondChild: _buildOTPInput(),
                ),

                const SizedBox(height: 24),

                // Continue button
                AnimatedPrimaryButton(
                  text: _showOTPInput ? 'Verifikasi' : 'Lanjutkan',
                  isLoading: _isLoading,
                  isEnabled: _showOTPInput
                      ? _otpControllers.every((c) => c.text.isNotEmpty)
                      : _isPhoneValid,
                  onPressed: _showOTPInput ? _verifyOTP : _sendOTP,
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
                  const SizedBox(height: 40),
                  // Divider
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

                  // Social Login Buttons
                  _SocialLoginButton(
                    icon: Icons.g_mobiledata,
                    label: 'Lanjutkan dengan Google',
                    onPressed: _loginWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  _SocialLoginButton(
                    icon: Icons.fingerprint,
                    label: 'Masuk dengan Biometrik',
                    onPressed: _loginWithBiometric,
                    isPrimary: true,
                  ),
                ],

                const SizedBox(height: 40),

                // Terms
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
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
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
  final VoidCallback onPressed;
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
          foregroundColor: isPrimary
              ? AppColors.primary
              : AppColors.textPrimary,
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
