import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AvatarPickerSheet extends StatefulWidget {
  final Function(String avatarUrl)? onAvatarSelected;
  final Function(List<int> bytes)? onCustomImageSelected;

  const AvatarPickerSheet({
    super.key,
    this.onAvatarSelected,
    this.onCustomImageSelected,
  });

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  List<int>? _selectedCustomBytes;

  Future<void> _pickCustomImage() async {
    // Penanganan/pemilihan file gambar kustom
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Foto Profil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAvatarTab(),
        ],
      ),
    );
  }

  Widget _buildAvatarTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Upload Button
          OutlinedButton.icon(
            onPressed: _pickCustomImage,
            icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
            label: Text(
              _selectedCustomBytes != null
                  ? 'Ganti Foto Dari Galeri'
                  : 'Unggah Foto Dari Galeri',
            ),
          ),
        ],
      ),
    );
  }
}