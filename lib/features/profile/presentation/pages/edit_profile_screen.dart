import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _namaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _alamatController = TextEditingController();

  String _selectedGender = 'Laki-laki';
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _hasChanges = false;
  File? _selectedImage;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    _namaController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  // ── Load data profil dari API ─────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _isLoadingData = true);
    try {
      final result = await _api.getProfile();
      if (!mounted) return;
      if (result['success']) {
        // Sesuaikan dengan struktur response Laravel kamu
        final raw = result['data'];
        final data = raw['data'] ?? raw;

        setState(() {
          _namaController.text = data['name'] ?? '';
          // Bersihkan prefix +62 / 62
          final rawPhone = (data['phone'] ?? '').toString();
          _phoneController.text = rawPhone.startsWith('62')
              ? rawPhone.substring(2)
              : rawPhone.startsWith('+62')
                  ? rawPhone.substring(3)
                  : rawPhone;
          _emailController.text = data['email'] ?? '';
          _alamatController.text = data['address'] ?? '';
          _selectedGender =
              (data['gender'] ?? 'male') == 'male' ? 'Laki-laki' : 'Perempuan';
          if (data['birth_date'] != null) {
            try {
              _selectedDate = DateTime.parse(data['birth_date']);
            } catch (_) {}
          }
          _existingPhotoUrl = data['photo_url'] ?? data['avatar'];
          _isLoadingData = false;
          _hasChanges = false;
        });

        // Mulai track perubahan SETELAH data diisi
        for (final c in [
          _namaController,
          _phoneController,
          _emailController,
          _alamatController,
        ]) {
          c.addListener(() {
            if (mounted) setState(() => _hasChanges = true);
          });
        }
      } else {
        setState(() => _isLoadingData = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal memuat profil'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // ── Pilih foto dari galeri ────────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedImage = File(picked.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka galeri')),
        );
      }
    }
  }

  // ── Pilih tanggal lahir ───────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 10, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _hasChanges = true;
      });
    }
  }

  // ── Simpan profil ke API ──────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      // 1. Upload foto dulu kalau ada yang dipilih
      if (_selectedImage != null) {
        final photoResult = await _api.uploadProfilePhoto(_selectedImage!);
        if (!photoResult['success']) {
          messenger.showSnackBar(SnackBar(
            content: Text('Gagal upload foto: ${photoResult['message']}'),
            backgroundColor: AppColors.error,
          ));
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. Update data profil
      final result = await _api.updateProfile(
        name: _namaController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _alamatController.text.trim().isEmpty
            ? null
            : _alamatController.text.trim(),
        gender: _selectedGender == 'Laki-laki' ? 'male' : 'female',
        birthDate: _selectedDate != null
            ? '${_selectedDate!.year}-'
                '${_selectedDate!.month.toString().padLeft(2, '0')}-'
                '${_selectedDate!.day.toString().padLeft(2, '0')}'
            : null,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        messenger.showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Profil berhasil diperbarui!'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusMD),
          margin: const EdgeInsets.all(16),
        ));
        nav.pop(true); // Kembalikan true agar profile_screen refresh
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan profil'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  // ── Konfirmasi buang perubahan ────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusLG),
        title: const Text('Buang perubahan?'),
        content: const Text(
            'Anda memiliki perubahan yang belum disimpan. Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child:
                const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final nav = Navigator.of(context);
          final canLeave = await _onWillPop();
          if (canLeave && mounted) nav.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Profil'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (_hasChanges && !_isLoadingData)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Simpan'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
          ],
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnim,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 32),
                        _buildSectionCard(
                          title: 'Informasi Pribadi',
                          icon: Icons.person_outline,
                          children: [
                            _buildTextField(
                              controller: _namaController,
                              label: 'Nama Lengkap',
                              icon: Icons.badge_outlined,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Nama wajib diisi'
                                  : null,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 16),
                            _buildGenderSelector(),
                            const SizedBox(height: 16),
                            _buildDatePicker(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Kontak',
                          icon: Icons.contact_phone_outlined,
                          children: [
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Nomor HP',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              prefix: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 15),
                                decoration: BoxDecoration(
                                  border: Border(
                                      right: BorderSide(
                                          color: AppColors.outline)),
                                ),
                                child: Text('+62',
                                    style: AppTypography.bodyMedium),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Nomor HP wajib diisi';
                                if (v.length < 9) return 'Nomor HP tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email (opsional)',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  if (!RegExp(
                                          r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$')
                                      .hasMatch(v)) {
                                    return 'Format email tidak valid';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Alamat',
                          icon: Icons.location_on_outlined,
                          children: [
                            _buildTextField(
                              controller: _alamatController,
                              label: 'Alamat Lengkap',
                              icon: Icons.home_outlined,
                              maxLines: 3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppShapes.borderRadiusMD),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Simpan Perubahan',
                                    style: AppTypography.labelLarge.copyWith(
                                        color: Colors.white, fontSize: 15),
                                  ),
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

  // ── Avatar ────────────────────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          // Prioritas: foto baru dipilih > foto dari server > icon default
          child: ClipOval(
            child: _selectedImage != null
                ? Image.file(_selectedImage!,
                    fit: BoxFit.cover, width: 100, height: 100)
                : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty)
                    ? Image.network(
                        _existingPhotoUrl!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 52, color: Colors.white),
                      )
                    : const Icon(Icons.person, size: 52, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section Card ──────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppShapes.cardRadius,
        boxShadow: AppShapes.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppShapes.borderRadiusSM,
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // ── Text Field ────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? prefix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix != null ? null : Icon(icon, size: 20),
        prefix: prefix,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Gender Selector ───────────────────────────────────────────────────────
  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wc_outlined, size: 20, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text('Jenis Kelamin',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Laki-laki', 'Perempuan'].map((gender) {
            final selected = _selectedGender == gender;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedGender = gender;
                  _hasChanges = true;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:
                      EdgeInsets.only(right: gender == 'Laki-laki' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceVariant,
                    borderRadius: AppShapes.borderRadiusMD,
                    border: Border.all(
                      color:
                          selected ? AppColors.primary : AppColors.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        gender == 'Laki-laki' ? Icons.male : Icons.female,
                        size: 18,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gender,
                        style: AppTypography.labelMedium.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Date Picker ───────────────────────────────────────────────────────────
  Widget _buildDatePicker() {
    final formatted = _selectedDate != null
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/'
            '${_selectedDate!.month.toString().padLeft(2, '0')}/'
            '${_selectedDate!.year}'
        : 'Pilih tanggal lahir';

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppShapes.borderRadiusMD,
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined,
                size: 20, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal Lahir',
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary, fontSize: 11)),
                  Text(formatted, style: AppTypography.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}