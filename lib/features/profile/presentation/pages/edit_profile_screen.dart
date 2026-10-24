import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_shapes.dart';

import '../../../../core/theme/app_typography.dart';

import '../../../../core/services/api_service.dart';

import '../../../../models/avatar_frame_data.dart';

import '../../../../widgets/profile_frame_avatar.dart';

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

  XFile? _selectedImage;

  Uint8List? _selectedImageBytes;

  String? _existingPhotoUrl;

  bool _useCustomPhoto = true;

  AvatarItem _selectedAvatar = dummyAvatars.first;

  FrameItem _selectedFrame = dummyFrames.first;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();

    _setupChangeListeners();

    _loadProfile();
  }

  void _setupChangeListeners() {
    void listener() {
      if (mounted && !_isLoadingData && !_hasChanges) {
        setState(() => _hasChanges = true);
      }
    }

    _namaController.addListener(listener);

    _phoneController.addListener(listener);

    _emailController.addListener(listener);

    _alamatController.addListener(listener);
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

  Future<void> _loadProfile() async {
    setState(() => _isLoadingData = true);

    try {
      final result = await _api.getProfile();

      if (!mounted) return;

      if (result['success']) {
        final raw = result['data'];
        final data = raw['data'] ?? raw;

        setState(() {
          _namaController.text = data['name'] ?? '';

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

          // Memuat jenis avatar dari database.
          _useCustomPhoto = (data['avatar_type'] ?? 'photo') != 'dummy';

          // Memuat karakter yang tersimpan.
          final savedAvatarId = (data['avatar_id'] ?? '').toString();
          final avatarMatch =
              RegExp(r'character_(\d{2})').firstMatch(savedAvatarId);

          final avatarIndex = avatarMatch != null
              ? int.tryParse(avatarMatch.group(1)!) ?? 1
              : 1;

          if (avatarIndex >= 1 && avatarIndex <= dummyAvatars.length) {
            _selectedAvatar = dummyAvatars[avatarIndex - 1];
          } else {
            _selectedAvatar = dummyAvatars.first;
          }

          // Memuat frame yang tersimpan.
          final savedFrameId = (data['frame_id'] ?? 'none').toString();

          final savedFrameType = switch (savedFrameId) {
            'none' => FrameType.simple,
            'soft' => FrameType.cute,
            'glow' => FrameType.glow,
            'sparkle' => FrameType.sparkle,
            'gradient' => FrameType.gradient,
            _ => FrameType.simple,
          };

          _selectedFrame = dummyFrames.firstWhere(
            (frame) => frame.type == savedFrameType,
            orElse: () => dummyFrames.first,
          );

          _isLoadingData = false;
          _hasChanges = false;
        });
      } else {
        setState(() => _isLoadingData = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Gagal memuat profil',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);

                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primary,
                ),
                title: const Text('Ambil Foto Kamera'),
                onTap: () {
                  Navigator.pop(ctx);

                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();

        if (!mounted) return;

        setState(() {
          _selectedImage = picked;

          _selectedImageBytes = bytes;

          _useCustomPhoto = true;

          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memilih foto'),
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime(
        now.year - 10,
        now.month,
        now.day,
      ),
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);

    final nav = Navigator.of(context);

    try {
      if (_selectedImage != null) {
        final photoResult = await _api.uploadProfilePhoto(_selectedImage!);

        if (!mounted) return;

        if (!photoResult['success']) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Gagal upload foto: ${photoResult['message']}',
              ),
              backgroundColor: AppColors.error,
            ),
          );

          setState(() => _isLoading = false);

          return;
        }
      }

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

        // Pengaturan avatar
        avatarType: _useCustomPhoto ? 'photo' : 'dummy',

        avatarId: _useCustomPhoto
            ? null
            : 'character_${(dummyAvatars.indexOf(_selectedAvatar) + 1).toString().padLeft(2, '0')}',

        // Pengaturan frame
        frameId: switch (_selectedFrame.type) {
          FrameType.simple => 'none',
          FrameType.glow => 'glow',
          FrameType.sparkle => 'sparkle',
          FrameType.gradient => 'gradient',
          _ => 'soft',
        },
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success']) {
        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Text('Profil berhasil diperbarui!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppShapes.borderRadiusMD,
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        nav.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Gagal menyimpan profil',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.borderRadiusLG,
        ),
        title: const Text('Buang perubahan?'),
        content: const Text(
          'Anda memiliki perubahan yang belum disimpan. '
          'Yakin ingin keluar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final nav = Navigator.of(context);

          final canLeave = await _onWillPop();

          if (canLeave && mounted) {
            nav.pop();
          }
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Simpan'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(),
              )
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
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              prefix: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 15,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '+62',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Nomor HP wajib diisi';
                                }

                                if (v.length < 9) {
                                  return 'Nomor HP tidak valid';
                                }

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
                                    r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$',
                                  ).hasMatch(v)) {
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppShapes.borderRadiusMD,
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Simpan Perubahan',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
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

  Widget _buildAvatarSection() {
    final bool hasNewPhoto = _selectedImageBytes != null;

    final bool hasExistingPhoto =
        _existingPhotoUrl != null && _existingPhotoUrl!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: ProfileFrameAvatar(
            key: ValueKey(
              '${_useCustomPhoto}_${_useCustomPhoto ? (_selectedImage?.name ?? _existingPhotoUrl ?? 'default') : _selectedAvatar.id}_${_selectedFrame.id}',
            ),
            size: 110,
            frameType: _selectedFrame.type,
            isCustomPhoto: _useCustomPhoto,
            selectedAvatar: _selectedAvatar,
            imageWidget: hasNewPhoto
                ? Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.cover,
                  )
                : hasExistingPhoto
                    ? Image.network(
                        ApiService.toFullUrl(
                          _existingPhotoUrl,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.person,
                            size: 52,
                            color: Colors.grey,
                          );
                        },
                      )
                    : null,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Foto Profil',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Gunakan foto sendiri atau pilih avatar lucu',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildAvatarModeButton(
                icon: Icons.camera_alt_outlined,
                label: 'Foto Pribadi',
                selected: _useCustomPhoto,
                onTap: () {
                  setState(() {
                    _useCustomPhoto = true;
                    _hasChanges = true;
                  });

                  _showImagePickerOptions();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAvatarModeButton(
                icon: Icons.pets_outlined,
                label: 'Pilih Avatar',
                selected: !_useCustomPhoto,
                onTap: () {
                  setState(() {
                    _useCustomPhoto = false;
                    _hasChanges = true;
                  });
                },
              ),
            ),
          ],
        ),
        if (!_useCustomPhoto) ...[
          const SizedBox(height: 22),
          _buildAvatarPicker(),
        ],
        const SizedBox(height: 24),
        _buildFramePicker(),
      ],
    );
  }

  Widget _buildAvatarModeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(
                      alpha: 0.08,
                    )
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  



Widget _buildAvatarPicker() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Pilih Avatar',
        style: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        'Pilih avatar yang kamu suka',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 8),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final columns = width < 360
              ? 4
              : width < 600
                  ? 5
                  : width < 900
                      ? 7
                      : 9;

          final spacing = width < 600 ? 6.0 : 8.0;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: dummyAvatars.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final avatar = dummyAvatars[index];
              final selected = avatar.id == _selectedAvatar.id;

              return Tooltip(
                message: avatar.name,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar;
                      _useCustomPhoto = false;
                      _hasChanges = true;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.10)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        avatar.assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: const Color(0xFFF3EEFF),
                            alignment: Alignment.center,
                            child: Icon(
                              avatar.fallbackIcon,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ],
  );
}




  Widget _buildFramePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Bingkai',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bingkai juga bisa digunakan pada foto pribadi',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dummyFrames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final frame = dummyFrames[index];

              final selected = frame.id == _selectedFrame.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFrame = frame;
                    _hasChanges = true;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 82,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(
                            alpha: 0.08,
                          )
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? AppColors.primary.withValues(
                                  alpha: 0.12,
                                )
                              : Colors.white,
                        ),
                        child: Icon(
                          frame.icon,
                          size: 22,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        frame.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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
                child: Icon(
                  icon,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

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
        prefixIcon: prefix != null
            ? null
            : Icon(
                icon,
                size: 20,
              ),
        prefix: prefix,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.wc_outlined,
              size: 20,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              'Jenis Kelamin',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
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
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  margin: EdgeInsets.only(
                    right: gender == 'Laki-laki' ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceVariant,
                    borderRadius: AppShapes.borderRadiusMD,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.outline,
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
                      const SizedBox(
                        width: 6,
                      ),
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

  Widget _buildDatePicker() {
    final formatted = _selectedDate != null
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/'
            '${_selectedDate!.month.toString().padLeft(2, '0')}/'
            '${_selectedDate!.year}'
        : 'Pilih tanggal lahir';

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppShapes.borderRadiusMD,
          border: Border.all(
            color: AppColors.outline,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cake_outlined,
              size: 20,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Lahir',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    formatted,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
