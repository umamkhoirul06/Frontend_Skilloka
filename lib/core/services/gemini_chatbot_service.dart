import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_service.dart';
import '../../features/course/data/models/course_model.dart';

/// Gemini AI Service for Skilloka
class GeminiChatbotService {
  GeminiChatbotService._();
  static final GeminiChatbotService instance = GeminiChatbotService._();

  static const String _storageKeyGeminiApiKey = 'skilloka_gemini_api_key';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Cached API key in memory
  String? _cachedApiKey;

  // Cached live courses from backend database (updated by LPK admins)
  List<CourseModel> _liveCourses = [];
  DateTime? _lastCourseFetchTime;

  /// Cache or refresh live courses from backend database (updated by LPK admins)
  Future<List<CourseModel>> getOrFetchLiveCourses(
      {bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _liveCourses.isNotEmpty &&
        _lastCourseFetchTime != null &&
        now.difference(_lastCourseFetchTime!).inMinutes < 5) {
      return _liveCourses;
    }

    try {
      final api = ApiService();
      final result = await api.getCourses();
      if (result['success'] == true) {
        final data = result['data'];
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          final inner = data['data'];
          if (inner is List) {
            list = inner;
          } else if (inner is Map && inner['data'] is List) {
            list = inner['data'];
          } else if (data['items'] is List) {
            list = data['items'];
          }
        }
        _liveCourses = list
            .whereType<Map>()
            .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _lastCourseFetchTime = now;
        debugPrint(
            '[GeminiChatbotService] Synced ${_liveCourses.length} live courses from backend');
      }
    } catch (e) {
      debugPrint(
          '[GeminiChatbotService] Error fetching live courses from backend: $e');
    }
    return _liveCourses;
  }

  /// System prompt tailored for natural, concise, and friendly conversations with strict guardrails
  static const String systemPrompt = '''
Kamu adalah Loka, konsultan karir vokasi & asisten AI resmi dari Skilloka (platform pencarian, booking pelatihan kerja, dan manajemen LPK berizin resmi Disnaker).

BATASAN TOPIK YANG BOLEH DIJAWAB (GUARDRAILS & RUANG LINGKUP WAJIB):
Kamu HANYA melayani dan menjawab pertanyaan yang berkaitan dengan:
1. **Katalog & Bidang Kursus Vokasi**:
   - Teknik Pengelasan (Las SMAW/GMAW/GTAW Argon).
   - Operator Mesin Bubut & CNC Logam Presisi.
   - Otomotif Sepeda Motor Injeksi & Mobil.
   - IT, Web Programming & Fullstack Developer.
   - Desain Grafis Komersial & Branding.
   - Bahasa Asing Persiapan Kerja (Bahasa Jepang Tokutei Ginou/SSW & Bahasa Inggris Perhotelan/Kapal Pesiar).
   - Barista, Tata Boga/Kuliner, dan Tata Busana/Menjahit.
2. **Lembaga Pelatihan Kerja (LPK)**: Profil LPK mitra resmi Skilloka (LPK Merah Putih, Techno Skill Center, Global English House, dll), fasilitas lab/bengkel kerja, legalitas izin Disnaker, dan lokasi di Indramayu & sekitarnya.
3. **Biaya & Booking Kursus**: Rincian biaya kursus bersubsidi, alur pendaftaran/booking di aplikasi Skilloka, syarat ijazah (SMP/SMA/SMK/Paket C/Umum terbuka), batasan usia, serta metode pembayaran resmi (QRIS, Transfer Bank, cicilan batch).
4. **Sertifikasi BNSP & Legalitas**: Sertifikasi kompetensi resmi Badan Nasional Sertifikasi Profesi (lambang Garuda Emas berstandar SKKNI) dan keuntungan lulusan di mata HRD industri.
5. **Penyaluran Kerja & Magang Luar Negeri**: Jejaring bursa kerja LPK ke kawasan industri manufaktur (Cikarang, Karawang, Cirebon) dan magang resmi ke Jepang / kapal pesiar.
6. **Konseling Minat Bakat & Curhat Karir**: Pendampingan ramah untuk pengguna yang bingung memilih jurusan, belum kerja/menganggur, minder, atau overthinking masa depan — bimbing mereka dengan solusi nyata menguasai 1 skill praktis.
7. **Fitur Aplikasi Skilloka**: Penggunaan aplikasi, alur langganan Skilloka Premium, akses materi digital modul/video, presensi absensi kelas per sesi, e-sertifikat, profil, dan pesanan.

ATURAN WAJIB JIKA PERTANYAAN DI LUAR BATASAN (OUT-OF-SCOPE):
Jika pengguna menanyakan hal di LUAR ruang lingkup di atas (contoh: politik/pemilu, gosip artis/selebriti, rumus matematika/sains murni sekolah umum, resep masakan rumahan non-kursus, kencan/asmara, ramalan zodiak, coding eksploit/hacking ilegal, saran medis kesehatan berat, game online umum, dsb.):
- JANGAN menjawab isi konten pertanyaan di luar topik tersebut.
- TOLAK SECARA RAMAH, SANTUN, DAN BERSAHABAT (DILARANG kaku, kasar, atau terdengar seperti error robot!).
- Sampaikan dengan sopan bahwa sebagai Loka, peranmu khusus fokus mendampingi persiapan karir, kursus pelatihan kerja vokasi, dan LPK di Skilloka.
- Tawarkan 2-3 pilihan topik pelatihan atau konsultasi karir yang relevan agar percakapan tetap nyambung, bermanfaat, dan menyenangkan.
- Format penolakan santun:
  "Pertanyaan yang menarik! Namun sebagai Loka (konsultan karir & asisten Skilloka), fokus utama saya adalah mendampingi kamu seputar pelatihan kerja vokasi, info LPK mitra, pendaftaran kursus, dan konsultasi karir di industri. 😊 Biar obrolan kita tetap relevan dan bermanfaat untuk masa depanmu, ada yang ingin kamu ketahui seputar pilihan kursus seperti teknik las, mesin, otomotif, IT, bahasa Jepang, atau konsultasi minat bakat kerja?"

PANDUAN GAYA JAWABAN (WAJIB DIPATUHI - NATURAL & HEMAT TOKEN):
1. **Bahasa Alami, Santun & Manusiawi**:
   - Bicara santai, ramah, dan bersahabat seperti kakak mentor atau teman ngobrol yang asyik.
   - DILARANG menggunakan kata klise AI robotik seperti: "Tentu saja!", "Pertama-tama peluk jauh untukmu", "Tarik napas dalam-dalam ya", "Sebagai asisten AI...", dll. Jangan berlebihan atau terdengar dibuat-buat.
2. **Singkat, Padat & To The Point (Maksimal 2-3 Paragraf Singkat)**:
   - JANGAN bertele-tele atau membuat karangan esai panjang.
   - Langsung masuk ke inti jawaban atau solusi praktis.
   - Tulis secara ringkas dan enak dibaca di layar HP agar hemat token dan tidak membuat lelah membaca.
3. **Fokus Solusi**:
   - Berikan kejelasan dan langkah praktis yang bisa diambil user hari ini di aplikasi Skilloka.
4. **Akhiri dengan 1 Pertanyaan Singkat**:
   - Berikan 1 pertanyaan santai yang relevan di akhir agar obrolan mengalir natural.
''';

  /// Get active API key (from secure storage, fallback to AppConfig, then fallback to built-in fallback)
  Future<String> getApiKey() async {
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey!;
    }

    try {
      final storedKey = await _secureStorage.read(key: _storageKeyGeminiApiKey);
      if (storedKey != null && storedKey.trim().isNotEmpty) {
        _cachedApiKey = storedKey.trim();
        return _cachedApiKey!;
      }
    } catch (e) {
      debugPrint('[GeminiChatbotService] Error reading secure storage: $e');
    }

    if (AppConfig.geminiApiKey.isNotEmpty) {
      _cachedApiKey = AppConfig.geminiApiKey;
      return _cachedApiKey!;
    }

    return '';
  }

  /// Save custom API key to secure storage
  Future<void> saveApiKey(String apiKey) async {
    final clean = apiKey.trim();
    _cachedApiKey = clean;
    await _secureStorage.write(key: _storageKeyGeminiApiKey, value: clean);
  }

  /// Delete custom API key (reset to default)
  Future<void> resetApiKey() async {
    _cachedApiKey = null;
    await _secureStorage.delete(key: _storageKeyGeminiApiKey);
  }

  /// Check if an API key is available
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key.isNotEmpty;
  }

  /// Generate response with conversation history and live database of courses
  Future<String> getChatResponse({
    required String userMessage,
    List<Map<String, String>> chatHistory = const [],
    List<CourseModel>? optionalLiveCourses,
  }) async {
    final liveCourses = optionalLiveCourses ?? await getOrFetchLiveCourses();
    final apiKey = await getApiKey();

    if (apiKey.isNotEmpty) {
      const models = [
        'gemini-2.0-flash-lite',
        'gemini-2.0-flash',
        'gemini-1.5-flash'
      ];
      for (final model in models) {
        try {
          final response = await _callGeminiApi(
            apiKey: apiKey,
            userMessage: userMessage,
            chatHistory: chatHistory,
            liveCourses: liveCourses,
            modelName: model,
          );
          if (response != null && response.trim().isNotEmpty) {
            return response.trim();
          }
        } catch (e) {
          debugPrint('[GeminiChatbotService] $model failed: $e');
        }
      }
    }

    // High quality contextual reasoning engine with multi-turn context and live database
    return _generateContextualCareerAndCounselingReply(
      userMessage: userMessage,
      chatHistory: chatHistory,
      liveCourses: liveCourses,
    );
  }

  /// Call Google Gemini REST API with injected live courses database
  Future<String?> _callGeminiApi({
    required String apiKey,
    required String userMessage,
    required List<Map<String, String>> chatHistory,
    required List<CourseModel> liveCourses,
    required String modelName,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    // Build contents with recent multi-turn history (max 8 messages for speed)
    final contents = <Map<String, dynamic>>[];

    final recentHistory = chatHistory.length > 8
        ? chatHistory.sublist(chatHistory.length - 8)
        : chatHistory;

    for (final msg in recentHistory) {
      final role = msg['role'] == 'user' ? 'user' : 'model';
      final text = msg['text'] ?? '';
      if (text.isNotEmpty) {
        contents.add({
          'role': role,
          'parts': [
            {'text': text}
          ],
        });
      }
    }

    // Add current user prompt
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final liveDbSummary = liveCourses.isNotEmpty
        ? '\n\nDATABASE RESMI KURSUS TERKINI DARI LPK SKILLOKA (SELALU RUJUK DATA KURSUS DI BAWAH JIKA PENGGUNA BERTANYA SOAL KURSUS/LPK/BIAYA/JADWAL):\n${liveCourses.map((c) => '• ${c.title} | LPK: ${c.lpkName} | Biaya: Rp ${c.price.toInt()} | Durasi: ${c.durationHours} Jam | Kategori: ${c.categoryName} | Info: ${c.description}').join('\n')}'
        : '';

    final dynamicSystemPrompt = systemPrompt + liveDbSummary;

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': dynamicSystemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 400,
        'topP': 0.90,
      },
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 18));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final replyText = parts[0]['text'] as String?;
          return replyText;
        }
      }
    } else {
      debugPrint(
          '[GeminiChatbotService] Gemini HTTP Error ${response.statusCode}: ${response.body}');
    }

    return null;
  }

  /// Deep contextual Career & Counseling Reasoning Engine (Multi-Turn & Domain Aware & Live DB)
  String _generateContextualCareerAndCounselingReply({
    required String userMessage,
    List<Map<String, String>> chatHistory = const [],
    List<CourseModel> liveCourses = const [],
  }) {
    final msg = userMessage.toLowerCase().trim();

    // Check conversation history context
    final historyText = chatHistory
        .take(5)
        .map((m) => (m['text'] ?? '').toLowerCase())
        .join(' ');

    final bool inWeldingContext = historyText.contains('las') ||
        historyText.contains('welding') ||
        historyText.contains('bubut') ||
        historyText.contains('mesin');
    final bool inJapanContext = historyText.contains('jepang') ||
        historyText.contains('tokutei') ||
        historyText.contains('ssw');
    final bool inComputerContext = historyText.contains('komputer') ||
        historyText.contains('coding') ||
        historyText.contains('desain');
    final bool inAutomotiveContext = historyText.contains('otomotif') ||
        historyText.contains('motor') ||
        historyText.contains('injeksi');

    // 0. CEK DATABASE KURSUS LANGSUNG DARI ADMIN LPK DI BACKEND
    final bool asksForCourseList = msg.contains('kursus apa') ||
        msg.contains('ada kursus apa') ||
        msg.contains('daftar kursus') ||
        msg.contains('list kursus') ||
        msg.contains('katalog') ||
        msg.contains('pilihan kursus') ||
        msg.contains('semua kursus') ||
        msg.contains('database kursus') ||
        msg.contains('kursus yang tersedia') ||
        msg.contains('rekomendasi kursus');

    if (asksForCourseList && liveCourses.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln(
          'Berikut kursus pelatihan kerja resmi yang saat ini **aktif dibuka oleh LPK Mitra Skilloka**:');
      buffer.writeln();
      for (int i = 0; i < liveCourses.length; i++) {
        final c = liveCourses[i];
        final priceFormatted = c.price > 0
            ? 'Rp ${c.price.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}'
            : 'Gratis / Bersubsidi';
        buffer.writeln('${i + 1}. **${c.title}**');
        buffer.writeln('   • **LPK**: ${c.lpkName}');
        buffer.writeln(
            '   • **Biaya**: $priceFormatted (${c.durationHours} Jam)');
        buffer.writeln('   • **Kategori**: ${c.categoryName}');
        if (c.description.isNotEmpty) {
          buffer.writeln('   • **Info**: ${c.description}');
        }
        buffer.writeln();
      }
      buffer.writeln(
          'Semua kursus di atas dilengkapi fasilitas bengkel/lab resmi dan sertifikasi BNSP. Ada kursus yang ingin kamu daftarkan atau tanyakan detailnya?');
      return buffer.toString();
    }

    // CEK SPESIFIK NAMA LPK DARI LIVE DATABASE
    if (liveCourses.isNotEmpty) {
      final matchingLpkCourses = liveCourses.where((c) {
        final lpk = c.lpkName.toLowerCase();
        if (msg.contains('merah putih') && lpk.contains('merah putih'))
          return true;
        if (msg.contains('techno skill') && lpk.contains('techno')) return true;
        if (msg.contains('global english') && lpk.contains('global english'))
          return true;
        if (msg.contains('genki') && lpk.contains('genki')) return true;
        return false;
      }).toList();

      if (matchingLpkCourses.isNotEmpty &&
          (msg.contains('kursus') ||
              msg.contains('ada apa') ||
              msg.contains('pelatihan') ||
              msg.contains('biaya') ||
              msg.contains('lpk') ||
              msg.contains('program'))) {
        final lpkName = matchingLpkCourses.first.lpkName;
        final buffer = StringBuffer();
        buffer.writeln(
            'Di **$lpkName**, berikut kursus yang saat ini aktif dibuka:');
        buffer.writeln();
        for (int i = 0; i < matchingLpkCourses.length; i++) {
          final c = matchingLpkCourses[i];
          final priceFormatted = c.price > 0
              ? 'Rp ${c.price.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}'
              : 'Gratis';
          buffer.writeln('${i + 1}. **${c.title}**');
          buffer.writeln(
              '   • **Biaya**: $priceFormatted (${c.durationHours} Jam)');
          buffer.writeln('   • **Kategori**: ${c.categoryName}');
          if (c.description.isNotEmpty) {
            buffer.writeln('   • **Deskripsi**: ${c.description}');
          }
          buffer.writeln();
        }
        buffer.writeln(
            'Kamu bisa langsung mendaftar atau melihat jadwal kelasnya di katalog aplikasi. Ada yang ingin kamu tanyakan lebih lanjut?');
        return buffer.toString();
      }
    }

    // 1. SAPAAN RAMAH & IDENTITAS
    if (msg == 'halo' ||
        msg == 'hai' ||
        msg == 'hi' ||
        msg == 'pagi' ||
        msg == 'selamat pagi' ||
        msg == 'selamat siang' ||
        msg == 'selamat sore' ||
        msg == 'selamat malam' ||
        msg == 'assalamualaikum' ||
        msg == 'tes' ||
        msg == 'test') {
      return 'Halo! Senang bisa ngobrol denganmu. Saya **Loka**, konsultan karir & asisten AI resmi Skilloka.\n\n'
          'Kamu bisa tanya apa saja: rekomendasi kursus LPK, peluang kerja, rincian biaya, sertifikasi BNSP, atau curhat soal arah masa depanmu.\n\n'
          'Ada yang lagi kamu pikirkan atau ingin diskusikan hari ini?';
    }

    if (msg.contains('siapa kamu') ||
        msg.contains('kamu siapa') ||
        msg.contains('apa itu loka') ||
        msg.contains('apa itu skilloka')) {
      return '**Skilloka** adalah platform agregator Lembaga Pelatihan Kerja (LPK) vokasi resmi berizin Disnaker di Indonesia.\n\n'
          'Saya **Loka**, AI yang dirancang untuk mendampingi kamu menemukan pelatihan yang sesuai bakat, membantu persiapan uji kompetensi BNSP, hingga konsultasi penyaluran kerja industri.\n\n'
          'Kamu sedang mencari info kursus atau ingin konsultasi minat bakat?';
    }

    // 2. CURHAT, OVERTHINKING, BINGUNG MASA DEPAN, RASA MINDER & BELUM KERJA
    if (msg.contains('curhat') ||
        msg.contains('bingung') ||
        msg.contains('minder') ||
        msg.contains('takut') ||
        msg.contains('stres') ||
        msg.contains('stress') ||
        msg.contains('nganggur') ||
        msg.contains('capek') ||
        msg.contains('lelah') ||
        msg.contains('overthinking') ||
        msg.contains('putus asa') ||
        msg.contains('gagal') ||
        msg.contains('belum kerja') ||
        msg.contains('belum dapat kerja') ||
        msg.contains('ga punya skill') ||
        msg.contains('tidak punya skill') ||
        msg.contains('insecure') ||
        msg.contains('beban')) {
      return 'Perasaan bingung atau cemas itu wajar banget dialami siapa saja yang lagi di fase transisi. Kamu nggak sendirian, dan jangan merasa terlambat ya.\n\n'
          'Kuncinya: **fokus pada 1 skill praktis yang bisa kamu kuasai dalam 1-3 bulan**. Di Skilloka, pelatihan vokasi dirancang langsung praktik 80%:\n'
          '• Nggak butuh pengalaman sebelumnya.\n'
          '• Instruktur membimbing dari nol sampai bisa.\n'
          '• Lulus langsung pegang portofolio dan sertifikat BNSP resmi untuk melamar kerja.\n\n'
          'Coba ceritakan santai, apa hal yang bikin kamu paling ragu atau cemas sekarang?';
    }

    // 3. SPESIFIK TEKNIK LAS / WELDING
    if (msg.contains('las') ||
        msg.contains('welding') ||
        msg.contains('smaw') ||
        msg.contains('gtaw') ||
        msg.contains('gmaw') ||
        msg.contains('welder')) {
      return 'Bidang **Teknik Las (Welding)** adalah salah satu profesi dengan permintaan tertinggi di kawasan industri manufaktur, fabrikasi, dan galangan kapal!\n\n'
          'Di LPK Skilloka (seperti LPK Merah Putih Indramayu):\n'
          '• Pelatihan mencakup teknik las SMAW, GMAW, dan GTAW (Argon) posisi 1G hingga 3G/6G.\n'
          '• Bimbingan standar keselamatan K3 bengkel.\n'
          '• Sertifikasi kompetensi resmi BNSP yang diakui secara nasional (potensi gaji Rp 5jt - 10jt+).\n\n'
          'Tertarik mulai belajar las dari level dasar atau sudah pernah pegang alat las sebelumnya?';
    }

    // 4. BUBUT, MESIN & CNC PRESISI
    if (msg.contains('bubut') ||
        msg.contains('cnc') ||
        msg.contains('milling') ||
        msg.contains('lathe') ||
        msg.contains('operator mesin')) {
      return 'Program **Operator Mesin Bubut & CNC Presisi** melatih keahlian permesinan komponen logam industri:\n\n'
          '• **Materi**: Membaca gambar teknik, kalibrasi jangka sorong/mikrometer, pembubutan konvensional, hingga pemrograman CNC.\n'
          '• **Peluang Kerja**: Pabrik otomotif, vendor tier-1, dan industri permesinan presisi di Karawang, Cikarang, dan Cirebon.\n'
          '• **Sertifikat**: BNSP Operator Mesin Bubut / CNC Logam.\n\n'
          'Mau tahu rekomendasi LPK teknik mesin terdekat di Indramayu?';
    }

    // 5. OTOMOTIF & SERVIS MOTOR/MOBIL
    if (msg.contains('otomotif') ||
        msg.contains('motor') ||
        msg.contains('mobil') ||
        msg.contains('injeksi') ||
        msg.contains('mekanik') ||
        msg.contains('bengkel')) {
      return 'Pelatihan **Teknisi Otomotif & Injeksi** sangat prospektif untuk bekerja di bengkel resmi maupun membuka usaha mandiri:\n\n'
          '• **Fokus Praktek**: Troubleshooting sistem injeksi PGM-FI/FI, kelistrikan bodi, servis rem & suspensi, serta tune-up mesin modern.\n'
          '• **Keuntungan**: LPK menyediakan unit motor praktek langsung dan bimbingan wirausaha bengkel.\n'
          '• **Sertifikasi**: BNSP Teknisi Perawatan Berkala Sepeda Motor.\n\n'
          'Kamu ingin belajar untuk tujuan melamar ke bengkel resmi atau berniat buka usaha bengkel sendiri?';
    }

    // 6. BAHASA JEPANG & MAGANG SSW (TOKUTEI GINOU)
    if (msg.contains('jepang') ||
        msg.contains('tokutei') ||
        msg.contains('ssw') ||
        msg.contains('ginou') ||
        msg.contains('n4') ||
        msg.contains('n5') ||
        msg.contains('jft') ||
        msg.contains('magang jepang')) {
      return 'Program **Bahasa Jepang Vokasi & Tokutei Ginou (SSW)** di Skilloka membimbingmu hingga siap terbang ke Jepang:\n\n'
          '• **Kurikulum**: Pembelajaran bahasa intensif target lulus ujian JFT-Basic A2 atau JLPT N4.\n'
          '• **Etika Kerja**: Pelatihan budaya kerja Jepang (Hou-Ren-So, 5S) dan wawancara perusahaan Jepang.\n'
          '• **Bidang Kerja**: Pengolahan makanan, manufaktur, pertanian, dan caregiver (gaji berkisar Rp 18jt - 25jt/bulan).\n\n'
          'Sudah pernah belajar huruf Hiragana/Katakana sebelumnya, atau baru mau mulai dari nol?';
    }

    // 7. KOMPUTER, CODING & IT DIGITAL
    if (msg.contains('coding') ||
        msg.contains('web') ||
        msg.contains('programmer') ||
        msg.contains('it') ||
        msg.contains('programming') ||
        msg.contains('komputer') ||
        msg.contains('software')) {
      return 'Untuk bidang **Teknologi & Digital**, kursus unggulan di Skilloka adalah **Web Programming & Fullstack Modern**:\n\n'
          '• **Materi Praktik**: HTML, CSS, JavaScript, database, dan framework backend modern untuk membangun aplikasi nyata.\n'
          '• **Portofolio**: Setiap lulusan wajib membuat proyek web live sebagai portofolio lamaran kerja.\n'
          '• **Prospek**: Junior Web Developer, QA Tester, atau IT Support kantor dengan peluang kerja onsite maupun remote.\n\n'
          'Apakah kamu sudah punya laptop/PC sendiri untuk latihan di rumah?';
    }

    // 8. DESAIN GRAFIS & BRANDING
    if (msg.contains('desain') ||
        msg.contains('grafis') ||
        msg.contains('photoshop') ||
        msg.contains('illustrator') ||
        msg.contains('canva') ||
        msg.contains('branding')) {
      return 'Kelas **Desain Grafis Komersial & Branding UMKM** mengajarkan keahlian visual yang langsung dicari pasar:\n\n'
          '• **Tools**: Menguasai Adobe Photoshop, Illustrator, dan Canva profesional.\n'
          '• **Output Karya**: Pembuatan logo, kemasan produk (packaging), feed sosial media promosi, dan materi promosi cetak/digital.\n'
          '• **Karir**: Graphic Designer in-house, agency kreatif, social media specialist, atau freelance.\n\n'
          'Tertarik membuat desain promosi digital atau lebih suka pembuatan logo & ilustrasi?';
    }

    // 9. BAHASA INGGRIS & KAPAL PESIAR / HOSPITALITY
    if (msg.contains('kapal pesiar') ||
        msg.contains('bahasa inggris') ||
        msg.contains('inggris') ||
        msg.contains('cruise') ||
        msg.contains('speaking')) {
      return 'Program **Bahasa Inggris Kapal Pesiar & Hospitality** di LPK Skilloka difokuskan pada percakapan kerja langsung:\n\n'
          '• **Materi**: Interview simulation, customer service speaking, F&B terminology, dan standar keselamatan maritim.\n'
          '• **Prospek**: Penempatan hotel berbintang luar negeri dan kapal pesiar internasional (pendapatan Dollar/Euro).\n'
          '• **Mitra LPK**: Global English House Indramayu menyediakan simulasi interview langsung dengan alumni kapal pesiar.\n\n'
          'Ada target waktu kapan kamu ingin mulai berangkat magang atau bekerja?';
    }

    // 10. PERHOTELAN, BARISTA & TATA BOGA
    if (msg.contains('hotel') ||
        msg.contains('perhotelan') ||
        msg.contains('barista') ||
        msg.contains('kopi') ||
        msg.contains('tata boga') ||
        msg.contains('masak') ||
        msg.contains('culinary') ||
        msg.contains('tata busana') ||
        msg.contains('jahit')) {
      return 'Bidang **Perhotelan, Barista & Tata Boga** sangat cocok untuk karir industri hospitality maupun wirausaha:\n\n'
          '• **Barista & F&B**: Pengenalan biji kopi, kalibrasi espresso machine, latte art, dan standar layanan kafe.\n'
          '• **Tata Boga**: Kuliner komersial, baking & pastry, dan higienitas dapur industri.\n'
          '• **Sertifikasi**: BNSP Bidang Hospitality & Jasa Makanan/Minuman.\n\n'
          'Kamu lebih tertarik ke bidang meracik kopi (barista), kuliner dapur, atau perhotelan kamar?';
    }

    // 11. BIAYA, HARGA, CICILAN & PEMBAYARAN
    if (msg.contains('biaya') ||
        msg.contains('harga') ||
        msg.contains('bayar') ||
        msg.contains('tarif') ||
        msg.contains('uang') ||
        msg.contains('gratis') ||
        msg.contains('cicil') ||
        msg.contains('diskon') ||
        msg.contains('beasiswa') ||
        msg.contains('subsidi') ||
        msg.contains('qris') ||
        msg.contains('transfer')) {
      if (inWeldingContext) {
        return 'Untuk kursus **Teknik Las & Manufaktur**, biayanya sekitar **Rp 1.500.000 - Rp 1.800.000** (durasi 60-80 jam latihan intensif), sudah termasuk bahan praktek besi/las, APD bengkel, dan modul.\n\n'
            'Pembayaran bisa dilakukan mudah via Transfer Bank atau QRIS di aplikasi Skilloka. Mau dibantu cek rincian jadwalnya?';
      }
      if (inJapanContext) {
        return 'Untuk kursus **Bahasa Jepang Vokasi & SSW**, biayanya sekitar **Rp 2.500.000** untuk pelatihan intensif 120 jam hingga siap ujian JFT/N4 dan wawancara SO.\n\n'
            'Tersedia opsi cicilan bertahap sesuai batch di LPK mitra. Mau info batch pembukaan kelas terdekat?';
      }
      if (inComputerContext) {
        return 'Untuk kursus **Komputer & Digital**:\n'
            '• Desain Grafis: mulai **Rp 850.000** (40 jam)\n'
            '• Web Programming Fullstack: sekitar **Rp 1.500.000** (50 jam praktek coding)\n\n'
            'Bisa dibayar langsung lewat QRIS atau Transfer Bank. Tertarik ambil kelas desain atau coding?';
      }
      if (inAutomotiveContext) {
        return 'Untuk kursus **Teknik Otomotif & Injeksi Sepeda Motor**, biayanya sekitar **Rp 1.250.000 - Rp 1.600.000** (durasi 50-60 jam praktik langsung di bengkel unit motor modern).\n\n'
            'Sudah termasuk modul dan bimbingan sertifikasi BNSP. Mau dibantu cek jadwal kelasnya?';
      }

      return 'Biaya pelatihan di LPK Skilloka sangat terjangkau karena bersubsidi kemitraan:\n'
          '• **Kelas Digital & Desain**: Rp 850.000 - Rp 1.500.000\n'
          '• **Kelas Teknik Las & Otomotif**: Rp 1.250.000 - Rp 1.800.000 (termasuk bahan praktek bengkel)\n'
          '• **Kelas Bahasa Asing (Jepang/Inggris)**: Rp 2.000.000 - Rp 2.500.000 (durasi panjang 90-120 jam)\n\n'
          'Semua pembayaran resmi didukung QRIS & Transfer Bank di aplikasi. Ada bidang kursus tertentu yang ingin kamu tanyakan biayanya?';
    }

    // 12. SYARAT DAFTAR, IJAZAH & BATASAN USIA
    if (msg.contains('syarat') ||
        msg.contains('persyaratan') ||
        msg.contains('ijazah') ||
        msg.contains('lulusan') ||
        msg.contains('usia') ||
        msg.contains('umur') ||
        msg.contains('smp') ||
        msg.contains('sma') ||
        msg.contains('smk') ||
        msg.contains('paket c') ||
        msg.contains('bisa daftar') ||
        msg.contains('sarjana') ||
        msg.contains('kuliah')) {
      return 'Kabar baik! Pelatihan vokasi di LPK Skilloka **terbuka untuk semua kalangan**:\n\n'
          '1. **Pendidikan**: Lulusan SMP, SMA, SMK, Paket C, hingga Diploma/Sarjana/Umum bisa mendaftar. Tidak ada syarat jurusan asal!\n'
          '2. **Usia**: Umumnya 17-35 tahun untuk program persiapan kerja pabrik/industri (untuk keterampilan wirausaha tidak ada batasan usia).\n'
          '3. **Dokumen**: Cukup KTP / Kartu Keluarga dan mengisi biodata profil di aplikasi.\n\n'
          'Kamu sendiri lulusan pendidikan apa dan rencana ingin mengasah keahlian di bidang apa?';
    }

    // 13. PENYALURAN KERJA & JAMINAN KERJA
    if (msg.contains('salur') ||
        msg.contains('penyaluran') ||
        msg.contains('jaminan kerja') ||
        msg.contains('dijamin kerja') ||
        msg.contains('pabrik') ||
        msg.contains('loker') ||
        msg.contains('lowongan') ||
        msg.contains('penempatan') ||
        msg.contains('disnaker')) {
      return 'Semua LPK di Skilloka bermitra resmi dengan **Dinas Tenaga Kerja (Disnaker)** dan asosiasi industri:\n\n'
          '• **Koneksi Industri**: LPK memiliki jejaring rekrutmen dengan puluhan pabrik di kawasan industri Cikarang, Karawang, Cirebon, hingga mitra luar negeri.\n'
          '• **Pendampingan**: Siswa dibimbing pembuatan CV standar HRD, teknik wawancara, dan tes fisik/kejuruan.\n'
          '• **Prioritas**: Lulusan yang memegang sertifikat kompetensi BNSP resmi akan diprioritaskan dalam database bursa kerja LPK.\n\n'
          'Kamu ingin fokus mencari kerja di wilayah Jawa Barat atau tertarik penempatan luar negeri?';
    }

    // 14. SERTIFIKASI BNSP & KELEGALAN
    if (msg.contains('bnsp') ||
        msg.contains('sertifikat') ||
        msg.contains('sertifikasi') ||
        msg.contains('garuda') ||
        msg.contains('kompetensi') ||
        msg.contains('uji kompetensi') ||
        msg.contains('resmi')) {
      return 'Sertifikat **BNSP (Badan Nasional Sertifikasi Profesi)** adalah sertifikasi profesi resmi negara dengan lambang **Garuda Emas**:\n\n'
          '• **Diakui Luas**: Sangat dihargai oleh tim HRD pabrik dan perusahaan karena membuktikan kamu kompeten secara standar kerja nasional (SKKNI).\n'
          '• **Alur di Skilloka**: Setelah menyelesaikan modul praktik di LPK, kamu akan dibimbing langsung oleh asesor untuk menghadapi uji kompetensi hingga lulus.\n\n'
          'Sertifikasi di bidang apa yang ingin kamu capai?';
    }

    // 15. ALUR PENDAFTARAN & CARA BOOKING DI APLIKASI
    if (msg.contains('cara daftar') ||
        msg.contains('gimana daftar') ||
        msg.contains('bagaimana daftar') ||
        msg.contains('cara booking') ||
        msg.contains('alur daftar') ||
        msg.contains('langkah daftar') ||
        msg.contains('buat akun')) {
      return 'Alur mendaftar kursus di Skilloka sangat cepat dan praktis:\n\n'
          '1. Masuk ke tab **Beranda** atau **Cari**, lalu pilih kursus yang kamu sukai.\n'
          '2. Klik tombol **Daftar Sekarang** di halaman detail kursus.\n'
          '3. Pilih jadwal kelas / batch yang cocok dan lengkapi data diri.\n'
          '4. Lakukan pembayaran instan lewat **QRIS** atau **Transfer Bank**.\n'
          '5. Bukti tiket dan jadwal masuk LPK langsung otomatis aktif di tab **Pesanan**!\n\n'
          'Sudah menemukan kursus yang menarik di katalogmu?';
    }

    // 16. LOKASI & MITRA LPK DI INDRAMAYU
    if (msg.contains('lokasi') ||
        msg.contains('alamat') ||
        msg.contains('dimana') ||
        msg.contains('indramayu') ||
        msg.contains('cirebon') ||
        msg.contains('techno skill') ||
        msg.contains('merah putih') ||
        msg.contains('global english')) {
      return 'Saat ini Skilloka bermitra dengan LPK unggulan di wilayah Indramayu & sekitarnya:\n\n'
          '1. **LPK Merah Putih Indramayu**: Jl. Jendral Sudirman No. 45, Indramayu (Spesialis Teknik Mesin, Bubut, Las & Otomotif).\n'
          '2. **Techno Skill Center Indramayu**: Jl. DI Panjaitan No. 12, Indramayu (Spesialis IT, Web Programming & Desain Grafis).\n'
          '3. **Global English House Indramayu**: Jl. Veteran No. 8, Indramayu (Spesialis Bahasa Jepang SSW & Bahasa Inggris Perhotelan).\n\n'
          'Semua lokasi dilengkapi bengkel/lab komputer berstandar industri. Mau info kontak LPK tertentu?';
    }

    // 17. WAKTU, JADWAL & FORMAT (ONLINE VS OFFLINE)
    if (msg.contains('jadwal') ||
        msg.contains('waktu') ||
        msg.contains('jam') ||
        msg.contains('kapan mulai') ||
        msg.contains('online') ||
        msg.contains('offline') ||
        msg.contains('tatap muka') ||
        msg.contains('weekend') ||
        msg.contains('berapa lama') ||
        msg.contains('durasi')) {
      return 'Sistem pembelajaran di Skilloka dirancang fleksibel untuk peserta:\n\n'
          '• **Format Belajar**: Sebagian besar adalah **praktik langsung di bengkel/lab LPK (offline)** agar keterampilan fisik terasah nyata, didukung materi modul digital di aplikasi.\n'
          '• **Pilihan Kelas**: Tersedia kelas reguler (Senin - Jumat) dan kelas akhir pekan (Sabtu - Minggu) untuk yang sedang bekerja.\n'
          '• **Durasi**: Bervariasi antara 40 jam (1 bulan) hingga 120 jam (3 bulan intensif).\n\n'
          'Kamu lebih leluasa ikut kelas hari kerja atau kelas akhir pekan?';
    }

    // 18. REKOMENDASI UMUM / PEMILIHAN BIDANG
    if (msg.contains('rekomendasi') ||
        msg.contains('saran') ||
        msg.contains('pilih mana') ||
        msg.contains('cocok') ||
        msg.contains('jurusan apa') ||
        msg.contains('kursus apa')) {
      return 'Biar pas dengan kepribadian dan tujuanmu, ini 3 rekomendasi utama Loka:\n\n'
          '1. **Suka Kerja Fisik, Alat & Logika Mekik**: Pilih **Teknik Las** atau **Operator Mesin Bubut** (lapangan kerja industri selalu ramai).\n'
          '2. **Suka di Depan Komputer & Kerja Fleksibel**: Pilih **Web Programming** atau **Desain Grafis Komersial** (bisa kerja kantor atau freelance).\n'
          '3. **Ingin Berpenghasilan Tinggi & Pergi ke Luar Negeri**: Pilih **Bahasa Jepang Vokasi (SSW)** atau **Perhotelan Kapal Pesiar**.\n\n'
          'Dari 3 pilihan di atas, mana yang paling bikin kamu penasaran?';
    }

    // 19. TERIMA KASIH & APRESIASI
    if (msg.contains('makasih') ||
        msg.contains('terima kasih') ||
        msg.contains('thanks') ||
        msg.contains('tengkyu') ||
        msg.contains('mantap') ||
        msg.contains('oke') ||
        msg.contains('siap') ||
        msg.contains('paham')) {
      return 'Sama-sama! Senang banget bisa bantu kamu. Jangan ragu buat tanya lagi kalau ada yang bikin bingung.\n\n'
          'Semangat terus mengasah skill ya, masa depan cerah selalu terbuka buat orang yang mau mulai melangkah! 🚀';
    }

    // 20. LANGGANAN, FITUR MATERI, ABSENSI & SERTIFIKAT KHUSUS
    if (msg.contains('langganan') ||
        msg.contains('berlangganan') ||
        msg.contains('subscription') ||
        msg.contains('absensi') ||
        msg.contains('absen') ||
        msg.contains('materi') ||
        msg.contains('modul') ||
        msg.contains('fitur khusus') ||
        msg.contains('buka materi') ||
        msg.contains('premium')) {
      return 'Di Skilloka, akses **Materi Digital** dan **Sistem Absensi** aktif otomatis ketika kamu memilih opsi **Booking + Langganan (Skilloka Premium)** saat mendaftar kursus dan pembayaran telah terkonfirmasi:\n\n'
          '1. **Materi Pembelajaran**: Terbuka langsung di tab Kursus Saya > Materi, mencakup modul PDF, video instruktur, dan panduan praktik kerja bengkel/lab.\n'
          '2. **Sistem Presensi / Absensi**: Setiap sesi tatap muka di LPK dicatat resmi oleh instruktur untuk memantau kehadiran sebagai syarat penerbitan sertifikat BNSP.\n'
          '3. **E-Sertifikat Resmi**: Otomatis terbit di tab Sertifikat setelah kursus selesai dan syarat kehadiran terpenuhi.\n\n'
          'Opsi langganan ini melekat pada pendaftaran kursus di menu Booking. Ada kursus tertentu yang ingin kamu daftarkan atau tanyakan detailnya?';
    }

    // 21. DETEKSI PERTANYAAN DI LUAR BATASAN (OUT-OF-SCOPE GUARDRAIL)
    final bool isOutOfScope = msg.contains('politik') ||
        msg.contains('pemilu') ||
        msg.contains('pilpres') ||
        msg.contains('partai') ||
        msg.contains('dpr') ||
        msg.contains('presiden') ||
        msg.contains('menteri') ||
        msg.contains('artis') ||
        msg.contains('selebriti') ||
        msg.contains('gosip') ||
        msg.contains('pacar') ||
        msg.contains('jodoh') ||
        msg.contains('mantan') ||
        msg.contains('zodiak') ||
        msg.contains('ramalan') ||
        msg.contains('horoskop') ||
        msg.contains('kalkulus') ||
        msg.contains('integral') ||
        msg.contains('fisika murni') ||
        msg.contains('kimia murni') ||
        msg.contains('hack') ||
        msg.contains('bobol') ||
        msg.contains('meretas') ||
        msg.contains('judi') ||
        msg.contains('slot') ||
        msg.contains('pinjol') ||
        msg.contains('game online') ||
        msg.contains('mobile legends') ||
        msg.contains('free fire');

    if (isOutOfScope) {
      return 'Pertanyaan yang menarik! Namun sebagai **Loka**, fokus utama saya adalah mendampingi kamu seputar **pelatihan kerja vokasi, informasi LPK mitra resmi, pendaftaran kursus, dan konsultasi karir industri di Skilloka**.\n\n'
          'Biar obrolan kita tetap relevan dan bermanfaat untuk masa depanmu, yuk kita bahas topik seputar:\n'
          '1. **Rekomendasi Kursus Pelatihan** (Teknik Las, Mesin Bubut, Otomotif, IT/Coding, Desain, Bahasa Jepang SSW, Barista/Kuliner)\n'
          '2. **Info LPK Mitra, Fasilitas Bengkel & Jadwal Belajar**\n'
          '3. **Biaya, Cara Booking & Sertifikasi Resmi BNSP**\n'
          '4. **Persiapan Karir Industri & Magang ke Luar Negeri**\n\n'
          'Ada keahlian kerja atau rencana masa depan yang ingin kamu diskusikan bersama hari ini? 😊';
    }

    // 22. FALLBACK INFORMATIF, RAMAH & MEMASTIKAN CHAT TETAP NYAMBUNG
    return 'Halo! Sebagai **Loka** dari Skilloka, saya siap membantu kamu seputar **pelatihan kerja vokasi, informasi LPK mitra resmi, pendaftaran kursus, dan konsultasi karir di industri**.\n\n'
        'Agar obrolan kita pas dan nyambung dengan kebutuhanmu, boleh tahu apakah kamu ingin tanya seputar:\n'
        '1. **Pilihan Bidang Kursus** (Teknik Las, Otomotif, IT, Desain Grafis, Bahasa Asing, Perhotelan)?\n'
        '2. **Rincian Biaya, Jadwal & Cara Pendaftaran di Aplikasi**?\n'
        '3. **Sertifikasi Resmi BNSP & Penyaluran Kerja / Magang Luar Negeri**?\n\n'
        'Ceritakan saja apa yang sedang kamu butuhkan ya! 😊';
  }
}
