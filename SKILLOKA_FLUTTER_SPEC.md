# SKILLOKA MOBILE (FLUTTER) - INTEGRATION & DESIGN SYSTEM SPEC

Panduan integrasi data, standarisasi UI, dan referensi endpoint API mobile siswa
agar 100% selaras dengan Skilloka Web Platform dan PRD_SKILLOKA_FINAL_V2.md.

PENTING UNTUK AI ASSISTANT: Dokumen ini mencerminkan codebase aktual proyek.
Selalu gunakan class, path, dan konvensi yang sudah ada - jangan membuat ulang yang sudah ada.

---

## 0. SUMBER KEBENARAN & ATURAN AGENT

Urutan prioritas ketika terjadi konflik:
1. PRD_SKILLOKA_FINAL_V2.md - keputusan produk, alur, UI/UX, acceptance criteria
2. Dokumen ini (SKILLOKA_FLUTTER_SPEC.md) - panduan teknis integrasi mobile
3. Kode yang sudah ada di lib/ - implementasi aktual yang harus diikuti

Aturan wajib:
- Gunakan AppColors (BUKAN SkillokaColors) - sudah ada di lib/core/theme/app_colors.dart
- Gunakan AppTheme - sudah ada di lib/core/theme/app_theme.dart
- Gunakan AppConfig.baseUrl - sudah ada di lib/core/config/app_config.dart
- Gunakan ApiService yang sudah ada di lib/core/services/api_service.dart
- Ikuti struktur folder feature-first sesuai PRD Section 14
- State management: flutter_bloc (sudah terpasang)
- DI: get_it + injectable (sudah terpasang)
- Navigation: go_router (sudah terpasang)

---

## 1. ARSITEKTUR KOMUNIKASI DATA

Flutter Mobile <-> Laravel REST API <-> PostgreSQL
     |                    |
     |     Laravel Sanctum Bearer Token
     |     Accept: application/json
     |     Content-Type: application/json
     |     Authorization: Bearer <TOKEN>
     v
AppConfig.baseUrl  (environment-aware, lihat Section 2)

Role Backend: Pusat business logic, auth, validasi, transaksi, notifikasi
Role Mobile: Client UI - mencari kursus, booking, pembayaran, absensi, sertifikat, review, chatbot

---

## 2. KONFIGURASI BASE URL (lib/core/config/app_config.dart)

File sudah ada. JANGAN membuat ulang. Cukup ubah environment dan _deviceIp:

```dart
// Untuk ganti environment, ubah satu baris ini:
static AppEnvironment environment = AppEnvironment.devDevice; // <- ubah sesuai kebutuhan

// Untuk device fisik (HP + Laptop 1 WiFi), ubah IP ini:
static const String _deviceIp = '192.168.0.115'; // <- cek dengan `ipconfig`
```

| Environment      | Nilai enum   | Base URL                              | Kapan dipakai               |
|------------------|--------------|---------------------------------------|-----------------------------|
| Android Emulator | devLocal     | http://10.0.2.2:8000/api              | Android Studio Emulator     |
| Device Fisik     | devDevice    | http://<_deviceIp>:8000/api           | HP & Laptop di WiFi sama    |
| Dev/Production   | dev / prod   | https://skilloka.my.id/api            | Server live                 |
| Staging          | staging      | https://staging.skilloka.my.id/api    | Staging server              |

---

## 3. STANDAR FORMAT RESPONSE JSON BACKEND

Semua endpoint Skilloka membungkus response dengan struktur standar:

```json
// Success
{
  "status": "success",
  "message": "Data berhasil diambil.",
  "data": { }
}

// Success list dengan pagination
{
  "status": "success",
  "data": {
    "items": [],
    "meta": { "current_page": 1, "last_page": 5, "per_page": 15, "total": 72 }
  }
}

// Error validasi
{
  "status": "error",
  "message": "Validasi gagal",
  "errors": { "phone": ["Nomor telepon sudah terdaftar."] }
}

// Unauthorized (401)
{ "status": "error", "message": "Unauthenticated." }
```

Catatan ApiService: _handleResponse() di ApiService sudah menangani 200/201 (success),
401 (redirect ke login + hapus token), dan error lainnya. Gunakan pattern yang sudah ada.

---

## 4. KAMUS LENGKAP ENDPOINT API SKILLOKA

Base path: /api/v1 (sesuai PRD Section 12)
Semua endpoint protected wajib Authorization: Bearer <TOKEN>.

### A. Autentikasi & Akun User

| Method | Endpoint             | Auth | Deskripsi                               |
|--------|----------------------|------|-----------------------------------------|
| POST   | /auth/register       | No   | Registrasi akun baru (name, phone)     |
| POST   | /auth/otp/request    | No   | Request OTP via WhatsApp/Telegram       |
| POST   | /auth/otp/verify     | No   | Verifikasi OTP - response: token        |
| POST   | /auth/login          | No   | Login dengan credential                 |
| POST   | /auth/logout         | Yes  | Logout (revoke token)                   |
| GET    | /auth/me             | Yes  | Data user + active_bookings_count       |
| GET    | /profile             | Yes  | Profil lengkap user                     |
| PUT    | /profile             | Yes  | Update profil (name, email, dll.)       |
| PUT    | /profile/education   | Yes  | Update profil pendidikan (onboarding)   |
| GET    | /avatars             | Yes  | Daftar avatar tersedia                  |
| PUT    | /profile/avatar      | Yes  | Pilih avatar                            |

Body registrasi:
```json
{ "name": "Budi Santoso", "phone": "081234567890" }
```

Body request OTP:
```json
{ "phone": "081234567890", "channel": "whatsapp" }
```

Body verify OTP (field: otp_code bukan otp):
```json
{ "phone": "081234567890", "otp_code": "123456" }
```

Response verify OTP success:
```json
{
  "status": "success",
  "data": {
    "token": "1|sanctum_token_here",
    "user": { "id": 1, "name": "Budi", "phone": "081234..." }
  }
}
```

Body update profil pendidikan (onboarding):
```json
{
  "education_level": "SMA|SMK|PERGURUAN_TINGGI",
  "major": "Teknik Informatika",
  "institution_name": "SMK Negeri 1 Indramayu",
  "graduation_year": "2024",
  "career_goal": "kerja|wirausaha|upgrade-skill",
  "preferred_location": "Indramayu"
}
```

### B. Rekomendasi & Upload

| Method | Endpoint              | Auth | Deskripsi                              |
|--------|-----------------------|------|----------------------------------------|
| GET    | /recommendations      | Yes  | Daftar kursus rekomendasi personal     |
| POST   | /user/profile/photo   | Yes  | Upload foto profil (multipart/photo)   |

### C. Katalog Kursus, Kategori & LPK (Public)

| Method | Endpoint                  | Auth | Deskripsi                             |
|--------|---------------------------|------|---------------------------------------|
| GET    | /courses                  | No   | Daftar kursus (paginated)             |
| GET    | /courses/{id}             | No   | Detail kursus + silabus + jadwal      |
| GET    | /courses/{id}/schedules   | No   | Jadwal tersedia untuk kursus          |
| GET    | /courses/{id}/reviews     | No   | Review/rating kursus                  |
| GET    | /categories               | No   | Daftar kategori kejuruan              |
| GET    | /locations                | No   | Daftar lokasi/kota yang tersedia      |
| GET    | /lpks                     | No   | Daftar LPK (paginated)                |
| GET    | /lpks/{id}                | No   | Detail LPK + kursus miliknya          |

Query params GET /courses:
```
?search=nama_kursus
?category=slug_kategori
?level=Pemula|Menengah|Mahir
?lpk_id=1
?page=1
```

Query params GET /lpks:
```
?search=nama_lpk
?verified=true
?sort_by=courses_count|rating
?page=1
```

Struktur response kursus:
```json
{
  "id": 1,
  "title": "Pelatihan Las SMAW",
  "description": "...",
  "price": 1500000,
  "duration_hours": 40,
  "level": "Pemula",
  "images": ["https://skilloka.my.id/storage/..."],
  "facilities": ["Modul PDF", "Sertifikat"],
  "lpk": {
    "id": 1,
    "name": "LPK Maju Jaya",
    "logo": "https://skilloka.my.id/storage/...",
    "is_verified": true
  },
  "category": { "id": 2, "name": "Las", "slug": "las" },
  "schedules": [
    { "id": 3, "date": "2026-10-15", "time": "08:00", "slots": 10, "status": "available" }
  ]
}
```

### D. Booking & Pembayaran (Protected)

| Method | Endpoint                    | Auth | Deskripsi                              |
|--------|-----------------------------|------|----------------------------------------|
| POST   | /bookings                   | Yes  | Buat booking kursus                    |
| GET    | /bookings                   | Yes  | Riwayat booking user (list)            |
| GET    | /bookings/{id}              | Yes  | Detail booking                         |
| POST   | /bookings/{id}/cancel       | Yes  | Batalkan booking (POST sesuai PRD)     |
| GET    | /bookings/{id}/payment      | Yes  | Info pembayaran booking                |
| POST   | /bookings/{id}/payment      | Yes  | Inisiasi pembayaran (Midtrans)         |
| GET    | /subscription/plans         | No   | Daftar paket langganan                 |
| GET    | /subscriptions              | Yes  | Langganan aktif user                   |
| GET    | /subscriptions/{id}         | Yes  | Detail langganan                       |

Body POST /bookings:
```json
{ "course_id": 1, "schedule_id": 3 }
```

Body POST /bookings/{id}/payment:
```json
{ "payment_method": "midtrans" }
```

Response payment Midtrans Snap:
```json
{
  "status": "success",
  "data": {
    "snap_token": "token-untuk-midtrans-sdk",
    "redirect_url": "https://app.sandbox.midtrans.com/snap/..."
  }
}
```

CATATAN Midtrans: snap_token diumpankan ke Midtrans Mobile SDK Flutter
untuk memunculkan pop-up checkout pembayaran.

### E. Pembelajaran / My Courses (Protected)

| Method | Endpoint                            | Auth | Deskripsi                         |
|--------|-------------------------------------|------|-----------------------------------|
| GET    | /my-courses                         | Yes  | Kursus saya (datang/jalan/selesai)|
| GET    | /my-courses/{courseId}/content      | Yes  | Materi pembelajaran kursus        |
| GET    | /my-courses/{courseId}/attendance   | Yes  | Data absensi kursus               |
| GET    | /my-courses/{courseId}/certificate  | Yes  | Sertifikat kursus (jika ada)      |

### F. Review, Chatbot, Favorit, Sertifikat

| Method | Endpoint                 | Auth | Deskripsi                               |
|--------|--------------------------|------|-----------------------------------------|
| POST   | /courses/{id}/reviews    | Yes  | Tulis review kursus                     |
| PUT    | /reviews/{id}            | Yes  | Edit review                             |
| DELETE | /reviews/{id}            | Yes  | Hapus review                            |
| POST   | /chatbot/messages        | Yes  | Kirim pesan ke chatbot                  |
| GET    | /chatbot/history         | Yes  | Riwayat percakapan chatbot              |
| GET    | /favorites               | Yes  | Daftar kursus favorit                   |
| POST   | /favorites/{course_id}   | Yes  | Toggle simpan/hapus favorit             |
| GET    | /user/certificates       | Yes  | Semua sertifikat user                   |

Body POST /courses/{id}/reviews:
```json
{ "rating": 4, "comment": "Pelatihan sangat bermanfaat!" }
```

Body POST /chatbot/messages:
```json
{ "message": "Kursus las apa yang cocok untuk pemula?" }
```

---

## 5. DESIGN SYSTEM AKTUAL - PAKAI YANG SUDAH ADA

### 5.1 Color Tokens (lib/core/theme/app_colors.dart)

JANGAN membuat SkillokaColors baru. Gunakan AppColors yang sudah ada.

```dart
import 'package:skilloka/core/theme/app_colors.dart';

// Primary (Teal/Emerald - brand utama)
AppColors.primary          // Color(0xFF0D9488) - teal-600
AppColors.primaryLight     // Color(0xFF14B8A6) - teal-400
AppColors.primaryDark      // Color(0xFF0F766E) - teal-700
AppColors.primaryContainer // Color(0xFFCCFBF1)

// Secondary (Warm Orange - aksen aksi)
AppColors.secondary        // Color(0xFFF97316)
AppColors.secondaryLight   // Color(0xFFFB923C)

// Semantic Status
AppColors.success           // Color(0xFF22C55E)
AppColors.successContainer  // Color(0xFFDCFCE7)
AppColors.warning           // Color(0xFFF59E0B)
AppColors.warningContainer  // Color(0xFFFEF3C7)
AppColors.error             // Color(0xFFEF4444)
AppColors.danger            // alias untuk error
AppColors.errorContainer    // Color(0xFFFEE2E2)
AppColors.info              // Color(0xFF3B82F6)
AppColors.infoContainer     // Color(0xFFDBEAFE)

// Surface & Background
AppColors.background        // Color(0xFFFAFAFA)
AppColors.surface           // Color(0xFFFFFFFF)
AppColors.surfaceVariant    // Color(0xFFF5F5F5)
AppColors.outline           // Color(0xFFE5E5E5)

// Text - pakai adaptive methods di widget (dark mode support)
AppColors.textPrimary       // Color(0xFF171717) - light mode default
AppColors.textSecondary     // Color(0xFF525252)
AppColors.textTertiary      // Color(0xFF737373)
AppColors.textDisabled      // Color(0xFFA3A3A3)
AppColors.textPrimaryFor(context)    // adaptive untuk dark mode
AppColors.textSecondaryFor(context) // adaptive untuk dark mode

// Gradients
AppColors.primaryGradient   // teal gradient (= brandGradient dari dokumen lama)
AppColors.heroGradient      // teal-dark gradient
```

PEMETAAN dari nama dokumen lama ke nama aktual:

| Dokumen Lama (SkillokaColors)  | AppColors Aktual          |
|--------------------------------|---------------------------|
| SkillokaColors.primary         | AppColors.primary         |
| SkillokaColors.brand500        | AppColors.primaryLight    |
| SkillokaColors.brandGradient   | AppColors.primaryGradient |
| SkillokaColors.heroGradient    | AppColors.heroGradient    |
| SkillokaColors.success         | AppColors.success         |
| SkillokaColors.successBg       | AppColors.successContainer|
| SkillokaColors.warning         | AppColors.warning         |
| SkillokaColors.warningBg       | AppColors.warningContainer|
| SkillokaColors.danger          | AppColors.error           |
| SkillokaColors.dangerBg        | AppColors.errorContainer  |
| SkillokaColors.indigoAccent    | AppColors.info            |
| SkillokaColors.indigoBg        | AppColors.infoContainer   |
| SkillokaColors.background      | AppColors.background      |
| SkillokaColors.surface         | AppColors.surface         |
| SkillokaColors.border          | AppColors.outline         |
| SkillokaColors.textPrimary     | AppColors.textPrimary     |
| SkillokaColors.textMuted       | AppColors.textTertiary    |
| SkillokaColors.textDisabled    | AppColors.textDisabled    |

### 5.2 Typography (lib/core/theme/app_typography.dart)

```dart
import 'package:skilloka/core/theme/app_typography.dart';

// Heading
AppTypography.headlineLarge   // 32px, w600
AppTypography.headlineMedium  // 28px, w600
AppTypography.headlineSmall   // 24px, w600

// Title
AppTypography.titleLarge      // 22px, w600
AppTypography.titleMedium     // 16px, w600
AppTypography.titleSmall      // 14px, w600

// Body
AppTypography.bodyLarge       // 16px, w400
AppTypography.bodyMedium      // 14px, w400
AppTypography.bodySmall       // 12px, w400

// Label
AppTypography.labelLarge      // 14px, w500
AppTypography.labelMedium     // 12px, w500
AppTypography.labelSmall      // 11px, w500

// Custom Skilloka
AppTypography.priceTag        // 18px, w700 - untuk harga kursus
AppTypography.badge           // 10px, w600 - untuk label kategori
AppTypography.greeting        // 20px, w600 - untuk "Halo, [Nama]"
```

### 5.3 Theme Application (lib/core/theme/app_theme.dart)

```dart
// Di main.dart (sudah ada):
MaterialApp.router(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
)
```

### 5.4 Category Colors (sudah ada di AppColors)

```dart
AppColors.categoryLas        // Color(0xFFF97316) - Orange - Las
AppColors.categoryIT         // Color(0xFF3B82F6) - Blue - IT
AppColors.categoryOtomotif   // Color(0xFFEF4444) - Red - Otomotif
AppColors.categoryTataBusana // Color(0xFF8B5CF6) - Purple - Tata Busana
AppColors.categoryTataBoga   // Color(0xFFEC4899) - Pink - Tata Boga
AppColors.categoryBahasa     // Color(0xFF06B6D4) - Cyan - Bahasa
```

---

## 6. STRUKTUR FOLDER AKTUAL & TARGET

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          [SUDAH ADA] Environment config
│   ├── constants/
│   ├── error/
│   ├── network/                     Dio/Http client
│   ├── security/                    Jailbreak detection, token encryption
│   ├── services/
│   │   └── api_service.dart         [SUDAH ADA] HTTP service, 612 baris
│   ├── theme/
│   │   ├── app_colors.dart          [SUDAH ADA] Color tokens
│   │   ├── app_theme.dart           [SUDAH ADA] Material 3 theme
│   │   ├── app_typography.dart      [SUDAH ADA] Text styles
│   │   ├── app_shapes.dart          [SUDAH ADA] Border radius tokens
│   │   └── theme_cubit.dart         [SUDAH ADA] Dark/light toggle
│   ├── utils/                       Formatters, helpers
│   └── widgets/
│       ├── atoms/                   Button, Badge, Input dasar
│       ├── molecules/               CourseCard, LPKCard, BookingCard
│       ├── organisms/               Section header, list sections
│       └── skeleton/                Shimmer loading
├── features/
│   ├── auth/                        [SUDAH ADA] Login, register, OTP
│   ├── home/                        [SUDAH ADA] Home screen + recommendations
│   ├── course/                      [SUDAH ADA] Katalog + detail kursus
│   ├── booking/                     [SUDAH ADA] Flow booking
│   ├── profile/                     [SUDAH ADA] Profil + edit
│   ├── splash/                      [SUDAH ADA] Splash screen
│   ├── onboarding/                  [BELUM ADA] Profil pendidikan
│   ├── search/                      [BELUM ADA] Search + filter
│   ├── learning/                    [BELUM ADA] My-courses, materi, absensi
│   ├── subscription/                [BELUM ADA] Paket langganan
│   ├── review/                      [BELUM ADA] Tulis/lihat review
│   └── chatbot/                     [BELUM ADA] Chatbot asisten
└── main.dart
```

---

## 7. MODEL DATA DART - REFERENSI IMPLEMENTASI

Model yang sudah ada mengikuti pola fromJson. Buat model baru di fitur masing-masing
atau di lib/shared/models/ jika dipakai lintas-fitur.

### UserModel (referensi)
```dart
class UserModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? photoUrl;           // Gunakan ApiService.toFullUrl(json['photo_url'])
  final int activeBookingsCount;
  final bool isEducationComplete;   // true jika json['education'] != null

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    phone: json['phone'],
    email: json['email'],
    address: json['address'],
    photoUrl: ApiService.toFullUrl(json['photo_url']),
    activeBookingsCount: json['active_bookings_count'] ?? 0,
    isEducationComplete: json['education'] != null,
  );
}
```

### CourseModel (referensi)
```dart
class CourseModel {
  final int id;
  final String title;
  final double price;
  final int durationHours;
  final String? description;
  final String level;              // 'Pemula' | 'Menengah' | 'Mahir'
  final String? lpkName;
  final String? lpkLogoUrl;       // Gunakan ApiService.toFullUrl()
  final bool lpkVerified;
  final String? categoryName;
  final String? categorySlug;
  final List<String> imageUrls;   // Sudah full URL dari backend
  final List<String> facilities;
  final List<ScheduleModel> schedules;
  final double? averageRating;
  final int reviewCount;
}
```

### BookingModel (referensi)
```dart
// Status enum sesuai backend Skilloka
enum BookingStatus { pending, confirmed, cancelled, completed }

class BookingModel {
  final String id;             // UUID atau int - cek response backend aktual
  final BookingStatus status;
  final double amount;
  final String? courseTitle;
  final String? lpkName;
  final String? scheduleDate;
  final String? scheduleTime;
  final String? createdAt;
  final String? snapToken;     // untuk pembayaran Midtrans
}
```

### Helper Format Harga IDR
```dart
// Letakkan di lib/core/utils/formatters.dart
String formatRupiah(double amount) {
  return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  )}';
}
// Contoh: formatRupiah(1500000) -> "Rp 1.500.000"
```

---

## 8. WIDGET UI REFERENSI

Cek dulu apakah widget sudah ada di atoms/, molecules/, atau organisms/
sebelum membuat baru. Ikuti pola atomic design yang sudah dipakai.

### Pola StatusBadge (sesuai AppColors aktual)
```dart
Widget _buildStatusBadge(String status) {
  Color bg, textColor, border;
  String label;

  switch (status.toLowerCase()) {
    case 'completed':
    case 'selesai':
      bg = AppColors.successContainer;
      textColor = AppColors.success;
      border = AppColors.success.withOpacity(0.3);
      label = 'Selesai';
      break;
    case 'cancelled':
    case 'dibatalkan':
      bg = AppColors.errorContainer;
      textColor = AppColors.error;
      border = AppColors.error.withOpacity(0.3);
      label = 'Dibatalkan';
      break;
    case 'confirmed':
      bg = AppColors.infoContainer;
      textColor = AppColors.info;
      border = AppColors.info.withOpacity(0.3);
      label = 'Dikonfirmasi';
      break;
    default: // 'pending'
      bg = AppColors.warningContainer;
      textColor = AppColors.warning;
      border = AppColors.warning.withOpacity(0.3);
      label = 'Menunggu';
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border),
    ),
    child: Text(label, style: AppTypography.badge.copyWith(color: textColor)),
  );
}
```

### Pola Gradient Button (sesuai AppColors aktual)
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.35),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
          ],
        ),
      ),
    ),
  ),
)
```

---

## 9. CARA MEMAKAI ApiService (Sudah Ada, 612 Baris)

```dart
import 'package:skilloka/core/services/api_service.dart';

final api = ApiService(); // Inject via GetIt

// GET dengan token otomatis
final result = await api.getCourses(search: 'las', category: 'otomotif');
if (result['success']) {
  final courses = result['data']; // data sudah di-extract dari response JSON
}

// POST booking
final result = await api.createBooking(courseId: '1', scheduleId: '3');

// Upload foto (Multipart)
await api.uploadProfilePhoto(imageFile);

// Konversi URL relatif -> absolut
final fullUrl = ApiService.toFullUrl(json['photo_url']);
```

Method yang tersedia di ApiService (lib/core/services/api_service.dart):
```
Auth    : register, requestOtp, verifyOtp, getProfile, updateProfile, uploadProfilePhoto
Kursus  : getCourses, getCourseDetail, getCourseSchedules, getCourseReviews
LPK     : getLpks, getLpkDetail
Booking : getBookings, createBooking, cancelBooking, getBookingPayment, createBookingPayment
Learning: getMyCourses, getCourseContent, getCourseAttendance, getCourseCertificate
Review  : createReview
Chatbot : sendChatbotMessage, getChatbotHistory
Favorit : getFavorites, toggleFavorite
Lainnya : getCategories, getLocations, getRecommendations,
          updateEducationProfile, getSubscriptionPlans, getMySubscriptions
```

---

## 10. ALUR NAVIGASI MOBILE (PRD Section 8.2 & 11.1)

```
Splash
  |
  v
Cek token di SecureStorage
  |-- Ada token -> GET /auth/me
  |     |-- Sukses -> Cek onboarding pendidikan
  |     |     |-- Sudah lengkap -> Home
  |     |     +-- Belum -> Onboarding Pendidikan
  |     +-- 401 -> hapus token -> Login
  +-- Tidak ada -> Login/Register

Login/Register
  |
  v
OTP Verify -> dapat token -> simpan ke SecureStorage
  |
  v
Cek onboarding pendidikan
  |
  v
Home (Bottom Nav: Home | Search | Kursus Saya | Notifikasi | Profil)
```

GoRouter paths (sesuai app_router.dart):
```dart
AppRouter.splash        // '/splash'
AppRouter.login         // '/login'
AppRouter.home          // '/home'
// Tambahkan route berikut:
AppRouter.onboarding    // '/onboarding'
AppRouter.courseDetail  // '/courses/:id'
AppRouter.booking       // '/booking/:courseId'
AppRouter.myCourses     // '/my-courses'
AppRouter.chatbot       // '/chatbot'
```

---

## 11. ALUR BOOKING (PRD Section 8.7)

```
Detail Kursus -> [Booking Sekarang]
  |
  v
Step 1: Pilih Jadwal (GET /courses/{id}/schedules)
  |
  v
Step 2: Konfirmasi Data (nama, nomor HP)
  |
  v
Step 3: Pilih Layanan (booking biasa vs. booking + langganan)
  |
  v
Step 4: Pembayaran (POST /bookings -> POST /bookings/{id}/payment -> Midtrans SDK)
  |
  v
Step 5: Selesai (animasi konfetti via package:confetti, lihat booking)
```

---

## 12. ONBOARDING PROFIL PENDIDIKAN (PRD Section 8.3)

```
Setelah login pertama / registrasi baru
  |
  v
Cek: apakah user['education'] ada?
  |-- Ya -> skip onboarding, ke Home
  +-- Tidak -> Onboarding Pendidikan
        |
        v
        Pilih jenjang: SMA | SMK | PERGURUAN_TINGGI
        |
        v
        Isi jurusan/program studi
        |
        v
        Tujuan: kerja | wirausaha | upgrade-skill
        |
        v
        Lokasi pilihan (opsional)
        |
        v
        PUT /profile/education
        |
        v
        GET /recommendations (buat rekomendasi awal)
        |
        v
        Home
```

---

## 13. FITUR YANG BELUM DIIMPLEMENTASI

| Fitur         | Feature Folder          | Endpoint Utama                                    | PRD Ref     |
|---------------|-------------------------|---------------------------------------------------|-------------|
| Onboarding    | features/onboarding/    | PUT /profile/education                            | Section 8.3 |
| Search+Filter | features/search/        | GET /courses, GET /lpks                           | Section 8.2 |
| My Courses    | features/learning/      | GET /my-courses, /content, /attendance, /cert     | Section 8.8 |
| Subscription  | features/subscription/  | GET /subscription/plans, /subscriptions           | Section 12  |
| Review        | features/review/        | POST /courses/{id}/reviews                        | Section 12  |
| Chatbot       | features/chatbot/       | POST /chatbot/messages, GET /chatbot/history      | Section 12  |
| Notifikasi    | features/notification/  | Firebase Messaging (sudah di pubspec)             | Section 12  |

---

## 14. DEPENDENSI SUDAH TERPASANG (pubspec.yaml)

| Dependensi                | Versi     | Kegunaan                           |
|---------------------------|-----------|------------------------------------|
| flutter_bloc              | ^9.0.0    | State management (wajib)           |
| get_it + injectable       | ^8.0.2    | Dependency injection               |
| dio                       | ^5.7.0    | HTTP client advanced               |
| http                      | ^1.6.0    | HTTP client (dipakai ApiService)   |
| flutter_secure_storage    | ^9.2.2    | Token storage aman                 |
| go_router                 | ^14.6.2   | Navigation                         |
| shimmer                   | ^3.0.0    | Skeleton loading                   |
| cached_network_image      | ^3.4.1    | Image caching                      |
| google_fonts              | ^6.2.1    | Font Inter/Outfit (opsional)       |
| firebase_messaging        | ^15.1.6   | Push notification                  |
| lottie                    | ^3.2.0    | Animasi Lottie                     |
| confetti                  | ^0.7.0    | Animasi konfetti (setelah booking) |
| image_picker              | ^1.0.7    | Upload foto profil                 |
| qr_flutter                | ^4.1.0    | QR Code (sertifikat, presensi)     |
| url_launcher              | ^6.3.1    | Buka link eksternal                |
| intl                      | any       | Format tanggal/angka               |

---

## 15. PANDUAN PROMPT AI UNTUK FITUR BARU

Ketika meminta AI assistant membuat halaman atau fitur baru, gunakan prompt ini:

"Tolong buatkan halaman [Nama Halaman] untuk proyek Flutter Skilloka.

Ikuti panduan di SKILLOKA_FLUTTER_SPEC.md:
- Gunakan AppColors (BUKAN SkillokaColors)
- Gunakan AppTypography untuk semua text style
- Gunakan ApiService yang sudah ada di lib/core/services/api_service.dart
- Ikuti struktur feature-first di lib/features/[nama_fitur]/
- Pakai flutter_bloc untuk state management
- Endpoint: [sebutkan endpoint dari Section 4 dokumen ini]
- Referensi PRD: Section [nomor] di PRD_SKILLOKA_FINAL_V2.md"

---

Dokumen ini dibuat berdasarkan audit codebase aktual pada 2026-09-29.
Sinkronkan dokumen ini setiap ada perubahan besar pada struktur proyek atau endpoint.
