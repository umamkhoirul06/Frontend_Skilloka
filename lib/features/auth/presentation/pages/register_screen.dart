import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atoms/animated_button.dart';
import '../../../../core/widgets/atoms/input_field.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/navigation/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final name = _nameController.text.trim();
    setState(() {
      _isFormValid =
          name.isNotEmpty && phone.length >= 10 && phone.length <= 13;
    });
  }

  Future<void> _register() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      String phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (phone.startsWith('8')) {
        phone = '0$phone';
      } else if (phone.startsWith('62')) {
        phone = '0${phone.substring(2)}';
      }
      final name = _nameController.text.trim();

      final response = await _apiService.register(name, phone);
      final success = response['success'] ?? false;

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Pendaftaran berhasil! Silakan login.')),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRouter.login);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal mendaftar.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Selamat Datang!',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan lengkapi data diri Anda untuk membuat akun di Skilloka.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                AppInputField(
                  label: 'Nama Lengkap',
                  controller: _nameController,
                  hint: 'Contoh: Budi Santoso',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PhoneInputField(
                  controller: _phoneController,
                  validator: (value) {
                    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (phone.isEmpty) return 'Nomor telepon wajib diisi';
                    if (phone.length < 10) return 'Nomor telepon tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                AnimatedPrimaryButton(
                  text: 'Daftar Sekarang',
                  isLoading: _isLoading,
                  isEnabled: _isFormValid,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
