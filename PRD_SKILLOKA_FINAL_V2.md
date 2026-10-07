# PRODUCT REQUIREMENTS DOCUMENT (PRD)

# SKILLOKA --- Platform Pencarian, Booking, Pelatihan, dan Manajemen LPK

**Status:** Final development baseline v2.0\
**Basis:** Proposal terbaru + SRS + SDD + revisi Use Case + Class
Diagram + Flowchart + ERD yang dibahas pada proyek\
**Platform:** Laravel/PHP Backend & REST API + Laravel Web UI + Flutter
Mobile + MySQL\
**Deployment target:** Docker + GitHub Actions + Linux server\
**Security baseline:** OWASP Top 10:2025 dan praktik secure development\
**Wilayah awal:** Kabupaten Indramayu

------------------------------------------------------------------------

## 0. STATUS DOKUMEN DAN ATURAN PENTING

Dokumen ini menjadi acuan implementasi terbaru Skilloka. Agent
AI/developer harus membaca PRD ini sebelum membuat, mengubah, atau
menghapus kode.

Urutan sumber kebenaran ketika terjadi perbedaan:

1.  PRD terbaru ini untuk keputusan produk, alur, UI/UX, arsitektur,
    kualitas kode, dan acceptance criteria.
2.  Proposal terbaru untuk ruang lingkup fitur dan terminologi proyek.
3.  SRS/SDD lama sebagai referensi kebutuhan dan rancangan yang tetap
    relevan.
4.  Use Case, Class Diagram, Flowchart/BPMN, dan ERD terbaru sebagai
    artefak desain yang harus disinkronkan.
5.  Kode yang sudah ada bukan sumber kebenaran apabila bertentangan
    dengan rancangan terbaru.

**Aturan:** Jangan menambah fitur besar di luar PRD hanya karena agent
AI menganggapnya menarik. Jika kebutuhan belum didefinisikan, tandai
sebagai `OPEN DECISION` dan jangan mengarang business rule.

------------------------------------------------------------------------

# 1. RINGKASAN PRODUK

Skilloka adalah platform digital yang mempertemukan pengguna dengan
Lembaga Pelatihan Kerja (LPK). User dapat menemukan LPK/kursus, melihat
informasi, memilih jadwal, melakukan booking dan pembayaran, memperoleh
akses pembelajaran, mengikuti absensi, menerima sertifikat, memberikan
review, dan menggunakan bantuan chatbot.

Admin LPK mengelola operasional LPK di dalam platform, sedangkan Super
Admin mengelola dan memverifikasi data LPK serta mengawasi data
platform.

Skilloka terdiri dari dua pengalaman utama:

-   **Public Web:** halaman informasi/marketing yang dapat dijelajahi
    tanpa login, terutama untuk memperkenalkan Skilloka dan mengajak LPK
    bergabung.
-   **Authenticated Application:** Flutter Mobile untuk User dan Laravel
    Web Dashboard untuk Admin LPK/Super Admin.

Laravel menjadi pusat business logic, REST API,
authentication/authorization, validasi, transaksi, dan akses database.
Flutter menjadi client mobile yang mengambil data melalui API. Laravel
Web menangani public landing page dan dashboard operasional berbasis
role agar tidak perlu membuat backend kedua.

------------------------------------------------------------------------

# 2. PRINSIP PRODUK FINAL

## 2.1 Booking adalah transaksi inti

Booking merupakan proses bisnis utama untuk mengikuti kursus.

## 2.2 Subscription bukan transaksi yang berdiri sendiri

Subscription/berlangganan adalah opsi layanan yang melekat pada proses
booking dan pembayaran. Entity/database `langganan` tetap berdiri
sendiri karena sistem perlu menyimpan periode aktif, status, paket, dan
hak akses.

``` text
Pilih Kursus
    ↓
Booking
    ↓
Pilih layanan
 ┌───────────────┬────────────────────┐
 │ Booking biasa │ Booking + Langganan│
 └───────────────┴────────────────────┘
              ↓
          Pembayaran
              ↓
       Booking terkonfirmasi
              ↓
   Jika berlangganan → aktifkan akses
              ↓
     Materi + Absensi + Sertifikat
```

## 2.3 User tidak diarahkan berdasarkan pendidikan secara kaku

Data pendidikan digunakan sebagai **personalization signal** untuk
menyusun rekomendasi kursus/LPK dan konten awal. User tetap dapat
mencari semua kursus yang tersedia.

## 2.4 Dashboard bukan kumpulan chart

Dashboard harus membantu pekerjaan dan pengambilan tindakan. Chart hanya
digunakan ketika menjawab pertanyaan operasional yang jelas.

## 2.5 UI harus terasa dirancang manusia

Hindari pola dashboard/template AI yang generik: terlalu banyak card,
gradient berlebihan, chart tanpa konteks, icon acak, typography tidak
konsisten, dan halaman yang penuh tetapi tidak memiliki prioritas
visual.

------------------------------------------------------------------------

# 3. TUJUAN PRODUK

1.  Mempermudah pencarian LPK dan kursus.
2.  Memusatkan informasi kursus, jadwal, biaya, dan status LPK.
3.  Mempermudah booking dan pembayaran.
4.  Memberikan pengalaman pembelajaran setelah booking valid.
5.  Menghubungkan materi, absensi, dan sertifikat dengan peserta/kursus.
6.  Membantu LPK mengelola operasional tanpa dashboard yang rumit.
7.  Membantu Super Admin memverifikasi dan mengawasi LPK.
8.  Memberikan rekomendasi yang lebih relevan berdasarkan profil
    pendidikan User.
9.  Menjaga codebase tetap bersih, mudah diuji, aman, dan mudah
    dideploy.
10. Menyiapkan pipeline Docker + GitHub Actions untuk deployment yang
    konsisten.

------------------------------------------------------------------------

# 4. AKTOR

  -----------------------------------------------------------------------
  Aktor                   Platform                Tanggung jawab
  ----------------------- ----------------------- -----------------------
  User                    Flutter Mobile          mencari, booking,
                                                  membayar, belajar,
                                                  absensi, sertifikat,
                                                  review, profil, chatbot

  Admin LPK               Laravel Web             mengelola kursus,
                                                  jadwal, booking, siswa,
                                                  content, pembayaran,
                                                  absensi, sertifikat

  Super Admin             Laravel Web             verifikasi LPK, kelola
                                                  LPK, kategori, user,
                                                  monitoring

  Sistem                  Laravel Backend         autentikasi, otorisasi,
                                                  validasi, rekomendasi,
                                                  transaksi, notifikasi,
                                                  logging
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 5. ARSITEKTUR SISTEM

``` text
                         INTERNET
                            │
             ┌──────────────┴──────────────┐
             │                             │
       Flutter Mobile                 Laravel Web
             │                         Public + Admin
             │                             │
             └──────────────┬──────────────┘
                            │ HTTPS / REST API
                            ↓
                 ┌─────────────────────┐
                 │ Laravel Application │
                 │                     │
                 │ Auth / RBAC         │
                 │ Business Logic      │
                 │ Validation          │
                 │ Recommendation      │
                 │ Payment Integration │
                 │ Content Access      │
                 │ Logging             │
                 └──────────┬──────────┘
                            │
                 ┌──────────┴──────────┐
                 ↓                     ↓
              postgres                  Redis*
                 │
          ┌──────┴─────────┐
          │ Storage/Object │
          │ files/media    │
          └────────────────┘

* Redis digunakan bila dibutuhkan untuk cache, queue, rate limit, dan session.
```

### Prinsip arsitektur

-   Flutter tidak mengakses database secara langsung.
-   Flutter hanya berkomunikasi dengan REST API Laravel.
-   Business rule tidak boleh diletakkan hanya di Flutter.
-   Authorization wajib dilakukan server-side.
-   Laravel Web dan REST API memakai domain/service logic yang sama agar
    tidak ada dua implementasi business rule.
-   Database hanya diakses melalui layer aplikasi Laravel.

Laravel Sanctum mendukung authentication untuk mobile API token dan
SPA/web authentication, sehingga dapat menjadi baseline authentication
layer. citeturn0search4

------------------------------------------------------------------------

# 6. PUBLIC WEB / LANDING PAGE

## 6.1 Tujuan

Halaman pertama bukan langsung login form. Pengunjung harus dapat
memahami:

-   Skilloka itu apa.
-   Masalah apa yang diselesaikan.
-   Apa yang dapat dilakukan User.
-   Apa manfaat Skilloka bagi LPK.
-   Bagaimana cara bergabung.
-   Contoh LPK/kursus yang tersedia.
-   Mengapa LPK perlu mendaftar.

Login dan register tetap tersedia jelas, tetapi tidak mengambil alih
seluruh halaman pertama.

## 6.2 Struktur landing page

``` text
NAVBAR
Logo Skilloka
Beranda | Cari Kursus | Untuk LPK | Tentang
                         [Masuk] [Daftarkan LPK]

HERO
"Temukan Pelatihan yang Sesuai dengan Tujuanmu"
Subheadline singkat
[Mulai Cari Kursus] [Saya Mewakili LPK]

↓

SECTION: SKILLOKA UNTUK APA?
Pencarian → Booking → Pembelajaran → Sertifikat

↓

SECTION: CARA KERJA
1. Cari kursus
2. Pilih jadwal
3. Booking & bayar
4. Ikuti pelatihan
5. Dapatkan sertifikat

↓

SECTION: PILIH BERDASARKAN KEBUTUHAN
Kategori / tujuan / pendidikan

↓

SECTION: LPK TERSEDIA
Card LPK nyata dari API

↓

SECTION: UNTUK LPK
Kelola kursus, jadwal, peserta, materi, absensi, sertifikat
[Daftarkan LPK]

↓

SECTION: FAQ

↓

FOOTER
```

## 6.3 Aturan UI landing page

-   Tidak menggunakan hero yang penuh gradient.
-   Gunakan maksimal 1 visual utama yang kuat.
-   Section memiliki ruang kosong yang cukup.
-   CTA utama jelas tetapi tidak berlebihan.
-   Card LPK menampilkan informasi yang berguna, bukan dekorasi.
-   Animasi hanya untuk transisi/feedback ringan.
-   Tidak menggunakan carousel otomatis yang mengganggu.
-   Mobile-first responsive.

## 6.4 Halaman Login Web

Login Web diperuntukkan Admin LPK dan Super Admin.

``` text
┌────────────────────────────────────────────────────────┐
│ Logo Skilloka                                          │
│                                                        │
│  ┌────────────────────┐   ┌─────────────────────────┐ │
│  │ Visual/Brand Story │   │ Masuk ke Dashboard       │ │
│  │                    │   │ Email                    │ │
│  │ Kelola LPK lebih   │   │ Password                 │ │
│  │ terstruktur.       │   │ [ Masuk ]                │ │
│  │                    │   │                         │ │
│  └────────────────────┘   └─────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

Login tidak boleh membuat pengunjung merasa harus login untuk mengetahui
produk.

## 6.5 Registrasi LPK

CTA `Daftarkan LPK` mengarah ke registrasi bertahap:

``` text
Info Skilloka
 ↓
Daftar sebagai LPK
 ↓
Data Admin
 ↓
Data LPK
 ↓
Alamat + lokasi
 ↓
Data legal/pendukung sesuai kebutuhan proyek
 ↓
Konfirmasi
 ↓
Submit
 ↓
Status: Menunggu Verifikasi
 ↓
Super Admin review
 ↓
Approve / Reject
```

Form harus menggunakan stepper dan progress indicator. Jangan
menampilkan 15--20 field sekaligus.

------------------------------------------------------------------------

# 7. UI/UX DESIGN SYSTEM

## 7.1 Arah visual

Target visual: **modern, clean, human-designed, professional edtech**,
bukan dashboard template AI.

Karakter: - tenang; - informatif; - tidak terlalu ramai; - memiliki
hierarchy yang kuat; - banyak whitespace; - rounded corner moderat; -
typography konsisten; - icon hanya jika membantu pemahaman; - warna
brand digunakan sebagai aksen, bukan seluruh background.

## 7.2 Aturan warna

Gunakan design tokens, bukan warna hardcoded di banyak file.

``` text
Primary       → brand utama Skilloka
Secondary     → aksen pendukung
Background    → netral terang
Surface       → putih/neutral
Text          → dark neutral
Muted         → gray neutral
Success       → status berhasil
Warning       → status perhatian
Danger        → status gagal
Info          → status informatif
```

Sediakan dark mode hanya jika benar-benar diperlukan; jangan
menambahkannya hanya untuk membuat UI terlihat modern.

## 7.3 Typography

-   Maksimal 2 family font.
-   Heading memiliki hierarchy konsisten.
-   Body text nyaman dibaca.
-   Hindari terlalu banyak uppercase.
-   Jangan menggunakan font dekoratif untuk dashboard.

## 7.4 Spacing

Gunakan sistem spacing konsisten, misalnya kelipatan 4/8 px.

## 7.5 Komponen

Komponen reusable minimal:

``` text
AppButton
AppInput
AppSelect
AppDropdown
AppModal
AppDialog
AppBadge
AppCard
AppTable
AppPagination
AppEmptyState
AppErrorState
AppSkeleton
AppToast
AppBottomSheet
AppSectionHeader
StatusBadge
CourseCard
LPKCard
BookingCard
```

Jangan membuat komponen baru jika komponen yang sudah ada dapat
digunakan.

------------------------------------------------------------------------

# 8. UI MOBILE USER

## 8.1 Prinsip

Flutter Mobile adalah aplikasi utama User. UI tidak boleh terasa seperti
web yang diperkecil.

Gunakan: - bottom navigation; - gesture yang natural; - bottom sheet
untuk filter; - card yang ringkas; - skeleton loading; - pull-to-refresh
bila relevan; - empty state yang menjelaskan langkah berikutnya.

## 8.2 Struktur navigasi

``` text
Home
├── Rekomendasi
├── Search
├── Kursus Saya
├── Notifikasi
└── Profil
```

## 8.3 Onboarding Profil Pendidikan

Setelah **registrasi pertama atau login pertama setelah akun dibuat**,
sistem memeriksa apakah profil pendidikan sudah lengkap.

Jika belum:

``` text
Login berhasil
 ↓
Profil pendidikan lengkap?
 ├─ Ya → Home Personal
 └─ Tidak → Onboarding Pendidikan
                 ↓
             Pilih jenjang
                 ↓
        ┌────────┼───────────┐
        ↓        ↓           ↓
       SMA      SMK     Perguruan Tinggi
        ↓        ↓           ↓
      Jurusan  Jurusan     Program studi
        └────────┼───────────┘
                 ↓
        Tujuan mengikuti kursus
                 ↓
       Lokasi pilihan (opsional)
                 ↓
           Simpan Profil
                 ↓
        Buat rekomendasi awal
                 ↓
               Home
```

### Data minimal

-   jenjang pendidikan: `SMA | SMK | PERGURUAN_TINGGI`;
-   jurusan/program studi;
-   tahun lulus (opsional sesuai kebutuhan);
-   tujuan mengikuti pelatihan;
-   lokasi pilihan (opsional).

**Catatan:** Requirement yang diberikan pengguna menyebut SMA, SMK, dan
kuliah. Struktur database harus dibuat extensible agar jenjang lain
dapat ditambahkan tanpa migrasi besar.

## 8.4 Algoritma rekomendasi versi awal

Jangan membuat machine learning yang kompleks pada tahap awal. Gunakan
rule-based scoring yang mudah dijelaskan dan diuji.

Contoh:

``` text
score = 0

+ 40 jika kategori kursus cocok dengan tujuan user
+ 25 jika bidang/jurusan relevan
+ 15 jika lokasi sesuai preferensi
+ 10 jika harga berada pada rentang preferensi
+ 10 jika kursus populer/tersedia
```

Ambang dan bobot harus berada di konfigurasi/service, bukan tersebar di
controller.

Contoh alur:

``` text
Profil User
   ↓
Ambil preferensi
   ↓
Ambil kursus aktif & LPK terverifikasi
   ↓
Filter basic eligibility
   ↓
Hitung relevance score
   ↓
Urutkan
   ↓
Ambil top N
   ↓
Tampilkan "Direkomendasikan untuk kamu"
```

Sistem **tidak boleh mengunci User** hanya pada jurusannya. Search
manual selalu tersedia.

## 8.5 Home Mobile

Jangan menampilkan 10 card statistik.

Struktur:

``` text
Header personal
"Halo, [Nama]"

Search bar
"Cari kursus atau LPK..."

Recommendation section
"Cocok untuk profilmu"
[Course Card] [Course Card]

Kategori
[Kerja] [Bahasa] [Teknis] [Lainnya]

Kursus berjalan
[Progress Card]

LPK pilihan / terbaru

Promo/announcement bila tersedia
```

## 8.6 Detail Kursus

Prioritas informasi:

1.  nama kursus;
2.  LPK + verified badge;
3.  rating;
4.  harga;
5.  durasi;
6.  jadwal dan kuota;
7.  deskripsi;
8.  materi yang akan dipelajari;
9.  review;
10. CTA Booking.

CTA booking dibuat sticky di bagian bawah pada mobile.

## 8.7 Booking

Gunakan stepper:

``` text
1. Jadwal → 2. Data → 3. Layanan → 4. Pembayaran → 5. Selesai
```

Jangan membuat satu halaman form panjang.

## 8.8 Kursus Saya

Kategori: - Akan datang; - Sedang berjalan; - Selesai.

Detail kursus berjalan:

``` text
Progress
Materi
Jadwal
Absensi
Sertifikat
Informasi LPK
```

------------------------------------------------------------------------

# 9. UI DASHBOARD ADMIN LPK

## 9.1 Masalah yang harus dihindari

Dashboard lama cenderung terasa monoton apabila seluruh halaman diisi:

-   4--8 metric card;
-   pie chart;
-   bar chart;
-   line chart;
-   tabel panjang;
-   warna-warni.

Versi baru memakai **action-oriented dashboard**.

## 9.2 Struktur dashboard

``` text
┌──────────────────────────────────────────────────────────┐
│ Sidebar        Header: Search | Notification | Profile  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ Selamat datang, Admin [Nama LPK]                         │
│ Ringkasan aktivitas LPK minggu ini                      │
│                                                          │
│ [Booking baru] [Peserta aktif] [Kursus aktif]            │
│                                                          │
│ ┌─────────────────────────┐ ┌─────────────────────────┐  │
│ │ Agenda terdekat         │ │ Tindakan yang diperlukan│  │
│ │ 10:00 Kelas A           │ │ 5 booking perlu dicek  │  │
│ │ 13:00 Kelas B           │ │ 2 jadwal hampir penuh  │  │
│ └─────────────────────────┘ └─────────────────────────┘  │
│                                                          │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Aktivitas booking 7/30 hari                          │ │
│ │ [satu chart yang relevan]                            │ │
│ └──────────────────────────────────────────────────────┘ │
│                                                          │
│ ┌──────────────────────────┐ ┌─────────────────────────┐ │
│ │ Kursus paling aktif      │ │ Kehadiran terbaru      │ │
│ │ table/list ringkas       │ │ list ringkas           │ │
│ └──────────────────────────┘ └─────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## 9.3 Prinsip dashboard

-   Maksimal 3--4 metric utama.
-   Maksimal 1--2 visualisasi pada halaman utama.
-   Sisanya berupa list/timeline/action.
-   Chart harus memiliki pertanyaan yang dijawab.
-   Gunakan tabel untuk data detail, bukan chart.
-   Empty state harus membantu user melakukan tindakan.
-   Setiap metric penting dapat diklik menuju detail.

## 9.4 Halaman dashboard tambahan

### Kursus

Tabel + filter + search + status + quick action.

### Jadwal

Gunakan calendar/list view. Hindari chart.

### Booking

Gunakan table dengan status badge dan action.

### Siswa

Gunakan list/table dengan progress kursus.

### Content

Gunakan content list dengan tipe, status publish, last updated.

### Absensi

Gunakan session-based attendance table.

### Sertifikat

Gunakan queue/list penerbitan sertifikat.

------------------------------------------------------------------------

# 10. UI SUPER ADMIN

Super Admin harus berorientasi moderation dan monitoring.

Dashboard:

``` text
Header
 ↓
Pengajuan LPK yang perlu diverifikasi
 ↓
Ringkasan platform
 ↓
Aktivitas terbaru
 ↓
Monitoring user/LPK
```

Prioritas utama bukan grafik, melainkan:

-   verification queue;
-   data anomaly;
-   user/LPK activity;
-   status platform.

------------------------------------------------------------------------

# 11. AUTHENTICATION & ONBOARDING DETAIL

## 11.1 Mobile User

``` text
Public Home
 ↓
Masuk / Daftar
 ↓
OTP / credential validation
 ↓
Account valid
 ↓
Cek onboarding profile
 ↓
Jika belum lengkap → questionnaire
 ↓
Recommendation generation
 ↓
Home
```

## 11.2 Web Admin

``` text
Public Web
 ↓
Masuk
 ↓
Authentication
 ↓
Role check
 ├─ Admin LPK → Admin Dashboard
 └─ Super Admin → Super Admin Dashboard
```

## 11.3 Session/token

Gunakan authentication yang dikelola Laravel. Untuk mobile API, gunakan
Sanctum/token mechanism sesuai arsitektur yang dipilih. Token tidak
boleh disimpan dalam source code atau database sebagai plaintext.
Laravel Sanctum mendukung token abilities dan revocation untuk API.
citeturn0search4

------------------------------------------------------------------------

# 12. REST API STRUCTURE

Base URL:

``` text
/api/v1
```

## Public

``` text
GET    /lpks
GET    /lpks/{id}
GET    /courses
GET    /courses/{id}
GET    /categories
GET    /locations
POST   /auth/register
POST   /auth/login
POST   /auth/otp/request
POST   /auth/otp/verify
```

## Authenticated User

``` text
GET    /auth/me
POST   /auth/logout
GET    /profile
PUT    /profile
PUT    /profile/education
GET    /avatars
PUT    /profile/avatar
GET    /recommendations
```

## Booking

``` text
POST   /bookings
GET    /bookings
GET    /bookings/{id}
POST   /bookings/{id}/cancel
GET    /bookings/{id}/payment
POST   /bookings/{id}/payment
```

## Subscription

``` text
GET    /subscriptions
GET    /subscriptions/{id}
GET    /subscription/plans
```

Subscription activation dilakukan sebagai bagian dari flow
booking/payment, bukan endpoint publik yang memungkinkan user membuat
langganan tanpa transaksi yang valid.

## Learning

``` text
GET    /my-courses
GET    /my-courses/{courseId}/content
GET    /my-courses/{courseId}/attendance
GET    /my-courses/{courseId}/certificate
```

## Review

``` text
POST   /courses/{id}/reviews
GET    /courses/{id}/reviews
PUT    /reviews/{id}
DELETE /reviews/{id}
```

## Chatbot

``` text
POST   /chatbot/messages
GET    /chatbot/history
```

## Admin LPK

``` text
GET    /admin/dashboard
GET    /admin/courses
POST   /admin/courses
PUT    /admin/courses/{id}
DELETE /admin/courses/{id}

GET    /admin/schedules
POST   /admin/schedules
PUT    /admin/schedules/{id}
DELETE /admin/schedules/{id}

GET    /admin/bookings
PUT    /admin/bookings/{id}
GET    /admin/students

GET    /admin/contents
POST   /admin/contents
PUT    /admin/contents/{id}
DELETE /admin/contents/{id}

GET    /admin/attendance
POST   /admin/attendance
PUT    /admin/attendance/{id}

GET    /admin/certificates
POST   /admin/certificates
```

## Super Admin

``` text
GET    /superadmin/dashboard
GET    /superadmin/lpks
PUT    /superadmin/lpks/{id}/verify
PUT    /superadmin/lpks/{id}/reject
GET    /superadmin/users
GET    /superadmin/categories
POST   /superadmin/categories
PUT    /superadmin/categories/{id}
DELETE /superadmin/categories/{id}
```

API harus memakai Resource/DTO/Transformer agar response konsisten dan
tidak mengembalikan seluruh kolom database secara sembarangan.

------------------------------------------------------------------------

# 13. CLEAN ARCHITECTURE / CLEAN CODE

Target struktur Laravel:

``` text
backend/
├── app/
│   ├── Actions/
│   ├── Console/
│   ├── Enums/
│   ├── Exceptions/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Api/V1/
│   │   │   └── Web/
│   │   ├── Middleware/
│   │   ├── Requests/
│   │   └── Resources/
│   ├── Models/
│   ├── Policies/
│   ├── Services/
│   ├── Repositories/       # hanya bila abstraction benar-benar diperlukan
│   ├── Rules/
│   └── Support/
├── bootstrap/
├── config/
├── database/
│   ├── factories/
│   ├── migrations/
│   └── seeders/
├── resources/
│   ├── views/
│   │   ├── layouts/
│   │   ├── public/
│   │   └── admin/
│   └── css/js/
├── routes/
│   ├── api.php
│   └── web.php
├── storage/
├── tests/
│   ├── Feature/
│   └── Unit/
├── Dockerfile
├── compose.yaml
└── .env.example
```

### Aturan clean code

-   Controller tipis.
-   Business logic berada pada service/action/domain layer.
-   Form Request menangani validation.
-   Policy/Gate menangani authorization.
-   Enum digunakan untuk status yang memiliki nilai terbatas.
-   Resource mengatur bentuk response API.
-   Tidak ada query database mentah tersebar di controller.
-   Tidak ada duplikasi business rule antara API dan Web.
-   Tidak ada file `Helper.php` raksasa.
-   Jangan membuat Repository untuk semua Model jika tidak memberikan
    manfaat nyata.
-   Nama class dan method harus menggambarkan aksi.
-   Fungsi harus kecil dan memiliki satu tanggung jawab.

------------------------------------------------------------------------

# 14. CLEAN CODE FLUTTER

Target:

``` text
mobile/
├── lib/
│   ├── core/
│   │   ├── config/
│   │   ├── constants/
│   │   ├── error/
│   │   ├── network/
│   │   ├── storage/
│   │   ├── theme/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   ├── onboarding/
│   │   ├── home/
│   │   ├── search/
│   │   ├── course/
│   │   ├── booking/
│   │   ├── learning/
│   │   ├── subscription/
│   │   ├── review/
│   │   ├── chatbot/
│   │   └── profile/
│   ├── shared/
│   │   ├── widgets/
│   │   └── models/
│   └── main.dart
├── test/
└── pubspec.yaml
```

Gunakan feature-first structure agar file fitur tidak tercampur.

------------------------------------------------------------------------

# 15. CODEBASE HYGIENE / PEMBERSIHAN PROJECT LAMA

Sebelum agent menambah fitur, lakukan audit.

## 15.1 Audit wajib

``` text
1. Scan seluruh folder.
2. Identifikasi file duplicate.
3. Identifikasi file tidak direferensikan.
4. Identifikasi component yang tidak dipakai.
5. Identifikasi endpoint mati.
6. Identifikasi migration duplikat/berkonflik.
7. Identifikasi model/controller lama.
8. Identifikasi TODO/FIXME yang sudah tidak relevan.
9. Identifikasi asset besar/tidak terpakai.
10. Identifikasi dependency yang tidak digunakan.
11. Identifikasi dead route.
12. Identifikasi environment/config yang bocor.
```

## 15.2 Jangan langsung menghapus

Agent wajib membuat laporan:

``` text
FILE / FOLDER
STATUS: USED | UNUSED | DUPLICATE | LEGACY | UNKNOWN
REFERENCED BY
RECOMMENDATION
RISK
```

File `UNKNOWN` tidak boleh dihapus otomatis.

## 15.3 Definition of clean

Project dianggap clean apabila:

-   tidak ada duplicate implementation untuk fitur yang sama;
-   tidak ada import mati;
-   tidak ada route mati tanpa alasan;
-   tidak ada secret di repository;
-   tidak ada file sementara;
-   folder mengikuti feature/domain responsibility;
-   lint/analyzer/test berjalan;
-   dokumentasi build/deploy sesuai project aktual.

------------------------------------------------------------------------

# 16. PERFORMANCE & OPTIMIZATION

## Backend

-   Eager loading untuk relasi yang diperlukan.
-   Hindari N+1 query.
-   Pagination untuk list.
-   Filter dan search melalui query database.
-   Index kolom pencarian/foreign key/status yang relevan.
-   Cache untuk data publik yang sering dibaca.
-   Queue untuk pekerjaan lambat seperti email, notifikasi, pembuatan
    file, dan integrasi eksternal.
-   Hindari mengembalikan payload API terlalu besar.
-   Gunakan API Resource.

Laravel menyediakan mekanisme caching dan deployment optimization;
dokumentasi deployment Laravel juga merekomendasikan caching
configuration, routes, events, dan views pada production.
citeturn0search5turn0search7

## Flutter

-   Pagination/infinite scroll.
-   Image caching.
-   Debounce search.
-   Skeleton loading.
-   Jangan melakukan network call berulang pada rebuild widget.
-   State management harus memiliki ownership yang jelas.
-   Gunakan immutable model/state bila sesuai.
-   Hindari rebuild seluruh halaman untuk perubahan kecil.

------------------------------------------------------------------------

# 17. SECURITY --- OWASP TOP 10:2025

Security baseline mengikuti OWASP Top 10:2025. Versi 2025 mencakup
Broken Access Control, Security Misconfiguration, Software Supply Chain
Failures, Cryptographic Failures, Injection, Insecure Design,
Authentication Failures, Software/Data Integrity Failures, Security
Logging and Alerting Failures, dan Mishandling of Exceptional
Conditions. citeturn0search0turn0search2

OWASP sendiri menempatkan Top 10 sebagai awareness baseline, bukan
daftar lengkap seluruh kontrol keamanan; untuk verifikasi yang lebih
terukur dapat mengacu ke OWASP ASVS. citeturn0search6

## A01 Broken Access Control

-   Semua endpoint private menggunakan authentication middleware.
-   Authorization berbasis role dan resource ownership.
-   Admin LPK hanya dapat mengakses data LPK miliknya.
-   User hanya dapat melihat materi/absensi/sertifikat yang memang
    menjadi haknya.
-   Super Admin memiliki permission khusus.
-   Jangan mempercayai `id_user` dari request jika dapat diambil dari
    authenticated user.

## A02 Security Misconfiguration

-   `APP_DEBUG=false` production.
-   Jangan commit `.env`.
-   CORS dibatasi domain yang diperlukan.
-   Error production tidak menampilkan stack trace.
-   Default credential harus diubah.
-   Docker image tidak berjalan sebagai root bila memungkinkan.
-   File upload dibatasi tipe, ukuran, dan lokasi penyimpanan.

## A03 Software Supply Chain Failures

-   Dependency dicatat melalui lock file.
-   Jangan install package yang tidak diperlukan.
-   Jalankan audit dependency pada CI.
-   Review package sebelum dipakai.
-   GitHub Actions memakai action version yang dipin bila memungkinkan.
-   Secret CI disimpan di GitHub Secrets, bukan repository.

## A04 Cryptographic Failures

-   Password memakai hashing Laravel.
-   HTTPS wajib production.
-   Token tidak disimpan plaintext di database jika mekanisme
    memungkinkan hashing.
-   Jangan menyimpan data sensitif di log.
-   Encryption digunakan untuk data sensitif yang memang membutuhkan
    encryption at rest.

## A05 Injection

-   Gunakan Eloquent/query builder/parameter binding.
-   Hindari raw SQL dari input user.
-   Validasi semua input.
-   Escape output pada web.
-   Chatbot prompt/user input diperlakukan sebagai untrusted data.

## A06 Insecure Design

-   Business rule ditulis sebelum coding.
-   Booking/payment/subscription memiliki state transition yang jelas.
-   Ownership selalu diverifikasi.
-   Jangan mengandalkan validasi client sebagai security control.
-   Threat modeling ringan untuk fitur pembayaran, upload,
    authentication, dan admin.

## A07 Authentication Failures

-   Rate limit login dan OTP.
-   OTP memiliki expiration.
-   Batasi percobaan OTP.
-   Jangan mengungkapkan apakah email/nomor tertentu terdaftar secara
    berlebihan.
-   Logout mencabut token/session yang relevan.
-   Password policy sesuai kebutuhan proyek.

## A08 Software/Data Integrity Failures

-   Validasi webhook/payment callback.
-   Jangan percaya status pembayaran hanya dari client.
-   Verifikasi signature provider jika payment gateway menyediakan.
-   Database transaction untuk perubahan state penting.
-   CI memastikan test/lint sebelum deployment.

## A09 Security Logging & Alerting Failures

Catat event keamanan yang relevan:

-   login gagal berulang;
-   OTP abuse;
-   permission denied;
-   perubahan role;
-   verifikasi/reject LPK;
-   perubahan status pembayaran;
-   penerbitan sertifikat;
-   perubahan data penting oleh admin.

Jangan log:

-   password;
-   OTP plaintext;
-   access token;
-   secret key;
-   data pribadi yang tidak diperlukan.

## A10 Mishandling of Exceptional Conditions

-   Exception handler terpusat.
-   API mengembalikan error format konsisten.
-   Jangan menampilkan exception internal ke client.
-   Transaksi database di-rollback ketika proses kritis gagal.
-   External API timeout memiliki fallback.
-   Upload/payment/AI failure harus memiliki state yang aman.

------------------------------------------------------------------------

# 18. SECURITY UNTUK PAYMENT

Payment harus server-authoritative.

``` text
User
 ↓
Create Booking
 ↓
Server hitung total
 ↓
Create Payment
 ↓
Payment Provider
 ↓
Webhook / callback
 ↓
Server validasi signature/status
 ↓
Database transaction
 ↓
Payment = paid
 ↓
Booking = confirmed
 ↓
Jika subscription → activate
```

Client tidak boleh mengirim `total_bayar` lalu server mempercayainya
tanpa menghitung ulang.

------------------------------------------------------------------------

# 19. SECURITY UNTUK FILE DAN SERTIFIKAT

-   Validasi MIME type dan extension.
-   Batas ukuran file.
-   Nama file tidak berasal langsung dari user.
-   File private tidak disajikan melalui path publik secara langsung.
-   Download menggunakan authorization check.
-   Sertifikat hanya dapat diakses oleh pemilik atau role yang
    berwenang.

------------------------------------------------------------------------

# 20. CHATBOT SECURITY

Chatbot tidak boleh memiliki akses langsung ke database berdasarkan
instruksi user.

Gunakan boundary:

``` text
User input
 ↓
Input validation
 ↓
Context builder yang aman
 ↓
Allowed knowledge/context
 ↓
AI provider
 ↓
Output validation
 ↓
User
```

Jangan mengirim secret, password, token, atau data pribadi yang tidak
dibutuhkan ke provider AI.

------------------------------------------------------------------------

# 21. DOCKER

Target minimal:

``` text
Docker
├── Laravel/PHP application
├── Web server
├── postgres
├── Redis (optional/production recommended when needed)
└── Queue worker
```

Development:

``` text
docker compose up -d
```

Production harus menggunakan environment variable dari deployment
environment, bukan `.env` yang di-commit.

Health check minimal:

``` text
GET /up
```

Laravel menyediakan health route dan deployment optimization untuk
production. citeturn0search5

------------------------------------------------------------------------

# 22. GITHUB ACTIONS / CI-CD

Pipeline minimal:

``` text
Push / Pull Request
        ↓
Checkout
        ↓
Install PHP dependencies
        ↓
Install Flutter dependencies
        ↓
Static analysis / lint
        ↓
Unit test
        ↓
Feature/API test
        ↓
Security/dependency audit
        ↓
Build Docker image
        ↓
Push image registry
        ↓
Deploy
        ↓
Health check
        ↓
Rollback jika gagal
```

## Gate sebelum merge

Minimal:

-   lint pass;
-   test pass;
-   migration check;
-   dependency audit;
-   secret scan;
-   build pass.

------------------------------------------------------------------------

# 23. DATABASE FINAL --- TARGET ENTITAS

ERD lama sudah memiliki entity inti:

``` text
users
LPK
Kategori
Kursus
Jadwal
Booking
Pembayaran
Sertifikat
Review
```

Target revisi final harus mengakomodasi:

``` text
users
LPK
AdminLPK / role
SuperAdmin / role
Kategori
Kursus
Jadwal
Booking
Pembayaran
Langganan
Content
Absensi
Sertifikat
Review
Avatar
Chatbot_Log
```

## Relasi utama

``` text
User 1 ─── N Booking
User 1 ─── N Langganan
User 1 ─── N Review
User 1 ─── N Absensi
User 1 ─── N Sertifikat
User 1 ─── N ChatbotLog

LPK 1 ─── N Kursus
LPK 1 ─── 1 AdminLPK
Kategori 1 ─── N Kursus
Kursus 1 ─── N Jadwal
Kursus 1 ─── N Content
Kursus 1 ─── N Booking
Kursus 1 ─── N Review
Booking 1 ─── N Pembayaran / sesuai payment design
Booking 1 ─── N Absensi
Booking 1 ─── 0..1 Sertifikat
Jadwal 1 ─── N Absensi
Avatar 1 ─── N User
```

**Catatan:** cardinality final pembayaran dan sertifikat harus
disesuaikan dengan aturan implementasi yang dipilih. Jangan membuat
relasi hanya agar gambar ERD terlihat ramai.

------------------------------------------------------------------------

# 24. ENTITY PENDIDIKAN USER

Untuk fitur onboarding/rekomendasi, user membutuhkan data pendidikan.

Disarankan menambahkan entity:

### education_profiles

``` text
id PK
user_id FK
education_level
major
institution_name nullable
graduation_year nullable
career_goal nullable
preferred_location nullable
created_at
updated_at
```

Atau jika proyek ingin lebih sederhana, field dapat berada di `users`.
Untuk desain yang lebih rapi dan extensible, `education_profiles`
dipisahkan dari `users` karena data pendidikan adalah profile domain,
bukan credential.

Relasi:

``` text
users 1 ─── 0..1 education_profiles
```

------------------------------------------------------------------------

# 25. STATE MACHINE UTAMA

## Booking

``` text
DRAFT
 ↓
PENDING_PAYMENT
 ↓
PAID / CONFIRMED
 ↓
ONGOING
 ↓
COMPLETED
```

Alternative:

``` text
PENDING_PAYMENT → EXPIRED
PENDING_PAYMENT → CANCELLED
PAID → CANCELLED   [hanya jika business rule mengizinkan]
```

## Payment

``` text
PENDING
 ↓
PAID
```

Alternative:

``` text
PENDING → FAILED
PENDING → EXPIRED
```

## Subscription

``` text
PENDING → ACTIVE → EXPIRED
                 ↘ CANCELLED jika business rule mengizinkan
```

## LPK Verification

``` text
PENDING → VERIFIED
        ↘ REJECTED
```

------------------------------------------------------------------------

# 26. BUSINESS RULE PENTING

1.  Kursus LPK yang belum verified tidak tampil sebagai LPK verified.
2.  User tidak dapat booking kursus tanpa jadwal valid.
3.  Server memeriksa kuota sebelum booking dikonfirmasi.
4.  Total pembayaran dihitung server.
5.  Subscription aktif hanya setelah pembayaran yang valid.
6.  Subscription tidak otomatis memberikan akses ke kursus yang tidak
    memiliki booking valid.
7.  Materi hanya dapat diakses oleh peserta yang memiliki hak akses.
8.  Absensi hanya dapat dibuat oleh role yang berwenang.
9.  Sertifikat hanya dapat diterbitkan oleh Admin LPK untuk peserta yang
    memenuhi aturan kursus.
10. Review hanya dapat dibuat oleh User yang memiliki hubungan valid
    dengan kursus sesuai business rule.
11. Admin LPK tidak boleh mengakses data LPK lain.
12. Super Admin dapat melakukan verifikasi dan pengelolaan platform
    sesuai permission.
13. User dapat mengubah profil pendidikan dan rekomendasi akan
    diperbarui.
14. Rekomendasi tidak mengunci hasil pencarian manual.

------------------------------------------------------------------------

# 27. FLOWCHART MASTER TERBARU

``` text
START
 ↓
Buka Skilloka
 ↓
Public Landing / Home
 ↓
Login / Register?
 ├─ Tidak → Jelajahi informasi / Cari kursus / Info LPK
 │             ↓
 │          Login/Register
 │
 └─ Ya → Authentication
            ↓
       User / Admin / Super Admin?

USER
 ↓
Cek profil pendidikan
 ├─ Belum → Questionnaire
 │           ↓
 │       Generate rekomendasi
 └─ Sudah
       ↓
Home Personal
 ↓
Cari Kursus / LPK
 ↓
Filter
 ↓
Detail LPK/Kursus
 ↓
Booking
 ↓
Pilih Jadwal
 ↓
Cek Kuota
 ├─ Tidak → Pilih Jadwal Lain
 └─ Ya
       ↓
Isi Data
       ↓
Pilih layanan
 ├─ Booking biasa
 └─ Booking + Subscription
       ↓
Pembayaran
 ├─ Gagal → Retry/Batal
 └─ Berhasil
       ↓
Booking Confirmed
       ↓
Subscription aktif jika dipilih
       ↓
Kursus Saya
       ↓
Materi / Jadwal / Absensi
       ↓
Kursus Selesai
       ↓
Sertifikat
       ↓
Review
       ↓
END
```

------------------------------------------------------------------------

# 28. ADMIN FLOW

``` text
START
 ↓
Login
 ↓
Dashboard
 ↓
 ┌───────────────┬──────────────┬───────────────┐
 ↓               ↓              ↓               ↓
Kursus          Jadwal        Booking         Siswa
 ↓               ↓              ↓               ↓
CRUD             CRUD           Kelola          Monitoring
 └───────────────┴──────────────┴───────────────┘
                 ↓
          Content / Materi
                 ↓
             Absensi
                 ↓
            Sertifikat
                 ↓
                END
```

------------------------------------------------------------------------

# 29. SUPER ADMIN FLOW

``` text
START
 ↓
Login
 ↓
Dashboard
 ↓
Verification Queue
 ↓
Pilih Pengajuan LPK
 ↓
Review Data
 ├─ Reject → alasan → notifikasi
 └─ Approve → verified
 ↓
Kelola LPK / User / Kategori
 ↓
END
```

------------------------------------------------------------------------

# 30. UI ERROR / EMPTY / LOADING STATE

Setiap halaman harus memiliki minimal:

``` text
Loading
Empty
Error
Success
Unauthorized
Not Found
```

Contoh empty state:

``` text
Belum ada kursus yang sedang diikuti.
Cari pelatihan yang sesuai dengan tujuanmu.
[ Cari Kursus ]
```

Jangan menampilkan halaman putih kosong atau hanya tulisan `No data`.

------------------------------------------------------------------------

# 31. ACCESSIBILITY DAN USABILITY

-   Kontras teks harus cukup.
-   Touch target mobile nyaman.
-   Form memiliki label yang jelas.
-   Error ditampilkan dekat field yang salah.
-   Jangan menggunakan warna saja untuk membedakan status.
-   Semua tombol memiliki state disabled/loading.
-   Keyboard type sesuai field.
-   Dialog dapat ditutup dengan jelas.

------------------------------------------------------------------------

# 32. TESTING STRATEGY

## Backend

Unit test: - recommendation scoring; - booking validation; -
subscription activation; - authorization policy; - certificate
eligibility.

Feature test: - register/login; - OTP; - booking; - payment callback; -
content access; - attendance; - certificate; - review; - admin
authorization; - super admin verification.

## Flutter

-   widget test untuk komponen penting;
-   repository/service test;
-   state management test;
-   routing/auth guard test.

## Security test minimum

-   unauthorized access;
-   IDOR/resource ownership;
-   SQL injection payload;
-   XSS payload pada field teks;
-   rate limit OTP/login;
-   upload malicious file;
-   expired token;
-   role escalation;
-   payment tampering.

------------------------------------------------------------------------

# 33. OBSERVABILITY

Minimal backend menyediakan:

-   structured application log;
-   request correlation ID;
-   error logging;
-   authentication security log;
-   payment event log;
-   admin activity log.

Production log harus menghindari secret dan data sensitif.

------------------------------------------------------------------------

# 34. DEPLOYMENT ENVIRONMENT

``` text
Development
    ↓
Testing / CI
    ↓
Staging
    ↓
Production
```

Environment variable minimal:

``` text
APP_ENV
APP_KEY
APP_URL
DB_HOST
DB_DATABASE
DB_USERNAME
DB_PASSWORD
CACHE_DRIVER
QUEUE_CONNECTION
MAIL_*
PAYMENT_*
AI_*
```

Jangan menyimpan nilai secret sebenarnya dalam PRD atau repository.

------------------------------------------------------------------------

# 35. OBSERVABLE PERFORMANCE TARGET

Target awal yang dapat diuji:

-   endpoint public sederhana: p95 \< 500 ms pada kondisi staging
    normal;
-   endpoint query kompleks: p95 \< 1.5 s dengan pagination;
-   mobile first meaningful content tidak menunggu seluruh data
    sekunder;
-   image menggunakan thumbnail/resizing;
-   list besar menggunakan pagination;
-   pekerjaan eksternal lambat dipindahkan ke queue.

Angka di atas adalah target engineering awal, bukan SLA produksi.

------------------------------------------------------------------------

# 36. ACCEPTANCE CRITERIA UTAMA

## User

-   [ ] Dapat menjelajahi public information tanpa login.
-   [ ] Dapat register/login.
-   [ ] Dapat melakukan onboarding pendidikan setelah login pertama.
-   [ ] Dapat melihat rekomendasi berdasarkan profil.
-   [ ] Dapat mencari semua kursus secara manual.
-   [ ] Dapat filter kursus.
-   [ ] Dapat melihat detail LPK/kursus.
-   [ ] Dapat booking.
-   [ ] Dapat memilih subscription sebagai bagian dari booking.
-   [ ] Pembayaran divalidasi server.
-   [ ] Subscription aktif hanya setelah pembayaran valid.
-   [ ] Dapat mengakses content sesuai hak akses.
-   [ ] Dapat melihat absensi.
-   [ ] Dapat melihat/mengunduh sertifikat jika tersedia.
-   [ ] Dapat memberikan review jika memenuhi syarat.
-   [ ] Dapat menggunakan chatbot.
-   [ ] Dapat mengubah avatar/profil.

## Admin LPK

-   [ ] Login sesuai role.
-   [ ] Dashboard menampilkan informasi yang actionable.
-   [ ] CRUD kursus.
-   [ ] CRUD jadwal.
-   [ ] Kelola booking.
-   [ ] Kelola siswa.
-   [ ] Kelola content.
-   [ ] Kelola pembayaran yang menjadi kewenangannya.
-   [ ] Kelola absensi.
-   [ ] Kelola sertifikat.
-   [ ] Tidak dapat mengakses data LPK lain.

## Super Admin

-   [ ] Dashboard.
-   [ ] Kelola LPK.
-   [ ] Verifikasi/reject LPK.
-   [ ] Kelola kategori.
-   [ ] Kelola user.

## Engineering

-   [ ] API versioned.
-   [ ] Validation server-side.
-   [ ] Authorization server-side.
-   [ ] Automated test.
-   [ ] Dependency audit.
-   [ ] Secret scan.
-   [ ] Docker build berhasil.
-   [ ] CI pipeline berhasil.
-   [ ] Health check berhasil.
-   [ ] Production debug disabled.

------------------------------------------------------------------------

# 37. ROADMAP IMPLEMENTASI

## Phase 0 --- Audit dan cleanup

-   Audit repository.
-   Backup branch/tag.
-   Mapping route/controller/model/widget.
-   Hapus hanya dead code yang sudah terbukti tidak dipakai.
-   Buat baseline test.

## Phase 1 --- Core foundation

-   Laravel API structure.
-   Sanctum.
-   User/role.
-   OTP.
-   Profile.
-   Education profile.
-   Public landing page.
-   Admin authentication.

## Phase 2 --- Discovery

-   LPK.
-   Kategori.
-   Kursus.
-   Jadwal.
-   Search/filter.
-   Recommendation service.

## Phase 3 --- Transaction

-   Booking.
-   Payment.
-   Subscription.
-   Notification.

## Phase 4 --- Learning

-   Content.
-   Attendance.
-   Certificate.
-   Review.

## Phase 5 --- Intelligent/support features

-   Chatbot.
-   Avatar.
-   Dashboard refinement.

## Phase 6 --- DevSecOps

-   Docker.
-   GitHub Actions.
-   CI security checks.
-   Staging.
-   Production deployment.
-   Monitoring.

------------------------------------------------------------------------

# 38. ATURAN KHUSUS UNTUK AI CODING AGENT

Sebelum mengubah kode:

``` text
READ PRD
 ↓
SCAN REPOSITORY
 ↓
UNDERSTAND CURRENT ARCHITECTURE
 ↓
IDENTIFY EXISTING IMPLEMENTATION
 ↓
COMPARE WITH PRD
 ↓
PLAN CHANGE
 ↓
IMPLEMENT SMALLEST CLEAN CHANGE
 ↓
RUN TEST/LINT
 ↓
REVIEW FILES CREATED/CHANGED
 ↓
REMOVE ONLY CONFIRMED DEAD CODE
 ↓
REPORT RESULT
```

AI agent **tidak boleh**:

-   membuat duplicate service/controller/model untuk fungsi yang sama;
-   membuat folder hanya karena pola tutorial;
-   membuat file `utils`/`helpers` tanpa kebutuhan nyata;
-   menggandakan endpoint versi lama tanpa alasan;
-   menyimpan secret dalam code;
-   melewati authorization karena client dianggap trusted;
-   membuat chart hanya agar dashboard terlihat ramai;
-   membuat UI menggunakan template generik tanpa mengikuti design
    system;
-   mengubah schema database tanpa migration;
-   menghapus file yang belum terbukti tidak digunakan;
-   menambah package tanpa menjelaskan manfaatnya.

Setiap perubahan besar harus dilaporkan:

``` text
WHY
WHAT CHANGED
FILES CHANGED
DATABASE IMPACT
API IMPACT
UI IMPACT
SECURITY IMPACT
TEST RESULT
```

------------------------------------------------------------------------

# 39. DEFINITION OF DONE

Fitur dianggap selesai apabila:

1.  Flow bisnis sesuai PRD.
2.  UI sesuai design system.
3.  API tervalidasi.
4.  Authorization benar.
5.  Error state tersedia.
6.  Loading/empty state tersedia.
7.  Database migration tersedia.
8.  Test relevan tersedia.
9.  Tidak ada duplicate implementation.
10. Tidak ada secret yang bocor.
11. Lint/static analysis lolos.
12. Security checks lolos.
13. Docker build berhasil.
14. CI berhasil.
15. Dokumentasi endpoint diperbarui.
16. File/folder yang tidak terpakai telah diaudit.

------------------------------------------------------------------------

# 40. CHECKLIST KONSISTENSI ARTEFAK

Sebelum submit proyek, lakukan cross-check:

``` text
Proposal
   ↕
PRD
   ↕
SRS
   ↕
Use Case
   ↕
BPMN / Flowchart
   ↕
Class Diagram
   ↕
ERD
   ↕
Sequence Diagram
   ↕
API
   ↕
UI/UX
   ↕
Implementation
```

Setiap fitur baru minimal harus dapat dilacak:

``` text
Requirement
 → Use Case
 → Flow
 → Class/Entity
 → ERD
 → API
 → UI
 → Test
```

Jika satu fitur tidak memiliki salah satu bagian tersebut, tandai
sebagai `TRACEABILITY GAP` dan selesaikan sebelum implementasi final.

------------------------------------------------------------------------

# 41. KEPUTUSAN PRODUK YANG DIKUNCI

### Dikunci

-   Laravel/PHP sebagai backend dan REST API.
-   Flutter sebagai mobile User.
-   Laravel Web sebagai public web + dashboard role.
-   MySQL sebagai database utama.
-   Booking sebagai transaksi inti.
-   Subscription sebagai layanan yang melekat pada Booking/Payment.
-   Subscription aktif setelah pembayaran valid.
-   Subscription membuka hak akses pembelajaran sesuai booking.
-   Materi, absensi, dan sertifikat menjadi bagian dari pengalaman
    pembelajaran.
-   Onboarding pendidikan terjadi setelah registrasi/login pertama
    ketika profile belum lengkap.
-   Pendidikan dipakai untuk rekomendasi, bukan membatasi search.
-   Dashboard action-oriented, bukan chart-heavy.
-   Public landing page dapat dijelajahi tanpa login.
-   Registrasi LPK dilakukan melalui public web dan dilanjutkan proses
    verifikasi Super Admin.
-   Clean code dan cleanup repository menjadi bagian dari Definition of
    Done.
-   Security baseline menggunakan OWASP Top 10:2025.
-   Deployment disiapkan untuk Docker + GitHub Actions.

### Belum dikunci / harus ditentukan ketika implementasi

-   Payment gateway yang dipakai.
-   Provider OTP.
-   Provider AI chatbot.
-   Object storage untuk file.
-   Redis wajib atau opsional berdasarkan traffic.
-   Aturan persentase minimal absensi untuk sertifikat.
-   Paket/langganan final dan harga.
-   Detail legalitas dokumen LPK.

Jangan mengarang nilai untuk keputusan yang belum dikunci tersebut.

------------------------------------------------------------------------

# 42. HASIL AKHIR YANG DIHARAPKAN

Skilloka final bukan sekadar aplikasi CRUD dengan dashboard dan chart.
Sistem harus terasa sebagai satu produk yang utuh:

``` text
PUBLIC WEB
   ↓
Kenali Skilloka
   ↓
Cari LPK/Kursus
   ↓
Register/Login
   ↓
ONBOARDING PENDIDIKAN
   ↓
PERSONALIZED HOME
   ↓
DISCOVERY
   ↓
BOOKING
   ↓
PAYMENT
   ↓
SUBSCRIPTION (opsional)
   ↓
LEARNING
   ├── CONTENT
   ├── ABSENSI
   └── SERTIFIKAT
   ↓
REVIEW
   ↓
END
```

Sementara dari sisi LPK:

``` text
PUBLIC WEB
   ↓
Pelajari manfaat Skilloka
   ↓
Daftarkan LPK
   ↓
Verifikasi Super Admin
   ↓
ADMIN DASHBOARD
   ↓
Kursus
Jadwal
Booking
Siswa
Content
Absensi
Sertifikat
Pembayaran
   ↓
Operasional LPK lebih terstruktur
```

**End of PRD --- Skilloka v2.0**
