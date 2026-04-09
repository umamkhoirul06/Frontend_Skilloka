# 🎓 Skilloka - Platform Pelatihan Kerja Modern

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Laravel](https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)

**Skilloka** adalah solusi komprehensif yang dirancang untuk menjembatani Lembaga Pelatihan Kerja (LPK) dengan para siswa yang ingin meningkatkan keterampilan mereka. Proyek ini menggabungkan kekuatan **Backend Laravel** yang handal untuk manajemen administrasi dan **Aplikasi Mobile Flutter** yang modern untuk pengalaman belajar siswa yang mulus.

---

## ✨ Fitur Unggulan

### 📱 **Aplikasi Mobile (Siswa)**
Aplikasi mobile dirancang untuk memberikan pengalaman pengguna yang intuitif dan menarik menggunakan Flutter.

*   **🔍 Penemuan Kursus Cerdas**: Jelajahi berbagai kursus berdasarkan kategori, lokasi, rating, dan popularitas.
*   **💳 Booking & Pembayaran Mudah**: Proses pendaftaran kursus yang seamless dengan integrasi pembayaran yang aman.
*   **📚 Dashboard Siswa**: Pantau progres belajar, jadwal kelas, dan riwayat transaksi dalam satu tempat.
*   **🏆 Sertifikat Digital**: Dapatkan sertifikat digital setelah menyelesaikan kursus.
*   **⭐ Ulasan & Rating**: Berikan umpan balik langsung kepada instruktur dan LPK.

### 💻 **Web Dashboard (Admin & LPK)**
Panel admin berbasis web yang powerful untuk pengelolaan operasional LPK.

*   **🏢 Multi-Tenancy Support**: Mendukung pengelolaan banyak LPK dalam satu platform dengan isolasi data yang aman.
*   **👥 Role-Based Access Control (RBAC)**: Hak akses terperinci untuk Super Admin, Admin LPK, Instruktur, dan Staff.
*   **📊 Laporan & Analitik**: Insight mendalam mengenai performa kursus, pendaftaran siswa, dan pendapatan.
*   **📅 Manajemen Jadwal**: Atur jadwal kelas, instruktur, dan ruangan dengan mudah.

---

## 🛠️ Teknologi yang Digunakan

*   **Frontend Mobile**: Flutter (BLoC Pattern, Hive Storage)
*   **Backend API**: Laravel 11 (REST API, Sanctum Auth)
*   **Database**: SQLite (Development) / PostgreSQL (Production Support)
*   **Architecture**: Clean Core Architecture, Repository Pattern

---

## 🚀 Panduan Instalasi (Getting Started)

Ikuti langkah-langkah berikut untuk menjalankan proyek ini di komputer lokal Anda.

### Prasyarat
Pastikan Anda telah menginstal:
*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   [PHP](https://www.php.net/) & [Composer](https://getcomposer.org/)
*   Git

### 1️⃣ Setup Backend (Laravel)

Buka terminal dan arahkan ke folder `backend`:

```bash
cd backend
```

Install dependensi PHP:
```bash
composer install
```

Salin file environment:
```bash
cp .env.example .env
```

Generate application key:
```bash
php artisan key:generate
```

Setup database (Pastikan driver SQLite aktif di `php.ini` atau sesuaikan `.env` jika menggunakan database lain):
```bash
# Membuat database sqlite (jika belum ada)
touch database/database.sqlite

# Menjalankan migrasi dan seeding data awal
php artisan migrate:fresh --seed --class=SuperAdminSeeder
```

Jalankan server backend:
```bash
php artisan serve
```
Server akan berjalan di `http://127.0.0.1:8000`.

---

### 2️⃣ Setup Mobile App (Flutter)

Buka terminal baru di root folder proyek (`c:\proyek2`):

Ambil semua packages Flutter:
```bash
flutter pub get
```

Jalankan aplikasi (Pastikan emulator Android sudah berjalan atau gunakan Chrome):
```bash
flutter run
```
*Catatan: Konfigurasi API URL sudah disesuaikan otomatis untuk Emulator Android (`10.0.2.2`) dan Web (`localhost`).*

---

## 🔑 Akun Demo (Credentials)

Gunakan akun berikut untuk mencoba fitur aplikasi:

| Role | Email | Password |
| :--- | :--- | :--- |
| **Super Admin** | `god@skilloka.com` | `password` |
| **Siswa (Test)** | `test@example.com` | `password` |

---

## 🤝 Kontribusi

Jika Anda ingin berkontribusi pada proyek ini, silakan buat *Pull Request* baru. Laporkan *issue* jika menemukan bug.

---

Dibuat dengan ❤️ oleh Tim Skilloka.
