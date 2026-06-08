import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();

  String _userName = '';
  String _userPhone = '';
  String? _userPhotoUrl;
  int _activeBookings = 0;
  int _certificates = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // 🔥 TAMBAHAN VARIABEL BACKGROUND GALERI
  List<String> _bgGallery = [];
  int _currentBgIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // ── Fetch profil dari API ─────────────────────────────────────────────────
  Future<void> _fetchProfile() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

    try {
      final result = await _api.getProfile();
      if (!mounted) return;

      if (result['success']) {
        final raw = result['data'];
        final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;

        // 🔥 MENCOBA MENGAMBIL GALERI JIKA DIA ADMIN LPK
        List<String> extractedGallery = [];
        if (data['lpk'] != null && data['lpk']['images'] != null) {
          final imgs = data['lpk']['images'];
          if (imgs is List) {
            extractedGallery =
                imgs.map((e) => ApiService.toFullUrl(e.toString())).toList();
          }
        }

        setState(() {
          _userName = data['name'] ?? 'Pengguna';
          _userPhone = data['phone'] ?? '';
          _userPhotoUrl = data['photo_url'] ?? data['avatar'] ?? data['photo'];
          _activeBookings = data['active_bookings_count'] ?? 0;
          _certificates = data['certificates_count'] ?? 0;
          _bgGallery = extractedGallery; // Simpan galeri LPK sebagai Background
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Koneksi gagal';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile(BuildContext context) async {
    final updated = await context.push<bool>(AppRouter.editProfile);
    if (updated == true && mounted) {
      _fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              backgroundColor: AppColors.background,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Text('Profil Saya', style: AppTypography.titleMedium),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Pengaturan',
                  onPressed: () => context.push(AppRouter.settings),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : Column(
                      children: [
                        _buildHeroHeader(context),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildStatsRow(),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildQuickActions(context),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildMenuList(context),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildLogoutButton(context),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
      ],
    );
  }

  // ── Hero Header (DENGAN GALERI BACKGROUND) ─────────────────────────────
  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      children: [
        // 🔥 LAYER 1: Background Gradient ATAU Slider Gambar
        Positioned.fill(
          child: _bgGallery.isNotEmpty
              ? PageView.builder(
                  itemCount: _bgGallery.length,
                  onPageChanged: (idx) => setState(() => _currentBgIndex = idx),
                  itemBuilder: (ctx, idx) => Image.network(
                    _bgGallery[idx],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration:
                          const BoxDecoration(gradient: AppColors.heroGradient),
                    ),
                  ),
                )
              : Container(
                  decoration:
                      const BoxDecoration(gradient: AppColors.heroGradient),
                ),
        ),

        // 🔥 LAYER 2: Overlay Hitam (Agar teks & avatar tetap jelas dibaca)
        if (_bgGallery.isNotEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),

        // 🔥 LAYER 3: Konten Utama (Avatar, Nama, Tombol)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
          child: Column(
            children: [
              // Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5EEAD4), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                          ? Image.network(
                              _userPhotoUrl!,
                              fit: BoxFit.cover,
                              width: 88,
                              height: 88,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 44,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.person,
                              size: 44, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _navigateToEditProfile(context),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Nama
              Text(
                _userName.isEmpty ? 'Pengguna' : _userName,
                style: AppTypography.titleLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),

              // Nomor HP
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: AppShapes.chipRadius,
                  ),
                  child: Text(
                    _errorMessage!,
                    style:
                        AppTypography.bodySmall.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      _userPhone.isEmpty ? '-' : _userPhone,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Tombol Edit Profil
              OutlinedButton.icon(
                onPressed: () => _navigateToEditProfile(context),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Profil'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppShapes.chipRadius),
                ),
              ),

              // 🔥 INDICATOR DOTS JIKA GALERI LEBIH DARI 1
              if (_bgGallery.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_bgGallery.length, (index) {
                      return AnimatedContainer(
                        duration: AppAnimations.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentBgIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentBgIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppShapes.cardRadius,
        boxShadow: AppShapes.shadowMD,
      ),
      child: Row(
        children: [
          _buildStatCell(
              '$_activeBookings', 'Kursus Aktif', Icons.school_outlined),
          _buildStatDivider(),
          _buildStatCell(
              '$_certificates', 'Sertifikat', Icons.workspace_premium_outlined),
        ],
      ),
    );
  }

  Widget _buildStatCell(String value, String label, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(value,
                style: AppTypography.headlineSmall
                    .copyWith(color: AppColors.textPrimary, fontSize: 22)),
            Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() =>
      Container(width: 1, height: 56, color: AppColors.outline);

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: 'Pesanan',
        color: AppColors.primary,
        onTap: () => context.go(AppRouter.bookings),
      ),
      _QuickAction(
        icon: Icons.workspace_premium_outlined,
        label: 'Sertifikat',
        color: AppColors.warning,
        onTap: () => context.push(AppRouter.certificates),
      ),
      _QuickAction(
        icon: Icons.favorite_outline,
        label: 'Favorit',
        color: AppColors.error,
        onTap: () => context.push(AppRouter.favorites),
      ),
      _QuickAction(
        icon: Icons.notifications_outlined,
        label: 'Notifikasi',
        color: AppColors.secondary,
        onTap: () => context.push(AppRouter.notifications),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Akses Cepat', style: AppTypography.titleSmall),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: GestureDetector(
                onTap: a.onTap,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.1),
                        borderRadius: AppShapes.borderRadiusMD,
                        border:
                            Border.all(color: a.color.withValues(alpha: 0.2)),
                      ),
                      child: Icon(a.icon, color: a.color, size: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(a.label,
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Menu List ─────────────────────────────────────────────────────────────
  Widget _buildMenuList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu', style: AppTypography.titleSmall),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppShapes.cardRadius,
            boxShadow: AppShapes.shadowSM,
          ),
          child: Column(
            children: [
              _buildMenuItem(
                context,
                icon: Icons.help_outline,
                iconColor: AppColors.categoryIT,
                iconBg: const Color(0xFFDBEAFE),
                title: 'Bantuan & FAQ',
                subtitle: 'Pusat bantuan & hubungi kami',
                onTap: () => context.push(AppRouter.help),
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                iconColor: AppColors.textSecondary,
                iconBg: AppColors.surfaceVariant,
                title: 'Tentang Aplikasi',
                subtitle: 'Versi 1.0.0',
                onTap: () => context.push(AppRouter.about),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShapes.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: AppShapes.borderRadiusSM),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.labelLarge),
                    Text(subtitle,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: AppShapes.chipRadius),
                  child: Text(badge,
                      style: AppTypography.badge.copyWith(color: Colors.white)),
                )
              else
                const Icon(Icons.chevron_right,
                    color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 72, endIndent: 16);

  // ── Logout ────────────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Keluar dari Akun'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusMD),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusLG),
        title: const Text('Keluar dari Akun?'),
        content: const Text(
            'Anda akan keluar dari akun Skilloka. Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _api.logout();
    }
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
