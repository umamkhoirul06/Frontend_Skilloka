import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_typography.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchController = TextEditingController();
  int? _expandedIndex;
  String _searchQuery = '';

  final List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'Bagaimana cara mendaftar kursus?',
      answer:
          'Cari kursus yang Anda minati di halaman Beranda, klik "Daftar Sekarang", pilih jadwal, lalu lakukan pembayaran. Setelah pembayaran dikonfirmasi, booking Anda akan aktif.',
      category: 'Pendaftaran',
    ),
    _FaqItem(
      question: 'Metode pembayaran apa yang tersedia?',
      answer:
          'Kami menerima berbagai metode pembayaran: Transfer Bank (BCA, Mandiri, BNI, BRI), QRIS, GoPay, OVO, Dana, dan ShopeePay.',
      category: 'Pembayaran',
    ),
    _FaqItem(
      question: 'Bagaimana jika saya ingin membatalkan booking?',
      answer:
          'Pembatalan dapat dilakukan maksimal 24 jam sebelum kelas dimulai dengan refund 80%. Pembatalan kurang dari 24 jam tidak dapat direfund. Hubungi LPK langsung untuk pengecualian.',
      category: 'Pembatalan',
    ),
    _FaqItem(
      question: 'Berapa lama sertifikat dikeluarkan?',
      answer:
          'Sertifikat diterbitkan dalam 3-7 hari kerja setelah Anda menyelesaikan seluruh kelas dan ujian akhir. Anda akan mendapat notifikasi saat sertifikat siap diunduh.',
      category: 'Sertifikat',
    ),
    _FaqItem(
      question: 'Apakah sertifikat diakui secara resmi?',
      answer:
          'Ya. Seluruh LPK di platform Skilloka telah terdaftar dan terverifikasi oleh Dinas Ketenagakerjaan Kabupaten Indramayu. Sertifikat yang diterbitkan diakui secara resmi.',
      category: 'Sertifikat',
    ),
    _FaqItem(
      question: 'Bagaimana cara mengubah jadwal kelas?',
      answer:
          'Perubahan jadwal dapat dilakukan minimal 48 jam sebelum kelas dimulai, tergantung kebijakan masing-masing LPK. Hubungi LPK melalui fitur chat atau telepon di halaman detail LPK.',
      category: 'Jadwal',
    ),
    _FaqItem(
      question: 'Saya lupa password, bagaimana cara mengatur ulang?',
      answer:
          'Pada halaman login, klik "Lupa Password". Masukkan nomor HP atau email yang terdaftar, lalu ikuti instruksi yang dikirimkan melalui SMS atau email Anda.',
      category: 'Akun',
    ),
    _FaqItem(
      question: 'Apakah ada biaya pendaftaran di Skilloka?',
      answer:
          'Tidak ada biaya pendaftaran di Skilloka. Anda hanya membayar biaya kursus yang telah tercantum di setiap program pelatihan.',
      category: 'Pembayaran',
    ),
  ];

  List<_FaqItem> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs
        .where(
          (f) =>
              f.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.answer.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bantuan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppShapes.cardRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pusat Bantuan Skilloka',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kami siap membantu Anda 24/7',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Contact
            Text('Hubungi Kami', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Live Chat',
                    subtitle: 'Online 08.00–22.00',
                    color: AppColors.success,
                    onTap: () => _showComingSoon('Live Chat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.phone_outlined,
                    label: 'Telepon',
                    subtitle: '(0234) 123-4567',
                    color: AppColors.primary,
                    onTap: () => _launchPhone('02341234567'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    subtitle: 'cs@skilloka.id',
                    color: AppColors.secondary,
                    onTap: () => _launchEmail('cs@skilloka.id'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // WhatsApp button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchWhatsApp(),
                icon: const Icon(Icons.message),
                label: const Text('Chat via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppShapes.borderRadiusMD,
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Search
            Text('Pertanyaan Umum (FAQ)', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _expandedIndex = null;
              }),
              decoration: InputDecoration(
                hintText: 'Cari pertanyaan...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: AppShapes.borderRadiusMD,
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppShapes.borderRadiusMD,
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppShapes.borderRadiusMD,
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // FAQ List
            if (_filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Tidak ada hasil untuk "$_searchQuery"',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppShapes.cardRadius,
                  boxShadow: AppShapes.shadowSM,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredFaqs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final faq = _filteredFaqs[index];
                    final isExpanded = _expandedIndex == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: AppShapes.chipRadius,
                                  ),
                                  child: Text(
                                    faq.category,
                                    style: AppTypography.badge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  faq.question,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isExpanded
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: isExpanded
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                              ),
                            ),
                            onTap: () => setState(
                              () => _expandedIndex =
                                  isExpanded ? null : index,
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: AppShapes.borderRadiusMD,
                                ),
                                child: Text(
                                  faq.answer,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppShapes.borderRadiusMD,
          boxShadow: AppShapes.shadowSM,
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera hadir'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderRadiusMD),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _launchPhone(String number) async {
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _launchEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _launchWhatsApp() async {
    const phone = '6281234567890';
    const msg = 'Halo, saya butuh bantuan dengan aplikasi Skilloka';
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeFull(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _FaqItem {
  final String question;
  final String answer;
  final String category;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}
