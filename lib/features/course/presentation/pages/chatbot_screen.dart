import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/chatbot_avatar_3d.dart';

/// Chatbot Screen — PRD section 20
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _messages.add(_ChatMessage(
      text:
          'Halo! Saya **Asisten AI Skilloka**.\n\nSaya siap membantu Anda:\n• Menemukan kursus dan pelatihan sesuai minat keahlian\n• Informasi lembaga LPK terverifikasi dan jadwal kelas\n• Panduan proses pendaftaran dan pembayaran kursus\n• Ketentuan sertifikasi kompetensi resmi Disnaker\n\nAda yang ingin Anda tanyakan?',
      isBot: true,
      time: DateTime.now(),
    ));

    _loadHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getChatbotHistory();
      if (result['success'] == true && mounted) {
        final data = result['data'];
        List<dynamic> rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map) {
          rawList = (data['data'] ?? data['messages'] ?? []) as List<dynamic>;
        }

        final historyMessages = rawList.expand((e) {
          final msg = Map<String, dynamic>.from(e as Map);
          return [
            if (msg['user_message'] != null)
              _ChatMessage(
                text: msg['user_message'].toString(),
                isBot: false,
                time: DateTime.tryParse(msg['created_at']?.toString() ?? '') ??
                    DateTime.now(),
              ),
            if (msg['bot_response'] != null)
              _ChatMessage(
                text: msg['bot_response'].toString(),
                isBot: true,
                time: DateTime.tryParse(msg['created_at']?.toString() ?? '') ??
                    DateTime.now(),
              ),
          ];
        }).toList();

        if (historyMessages.isNotEmpty) {
          setState(() {
            _messages = [_messages.first, ...historyMessages];
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      // History is optional, fail silently
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false, time: DateTime.now()));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final result = await _api.sendChatbotMessage(text);
      String reply = '';

      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map) {
          reply = (data['reply'] ?? data['response'] ?? data['message'] ?? '')
              .toString();
        } else if (data is String) {
          reply = data;
        }
      }

      // Jika backend tidak mengembalikan reply (endpoint tidak ada atau error), gunakan fallback lokal
      if (reply.isEmpty) {
        reply = _generateLocalReply(text);
      }

      if (mounted && reply.isNotEmpty) {
        setState(() {
          _messages.add(_ChatMessage(
            text: reply,
            isBot: true,
            time: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Saat koneksi gagal, gunakan fallback lokal
      final fallback = _generateLocalReply(text);
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: fallback,
            isBot: true,
            time: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Fallback jawaban lokal ketika backend chatbot tidak tersedia
  String _generateLocalReply(String userMessage) {
    final msg = userMessage.toLowerCase();

    if (msg.contains('kursus') &&
        (msg.contains('apa') || msg.contains('tersedia') || msg.contains('ada'))) {
      return 'Di Skilloka tersedia berbagai pilihan bidang kursus kejuruan:\n\n• **Teknik & Otomotif**: Pelatihan las listrik/argon, mekanik motor/mobil, dan operator bubut CNC.\n• **Teknologi & Digital**: Administrasi perkantoran, desain grafis multimedia, dan pemrograman web.\n• **Bahasa Asing**: Bahasa Jepang, Korea, dan Inggris untuk persiapan karir luar negeri.\n• **Bisnis & Manajemen**: Manajemen ritel, akuntansi dasar, dan kewirausahaan.\n• **Pariwisata & Jasa**: Perhotelan, tata boga kuliner, barista, dan tata rias.\n\nSilakan buka menu **Pencarian** untuk melihat daftar kurikulum dan silabus lengkap.';
    }

    if (msg.contains('booking') || msg.contains('daftar') || msg.contains('cara')) {
      return 'Tahapan pendaftaran kursus di Skilloka:\n\n1. Pilih program pelatihan yang diminati pada katalog kursus.\n2. Klik tombol "Daftar Sekarang" pada halaman detail kursus.\n3. Pilih jadwal kelas dan batch pelatihan yang tersedia.\n4. Konfirmasi data diri peserta dan pilih metode pembayaran.\n5. Selesaikan transaksi via Transfer Bank atau QRIS.\n\nNotifikasi bukti pendaftaran resmi akan otomatis dikirimkan ke akun dan WhatsApp Anda.';
    }

    if (msg.contains('biaya') || msg.contains('harga') || msg.contains('bayar')) {
      return 'Kisaran biaya pelatihan di Skilloka disesuaikan dengan jenis dan durasi program:\n\n• **Program Singkat (1–2 minggu)**: Rp 500.000 – Rp 1.500.000\n• **Program Reguler (1–3 bulan)**: Rp 1.500.000 – Rp 5.000.000\n• **Program Sertifikasi Profesi**: Rp 3.000.000 – Rp 8.000.000\n\nBeberapa program juga didukung subsidi program pelatihan Disnaker. Informasi biaya transparan dapat dicek pada tiap detail kursus.';
    }

    if (msg.contains('sertifikat') || msg.contains('syarat')) {
      return 'Syarat kelulusan untuk memperoleh sertifikat pelatihan:\n\n• Tingkat kehadiran tatap muka/praktik minimal 80%\n• Menyelesaikan seluruh modul tugas dan praktik keahlian\n• Lulus evaluasi uji kompetensi akhir dengan nilai minimal 70/100\n\nSertifikat diterbitkan resmi oleh LPK berizin Disnaker dan dilengkapi verifikasi QR Code.';
    }

    if (msg.contains('lpk') || msg.contains('lembaga') || msg.contains('terdekat')) {
      return 'Seluruh LPK yang bermitra dengan Skilloka telah terverifikasi secara resmi oleh Disnaker Indramayu.\n\nAnda dapat memfilter lembaga pelatihan berdasarkan kecamatan, meninjau profil fasilitas, rekam jejak instruktur, serta ulasan alumni di menu **Pencarian LPK**.';
    }

    if (msg.contains('halo') ||
        msg.contains('hi') ||
        msg.contains('hai') ||
        msg.contains('hello')) {
      return 'Halo! Senang dapat menyapa Anda di Skilloka. Apakah ada informasi kursus, rekomendasi LPK, atau panduan pendaftaran yang ingin Anda ketahui?';
    }

    if (msg.contains('terima kasih') ||
        msg.contains('makasih') ||
        msg.contains('thanks')) {
      return 'Sama-sama. Semoga pelatihan yang Anda pilih dapat menunjang perkembangan karir Anda. Jangan ragu bertanya kembali jika membutuhkan bantuan.';
    }

    // Default fallback
    final responses = [
      'Terima kasih atas pertanyaan Anda. Untuk informasi lebih spesifik mengenai "$userMessage", silakan telusuri katalog kursus di menu Pencarian atau hubungi LPK terkait melalui rincian kontak di aplikasi.',
      'Pertanyaan Anda sedang kami catat. Anda juga dapat melihat jadwal kelas terbaru atau berkonsultasi mengenai persyaratan pelatihan di menu Beranda dan Pencarian.',
    ];
    return responses[Random().nextInt(responses.length)];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  final List<String> _quickReplies = [
    'Kursus yang tersedia',
    'Cara pendaftaran kursus',
    'Kisaran biaya kursus',
    'Syarat sertifikat kompetensi',
    'Rekomendasi LPK terdekat',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              minHeight: 2,
            ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: _messages.length + (_messages.length <= 1 ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_messages.length <= 1 && i == 0) {
                    return _buildHeroAvatarHeader(context);
                  }
                  final msgIndex = _messages.length <= 1 ? i - 1 : i;
                  return _ChatBubble(
                    message: _messages[msgIndex],
                    isLast: msgIndex == _messages.length - 1,
                  );
                },
              ),
            ),
          ),
          if (_messages.length <= 2) _buildQuickReplies(context),
          if (_isSending) _buildTypingRow(context),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildHeroAvatarHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const ChatBotAvatar3D(
            size: 96,
            showShadow: true,
            showRing: true,
          ),
          const SizedBox(height: 14),
          Text(
            'Asisten Virtual AI Skilloka',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pusat informasi pelatihan kejuruan & LPK resmi di Indramayu',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor:
          isDark ? const Color(0xFF1E293B) : AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
        color: Colors.white,
      ),
      title: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChatBotAvatar3D(
              size: 40,
              showShadow: false,
              showRing: true,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Asisten Skilloka',
                  style: AppTypography.titleSmall
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Text('Online',
                      style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color: Colors.white.withValues(alpha: 0.8), size: 20),
          onPressed: () {
            setState(() {
              _messages = [_messages.first];
            });
          },
          tooltip: 'Hapus riwayat',
        ),
      ],
    );
  }

  Widget _buildTypingRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: ChatBotAvatar3D(
              size: 26,
              showShadow: false,
              showRing: false,
            ),
          ),
          const SizedBox(width: 8),
          _TypingIndicator(),
          const SizedBox(width: 6),
          Text('Sedang mengetik...',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              )),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Text(
              'Pertanyaan Cepat',
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return InkWell(
                  onTap: () {
                    _msgController.text = _quickReplies[i]
                        .replaceAll(RegExp(r'^[^\w\s]+\s*'), '');
                    _sendMessage();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      border:
                          Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _quickReplies[i],
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _msgController,
                focusNode: _focusNode,
                style: AppTypography.bodyMedium,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  final DateTime time;

  _ChatMessage({required this.text, required this.isBot, required this.time});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isLast;

  const _ChatBubble({required this.message, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr =
        '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot) ...[
            const Padding(
              padding: EdgeInsets.only(right: 8, bottom: 2),
              child: ChatBotAvatar3D(
                size: 32,
                showShadow: false,
                showRing: false,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isBot
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isBot
                        ? (isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white)
                        : AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isBot
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                      bottomRight: isBot
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isBot
                        ? Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : AppColors.outline,
                          )
                        : null,
                  ),
                  child: _buildMessageText(context, message.text, isBot),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (!isBot) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildMessageText(
      BuildContext context, String text, bool isBot) {
    // Parse simple **bold** markdown
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    final baseStyle = AppTypography.bodyMedium.copyWith(
      color: isBot
          ? Theme.of(context).colorScheme.onSurface
          : Colors.white,
      height: 1.5,
    );

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final delay = i * 0.2;
              final val = (_controller.value - delay).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6 + val * 4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.5 + val * 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
